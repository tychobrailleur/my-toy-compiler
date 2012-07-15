require File.expand_path(File.join(File.dirname(__FILE__), "spec_helper"))

describe 'A compiler' do

  let(:compiler) { Compiler.new }

  it "compiles function with no arg" do
    compile_and_check(compiler, [:getchar], "\tcall\tgetchar\n")
  end

  it "compiles function with one arg" do
    expected_output =
    compile_and_check(compiler, [:printf, "Hello\\n"],  <<EXPECTED
	movl	$.LC0, %edi
	call	printf
EXPECTED
)
  end

  it "compiles function with two args" do
    compile_and_check(compiler, [:printf, "Hello %s\\n", "World"],  <<EXPECTED
	movl	$.LC0, %esi
	movl	$.LC1, %edi
	call	printf
EXPECTED
    )
  end

  it "compiles function with 6 args" do
    compile_and_check(compiler, [:printf,"Hello %s %s %s %s %s\\n", "Cruel", "World", "Bonjour", "Monde", "Aussi"],  <<EXPECTED
	movl	$.LC0, %r9d
	movl	$.LC1, %r8d
	movl	$.LC2, %ecx
	movl	$.LC3, %edx
	movl	$.LC4, %esi
	movl	$.LC5, %edi
	call	printf
EXPECTED
)
  end

  it "compiles function with 7 args" do
    compile_and_check(compiler, [:printf,"Hello %s %s %s %s %s %s\\n", "Cruel", "World", "Bonjour", "Monde", "Aussi", "."], <<EXPECTED
	subq	$16, %rsp
	movq	$.LC0, (%rsp)
	movl	$.LC1, %r9d
	movl	$.LC2, %r8d
	movl	$.LC3, %ecx
	movl	$.LC4, %edx
	movl	$.LC5, %esi
	movl	$.LC6, %edi
	call	printf
EXPECTED
                      )
  end

  it "compiles function with more than 6 args" do
    compile_and_check(compiler, [:printf,"%s %s %s %s %s %s %s %s %s\\n", "Hello", "World", "Again", "Oy", "Senta", "Scusi", "Bonjour", "Monde", "encore"], <<EXPECTED
	subq	$32, %rsp
	movq	$.LC0, 24(%rsp)
	movq	$.LC1, 16(%rsp)
	movq	$.LC2, 8(%rsp)
	movq	$.LC3, (%rsp)
	movl	$.LC4, %r9d
	movl	$.LC5, %r8d
	movl	$.LC6, %ecx
	movl	$.LC7, %edx
	movl	$.LC8, %esi
	movl	$.LC9, %edi
	call	printf
EXPECTED
                      )
  end

  it "compiles functions chained with :do" do
    prog = [ :do,
             [:printf, "Hello"],
             [:printf, " "],
             [:printf, "World\\n"]
           ]

    expected_output = <<EXPECTED
	movl	$.LC0, %edi
	call	printf
	movl	$.LC1, %edi
	call	printf
	movl	$.LC2, %edi
	call	printf
EXPECTED
    compile_and_check(compiler, prog, expected_output)
  end

  it "compile a function definition" do
    prog = [:defun, :hello_world, [], [:puts, "Hello World"]]
    expected_output = <<EXPECTED
	.globl	hello_world
	.type	hello_world, @function
hello_world:
.LFB1:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	$.LC0, %edi
	call	puts
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1:
	.size	hello_world, .-hello_world

EXPECTED
    compile_and_check(compiler, prog, expected_output) do |c|
      c.output_functions
    end
  end

  it "compiles an if ... else statement" do
    prog = [:if, [:strlen,""],
             [:puts, "IF: The string was not empty"],
             [:puts, "ELSE: The string was empty"]
            ]
    expected_output = <<EXPECTED
	movl	$.LC0, %edi
	call	strlen
	testl   %eax, %eax
	je  .L2
	movl	$.LC3, %edi
	call	puts
	jmp .L3
.L2:
	movl	$.LC4, %edi
	call	puts
.L3:
EXPECTED
    compile_and_check(compiler, prog, expected_output)
  end


  it "makes the lambda available" do
    prog = [:lambda, [], [:puts, "hi"]]
    expected_output = "\tmovq	$lambda__0, %rax\n"
    compile_and_check(compiler, prog, expected_output)
  end

  it "compiles the lambda definition" do
    prog = [:lambda, [], [:puts, "hi"]]
    expected_output = <<EXPECTED
	movq	$lambda__0, %rax
	.globl	lambda__0
	.type	lambda__0, @function
lambda__0:
.LFB1:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	$.LC1, %edi
	call	puts
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1:
	.size	lambda__0, .-lambda__0

EXPECTED
    compile_and_check(compiler, prog, expected_output) do |c|
      c.output_functions
    end
  end

  it "compiles the lambda call" do
    prog = [:call, [:lambda, [], [:puts, "hi"]], []]
    expected_output = <<EXPECTED
	movq	$lambda__0, %rax
	call	*%rax
EXPECTED
    compile_and_check(compiler, prog, expected_output)
  end

  # This intentionally fails to pick it up next time.
#   it "compiles nested function calls" do
#     output = StringIO.new
#     compiler.output_stream = output

#     prog = [:printf,"'hello world' takes %s bytes\\n",[:echo, "hello world"]]

#     compiler.compile_exp(prog)
#     expected_output = <<EXPECTED
# 	movl	$.LC0, %edi
# 	call	echo
# 	movq	%rax, %rsi
# 	movq    $.LC1, %rdi
# 	call	printf
# EXPECTED
#     output.string.should eq(expected_output)

#   end

end
