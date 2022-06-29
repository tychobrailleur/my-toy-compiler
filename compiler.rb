#!/bin/env ruby
# coding: utf-8

require 'logger'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require 'function'
require 'scope'

# This is my first attempt at a simple compiler following the Ruby
# compiler series:
# http://www.hokstad.com/writing-a-compiler-in-ruby-bottom-up-step-2.html
#
# The article however uses x86 assembler, when this is an attempt at
# generating x64 assembler.  I know nothing of x64 assembler, and the
# code generated is deduced from `gcc -S` as indicated by the article
# series.  This means that more than likely the code is either
# suboptimal, or plain incorrect.
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
  # Temporary of 64 bits registers.  Will have to come up with
  # a way of handling just one, and getting the right register
  # name when dealing with 32 or 64 bits.
  # Or just use 64 bits everywhere?
  RREGISTERS = ["r9", "r8", "rcx", "rdx", "rsi", "rdi"]

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
  def get_arg(scope, a)
    # If argument is an array, we recursively compile it.
    return compile_exp(scope, a) if a.is_a?(Array)
    return [:int, a] if (a.is_a?(Integer))
    return scope.get_arg(a) if (a.is_a?(Symbol))

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
    @global_functions.each do |name, function|
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

      # Print stack adjustment.
      if function.args.size > 0
        index = [RREGISTERS.size, function.args.size].min
        stack_adjustment = [(index * PTR_SIZE), 16].max
        @output_stream.puts "\tsubq\t$#{stack_adjustment}, %rsp"
      end

      # Here get args
      function.args.each_with_index do |a,i|
        register = RREGISTERS[RREGISTERS.size-1-i]
        @output_stream.puts("\tmovq\t%#{register}, -#{PTR_SIZE*(i+1)}(%rbp)") if i < 6
      end

      compile_exp(Scope.new(self, function), function.body)

      if function.args.size > 0
        @output_stream.puts("leave")
      else
        @output_stream.puts("\tpopq\t%rbp")
      end

      @output_stream.puts <<EPILOGUE
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE#{@function_sequence}:
	.size	#{name}, .-#{name}

EPILOGUE

    end
  end

  # defines a function.
  def compile_defun(scope, name, args, body)
    @global_functions[name] = Function.new(args, body)
    [:subexpr]
  end

  # emits code for if ... else.
  def compile_ifelse(scope, cond, if_arm, else_arm = nil)
    compile_exp(scope, cond)
    @output_stream.puts "\ttestl   %eax, %eax"
    @seq += 2
    else_arm_seq = @seq - 1
    end_if_arm_seq = @seq
    @output_stream.puts "\tje  .L#{else_arm_seq}"
    compile_exp(scope, if_arm)
    @output_stream.puts "\tjmp .L#{end_if_arm_seq}"
    @output_stream.puts ".L#{else_arm_seq}:"
    compile_exp(scope, else_arm)
    @output_stream.puts ".L#{end_if_arm_seq}:"
    [:subexpr]
  end

  # emits code for while.
  def compile_while(scope, cond, body)
    start_while_seq = @seq
    cond_seq = @seq + 1
    @seq += 2
    @output_stream.puts "\tjmp\t.L#{cond_seq}"
    @output_stream.puts ".L#{start_while_seq}:"
    compile_exp(scope,body)
    @output_stream.puts ".L#{cond_seq}:"
    var = compile_eval_arg(scope,cond)
    @output_stream.puts "\tcmpq\t$0, #{var}"
    @output_stream.puts "\tjne\t.L#{start_while_seq}"
    return [:subexpr]
  end

  def compile_lambda(scope, args, body)
    name = "lambda__#{@seq}"
    @seq += 1
    compile_defun(scope, name, args, body)
    @output_stream.puts "\tmovq\t$#{name}, %rax"
    return [:subexpr]
  end

  def compile_eval_arg(scope, arg)
    atype, aparam = get_arg(scope, arg)
    return "$.LC#{aparam}" if atype == :strconst
    return "$#{aparam}" if atype == :int
    return aparam.to_s if atype == :atom
    return (aparam >= RREGISTERS.size ?
              "#{(aparam-RREGISTERS.size+2)*PTR_SIZE}(%rbp)"
            : "-#{PTR_SIZE*(aparam+1)}(%rbp)") if atype == :arg

    # Here put arg...
    return "%rax"
  end

  def compile_assign(scope, left, right)
    source = compile_eval_arg(scope, right)
    atype, aparam = get_arg(scope,left)
    raise "Expected a variable on left hand side of assignment" if atype != :arg
    @output_stream.puts "\tmovq\t#{source}, -#{PTR_SIZE*(aparam+1)}(%rbp)"
    return [:subexpr]
  end

  def compile_do(scope, *exp)
    exp.each { |e| compile_exp(scope, e) }
    [:subexpr]
  end

  # compiles a function call.
  def compile_call(scope, function, args)
    # if the function call has arguments.
    if args.size > 0
      if args.size > RREGISTERS.size
        # This is just a guess... It looks like minimum is 16, though?
        stack_adjustment = [((args.size-RREGISTERS.size) * PTR_SIZE), 16].max
        @output_stream.puts "\tsubq\t$#{stack_adjustment}, %rsp"
      end

      args.reverse.each_with_index do |a, i|
        param = compile_eval_arg(scope, a)

        # Using 64 bits instructions for the stack
        #mov_instruction = ((args.size-i) > RREGISTERS.size) ? "movq" : "movl"
        mov_instruction = 'movq'
        @output_stream.puts "\t#{mov_instruction}\t#{param}, #{get_register(args.size-i)}"
      end
    end

    res = compile_eval_arg(scope, function)
    res = "*" + res if res == "%rax"
    @output_stream.puts "\tcall\t#{res}"
    [:subexpr]
  end

  def compile_exp(scope, exp)
    return if !exp || exp.size == 0

    # if first element is :do, recursively compile following
    # entries in the expression.
    return compile_do(scope, *exp[1..-1]) if exp[0] == :do
    # function definition.
    return compile_defun(scope, *exp[1..-1]) if (exp[0] == :defun)
    # if ... else
    return compile_ifelse(scope, *exp[1..-1]) if (exp[0] == :if)
    return compile_while(scope,*exp[1..-1]) if (exp[0] == :while)
    return compile_lambda(scope, *exp[1..-1]) if (exp[0] == :lambda)
    return compile_call(scope, exp[1], exp[2]) if (exp[0] == :call)
    return compile_assign(scope, *exp[1..-1]) if (exp[0] == :assign)
    return compile_call(scope, exp[0], exp[1..-1])
  end

  def get_register(index)
    if index > RREGISTERS.size
      i = (index - RREGISTERS.size - 1) * PTR_SIZE
      "#{i>0 ? i : ""}(%rsp)"
    else
      "%#{RREGISTERS[RREGISTERS.size-index]}"
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


    @main = Function.new([], [])
    compile_exp(Scope.new(self, @main), exp)

    # @seq??  That looks wrong.
    if @seq > RREGISTERS.size
      @output_stream.puts "\tleave"
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
