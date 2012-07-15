#!/bin/env ruby

require 'logger'

# This is my first attempt at a simple compiler following the Ruby
# compiler series:
# http://www.hokstad.com/writing-a-compiler-in-ruby-bottom-up-step-2.html
#
# The article however uses x86 assembler, when this is an attempt at
# generating x64 assembler.  I know nothing of x64 assembler, and the
# code generated is deduced from `gcc -S` as indicated by the article
# series.  This means that more than likely the code is either
# suboptimal, or plain incorrect.  In particular, the convoluted way
# in which the label sequence is computed is due to the fact that I
# wanted to keep the registers used for the function call args in the
# order returned by gcc.  I actually have no idea what the registers
# may be, or if they could ordered differently.
#
# The command used to compile is:
# ruby stuff.rb > hello.s ; gcc -o hello hello.s
#
#

# Basic definition of a runtime library...
# DO_BEFORE = [:do,
#   [:defun, :hello_world, [], [:puts, "Hello World"]]
# ]

DO_BEFORE = []
DO_AFTER = []

class Compiler

  PTR_SIZE = 8
  REGISTERS = ["r9d", "r8d", "ecx", "edx", "esi", "edi"]

  attr_writer :output_stream

  def initialize
    @output_stream = STDOUT

    @global_functions = {}
    @string_constants = {}
    @seq = 0
    @function_sequence = 0

    @logger = Logger.new(STDERR)
  end


  # returns the sequence number for a given string.
  def get_arg(a)
    # If argument is an array, we recursively compile it.
    if a.is_a?(Array)
      compile_exp(a)
      return [:subexpr]
    end

    return [:int, a] if (a.is_a?(Fixnum))
    return [:atom, a] if (a.is_a?(Symbol))

    # handling strings.
    # check if string is present in constants already.
    seq = @string_constants[a]
    # if it is, return existing sequence.
    return [:strconst, seq] if seq
    # if not, increment sequence, and set sequence in constant pool.
    seq = @seq
    @seq += 1
    @string_constants[a] = seq
    # return sequence.
    [:strconst, seq]
  end

  # emits the assembly code for the constant definition.
  def output_constants
    @output_stream.puts "\t.section\t.rodata"
    @string_constants.each do |k,v|
      @output_stream.puts ".LC#{v}:"
      @output_stream.puts "\t.string \"#{k}\""
    end
  end

  #
  # Emits assembly code for functions.
  def output_functions
    @global_functions.each do |name,data|
      @function_sequence += 1
      @output_stream.puts <<PROLOG
	.globl	#{name}
	.type	#{name}, @function
#{name}:
.LFB#{@function_sequence}:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
PROLOG
      compile_exp(data[1])

      @output_stream.puts <<EPILOGUE
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE#{@function_sequence}:
	.size	#{name}, .-#{name}

