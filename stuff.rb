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

    # handle integers
    return [:int, a] if (a.is_a?(Fixnum))

    # for now we assume strings only.
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
    index = 0
    @string_constants.each_key do |c|
      @output_stream.puts ".LC#{index}:"
      @output_stream.puts "\t.string \"#{c}\""
      index += 1
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
  def defun(name, args, body)
    @global_functions[name] = [args,body]
  end

  PTR_SIZE = 8
  REGISTERS = ["r9d", "r8d", "ecx", "edx", "esi", "edi"]
  def compile_exp(exp)
    return if !exp || exp.size == 0

    # if first element is :do, recursively compile following 
    # entries in the expression.
    if exp[0] == :do
      exp[1..-1].each{ |e| compile_exp(e) }
      return
    end

    # function definition.
    return defun(*exp[1..-1]) if (exp[0] == :defun)
    funcall = exp[0].to_s


    # if the function call has arguments.
    if exp.size > 1

      # The current implementation (slightly different to the articles’)
      # requires to know in advance the number of args of the function 
      # to be able properly choose registers — hence this double iteration
      # of exp[1..-1].
      # Args must be reversed to be passed to functions.
      # args = exp[1..-1].reverse.collect { |a| get_arg(a) }
      args = exp[1..-1].collect { |a| get_arg(a) }

      if args.size > REGISTERS.size
        # This is just a guess... It looks like minimum is 16, though?
        stack_adjustment = [((args.size-REGISTERS.size) * PTR_SIZE), 16].max
        @output_stream.puts "\tsubq\t$#{stack_adjustment}, %rsp"
      end
      
      exp[1..-1].reverse.each_with_index do |a, i|
        atype, aparam = get_arg(a)
        if atype == :strconst
          param = "$.LC#{aparam}"
        elsif atype == :int then param = "$#{aparam}" 
        else
          param = "%eax"
        end

        # Using 64 bits instructions for the stack
        mov_instruction = ((args.size-i) > REGISTERS.size) ? "movq" : "movl"
        @output_stream.puts "\t#{mov_instruction}\t#{param}, #{get_register(args.size-i)}"
      end
    end
    @output_stream.puts "\tcall\t#{funcall}"
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
    @output_stream.puts "	.file	\"bootstrap.rb\""

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

prog = [:do,
  [:printf,"'hello world' takes %d bytes\\n", 11],
  [:printf,"The above should show _%d_ bytes\\n",11]
]

Compiler.new.compile(prog)
