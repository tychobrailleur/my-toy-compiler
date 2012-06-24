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

class Compiler
  attr_writer :output_stream

  def initialize
    @output_stream = STDOUT
    @string_constants = {}
    @seq = 0

    @logger = Logger.new(STDERR)
  end


  # returns the sequence number for a given string.
  def get_arg(a)
    # for now we assume strings only.
    # check if string is present in constants already.
    seq = @string_constants[a]
    # if it is, return existing sequence.
    return seq if seq
    # if not, increment sequence, and set sequence in constant pool.
    seq = @seq
    @seq += 1
    @string_constants[a] = seq
    # return sequence.
    seq
  end

  def output_constants
    @output_stream.puts "\t.section\t.rodata"
    index = 0
    @string_constants.each_key do |c|
      @output_stream.puts ".LC#{index}:"
      @output_stream.puts "\t.string \"#{c}\""
      index += 1
    end
  end

  PTR_SIZE = 8
  REGISTERS = ["r9d", "r8d", "ecx", "edx", "esi", "edi"]
  def compile_exp(exp)
    # if first element is :do, recursively compile following 
    # entries in the expression.
    if exp[0] == :do
      exp[1..-1].each{ |e| compile_exp(e) }
      return
    end


    funcall = exp[0].to_s

    # if the function call has arguments.
    if exp.size > 1
      args = exp[1..-1].collect { |a| get_arg(a) }

      counter = 0
      if args.size > REGISTERS.size
        # This is just a guess... It looks like minimum is 16, though?
        stack_adjustment = [((args.size-REGISTERS.size) * PTR_SIZE), 16].max
        @output_stream.puts "\tsubq\t$#{stack_adjustment}, %rsp"
        args[1..-(REGISTERS.size)].each_with_index do |a,i|
          if args.size > REGISTERS.size + 1
            index = stack_adjustment - (i+1)*PTR_SIZE
          else
            index = 0
          end
          @output_stream.puts "\tmovq\t$.LC#{args[args.size-counter-1]},#{index>0 ? index : ""}(%rsp)"
          counter += 1
        end
      end
      
      remaining = args.size - counter
      REGISTERS[REGISTERS.size-remaining..-1].each do 
        |r|
        @output_stream.puts "\tmovl\t$.LC#{args[args.size-counter-1]}, %#{r}"
        counter += 1
      end
    end

    @output_stream.puts "\tcall\t#{funcall}"
  end

  def compile(exp)
    @output_stream.puts "	.file	\"bootstrap.rb\""

    # Taken from gcc -S output
    @output_stream.puts <<PROLOG
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
PROLOG

    compile_exp(exp)
    
    if @seq > 6
      @output_stream.puts "\tleave" # What does that mean?
    else
      @output_stream.puts "\tpopq\t%rbp"
    end

    @output_stream.puts <<EPILOG
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
EPILOG

    output_constants

  end
end


#prog = [:getchar]
#prog = [:printf, "Hello\\n"]
#prog = [:printf,"Hello %s %s\\n", "Cruel", "World"]
#prog = [:printf,"Hello %s %s %s %s %s\\n", "Cruel", "World", "Bonjour", "Monde", "Aussi"]
#prog = [:printf,"Hello %s %s %s %s %s %s\\n", "Cruel", "World", "Bonjour", "Monde", "Aussi", "."]
prog = [:printf,"%s %s %s %s %s %s %s %s %s\\n", "Hello", "World", "Again", "Oy", "Senta", "Scusi", "Bonjour", "Monde", "encore"]
# prog = [ :do,
#   [:printf, "Hello"],
#   [:printf, " "],
#   [:printf, "World\\n"]
# ]


Compiler.new.compile(prog)