EPILOGUE

    end
  end

  # defines a function.
  def compile_defun(name, args, body)
    @global_functions[name] = [args,body]
  end

  # emits code for if ... else.
  def compile_ifelse(cond, if_arm, else_arm)
    compile_exp(cond)
    @output_stream.puts "\ttestl   %eax, %eax"
    @seq += 2
    else_arm_seq = @seq - 1
    end_if_arm_seq = @seq
    @output_stream.puts "\tje  .L#{else_arm_seq}"
    compile_exp(if_arm)
    @output_stream.puts "\tjmp .L#{end_if_arm_seq}"
    @output_stream.puts ".L#{else_arm_seq}:"
    compile_exp(else_arm)
    @output_stream.puts ".L#{end_if_arm_seq}:"
  end

  def compile_lambda(args, body)
    name = "lambda__#{@seq}"
    @seq += 1
    compile_defun(name, args, body)
    @output_stream.puts "\tmovq\t$#{name}, %rax"
    return [:subexpr]
  end

  def compile_eval_arg(arg)
    atype, aparam = get_arg(arg)
    return "$.LC#{aparam}" if atype == :strconst
    return "$#{aparam}" if atype == :int
    return aparam.to_s if atype == :atom
    return "*%rax"
  end

  def compile_do(*exp)
    exp.each { |e| compile_exp(e) }
    return [:subexpr]
  end

  def compile_call(function, args)
    # if the function call has arguments.
    if args.size > 0
      if args.size > REGISTERS.size
        # This is just a guess... It looks like minimum is 16, though?
        stack_adjustment = [((args.size-REGISTERS.size) * PTR_SIZE), 16].max
        @output_stream.puts "\tsubq\t$#{stack_adjustment}, %rsp"
      end

      args.reverse.each_with_index do |a, i|
        param = compile_eval_arg(a)

        # Using 64 bits instructions for the stack
        mov_instruction = ((args.size-i) > REGISTERS.size) ? "movq" : "movl"
        @output_stream.puts "\t#{mov_instruction}\t#{param}, #{get_register(args.size-i)}"
      end
    end

    res = compile_eval_arg(function)
    @output_stream.puts "\tcall\t#{res}"
    return [:subexpr]
  end

  def compile_exp(exp)
    return if !exp || exp.size == 0

    # if first element is :do, recursively compile following
    # entries in the expression.
    return compile_do(*exp[1..-1]) if exp[0] == :do
    # function definition.
    return compile_defun(*exp[1..-1]) if (exp[0] == :defun)
    # if ... else
    return compile_ifelse(*exp[1..-1]) if (exp[0] == :if) 
    return compile_lambda(*exp[1..-1]) if (exp[0] == :lambda)
    return compile_call(exp[1], exp[2]) if (exp[0] == :call)
    return compile_call(exp[0], exp[1..-1])
  end

  def get_register(index)
    if index > REGISTERS.size
      i = (index - REGISTERS.size - 1) * PTR_SIZE
      "#{i>0 ? i : ""}(%rsp)"
    else
      "%#{REGISTERS[REGISTERS.size-index]}"
    end
  end

  def compile_main(exp)
    @output_stream.puts "\t.file\t\"bootstrap.rb\""

    # Taken from gcc -S output
    @output_stream.puts <<PROLOG
	.text
	.globl	main
	.type	main, @function
main:
.LFB#{@function_sequence}:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
PROLOG

    compile_exp(exp)

    if @seq > REGISTERS.size
      @output_stream.puts "\tleave" # What does that mean?
    else
      @output_stream.puts "\tpopq\t%rbp"
    end

    @output_stream.puts <<EPILOG
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE#{@function_sequence}:
EPILOG

    output_functions
    output_constants

  end

  def compile(exp)
    compile_main([:do, DO_BEFORE, exp, DO_AFTER])
  end

end


#prog = [:getchar]
#prog = [:printf, "Hello\\n"]
#prog = [:printf, "Hello %s\\n", "World"]
#prog = [:printf,"Hello %s %s\\n", "Cruel", "World"]
#prog = [:printf,"Hello %s %s %s %s %s\\n", "Cruel", "World", "Bonjour", "Monde", "Aussi"]
#prog = [:printf,"Hello %s %s %s %s %s %s\\n", "Cruel", "World", "Bonjour", "Monde", "Aussi", "."]
#prog = [:printf,"%s %s %s %s %s %s %s %s %s\\n", "Hello", "World", "Again", "Oy", "Senta", "Scusi", "Bonjour", "Monde", "encore"]
# prog = [ :do,
#   [:printf, "Hello %s", "World"],
#   [:printf, " "],
#   [:printf, "World\\n"]
# ]
#prog = [:printf,"'hello world' takes %ld bytes\\n",[:echo, "hello world"]]
#prog = [:hello_world]

# prog = [:do,
#   [:printf,"'hello world' takes %d bytes\\n", 11],
#   [:printf,"The above should show _%d_ bytes\\n",11]
# ]

# prog = [:do,
#   [:if, [:strlen,""],
#     [:puts, "IF: The string was not empty"],
#     [:puts, "ELSE: The string was empty"]
#   ],
#   [:if, [:strlen,"Test"],
#     [:puts, "Second IF: The string was not empty"],
#     [:puts, "Second IF: The string was empty"]
#   ]
# ]

prog = [:do,
  [:call, [:lambda, [], [:puts, "Test"]], [] ]
]

Compiler.new.compile(prog)
