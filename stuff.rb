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

  def initialize
    @string_constants = {}
    @seq = 0

    @logger = Logger.new(STDERR)
  end

  def get_arg(a)
    # for now we assume strings only.
    seq = @string_constants[a]
    return seq if seq
    seq = @seq
    @seq += 1
    @string_constants[a] = seq
    seq
  end

  def order_constants
    clone = @string_constants.clone
    @ordered_constants = []
    @ordered_constants << clone.shift.first

    if clone.size < 6
      clone.keys.reverse.each do |i|
        @ordered_constants << i
      end
    else
      tmp = clone.keys[5..-1] + clone.keys[0..4]
      @ordered_constants += tmp.reverse
    end
  end

  def output_constants
#    order_constants
    puts "\t.section\t.rodata"
    index = 0
    @string_constants.each_key do |c|
      puts ".LC#{index}:"
      puts "\t.string \"#{c}\""
      index += 1
    end
  end

  PTR_SIZE = 8
  REGISTERS = ["r9d", "r8d", "ecx", "edx", "esi"]
  def compile_exp(exp)
    if exp[0] == :do
      exp[1..-1].each{ |e| compile_exp(e) }
      return
    end

    call = exp[0].to_s
    args = exp[1..-1].collect { |a| get_arg(a) }

    if args.size == 0
      puts "\tmovl\t$.LC0, %edi"
    elsif args.size <= 6
      counter = 0
      puts "\tmovl\t$.LC#{args[0]}, %eax"
      counter += 1
      REGISTERS[REGISTERS.size-args.size+1..-1].each do 
        |r|
        puts "\tmovl\t$.LC#{args[args.size-counter]}, %#{r}"
        counter += 1
      end
    else
      counter = 0
      # TODO: this is just a guess value, what is the correct one??
      stack_adjustment = ((args.size-6) * PTR_SIZE)
      puts "\tsubq\t$#{stack_adjustment}, %rsp"
      puts "\tmovl\t$.LC#{args[0]}, %eax"

      counter = 6
      args[1..-6].each_with_index do |a,i|
        index = stack_adjustment - (i+1)*PTR_SIZE
        puts "\tmovq\t$.LC#{args[args.size-counter+1]},#{index>0 ? index : ""}(%rsp)"
        counter += 1
      end

      REGISTERS.each do 
        |r|
        if args.size-counter == -1
          counter = 2
        end

        puts "\tmovl\t$.LC#{args[(args.size-counter+1)]}, %#{r}"
        counter += 1
      end

    end
    
    # Actual call
    puts "\tmovq\t%rax, %rdi"
    puts "\tmovl\t$0, %eax"
    puts "\tcall\t#{call}"

  end

  def compile(exp)
    puts "	.file	\"bootstrap.rb\""

    # Taken from gcc -S output
    puts <<PROLOG
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
      puts "\tleave" # What does that mean?
    else
      puts "\tpopq\t%rbp"
    end

    puts <<EPILOG
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
EPILOG

    output_constants

  end
end

#prog = [:printf,"Hello %s %s\\n", "Cruel", "World"]
prog = [:printf,"%s %s %s %s %s %s %s %s %s\\n", "Hello", "World", "Again", "Oy", "Senta", "Scusi", "Bonjour", "Monde", "encore"]
# prog = [ :do,
#   [:printf, "Hello"],
#   [:printf, " "],
#   [:printf, "World\\n"]
# ]


Compiler.new.compile(prog)
