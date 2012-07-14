require File.expand_path(File.join(File.dirname(__FILE__), "spec_helper"))

describe 'A compiler' do

  let(:compiler) { Compiler.new }

  it "compiles function with no arg" do
    output = StringIO.new
    compiler.output_stream = output

    compiler.compile_exp([:getchar])
    output.string.should eq("	call	getchar\n")
  end

  it "compiles function with one arg" do
    output = StringIO.new
    compiler.output_stream = output

    compiler.compile_exp([:printf, "Hello\\n"])

    expected_output = <<EXPECTED
	movl	$.LC0, %edi
	call	printf
EXPECTED
    output.string.should eq(expected_output)
  end

  it "compiles function with two args" do
    output = StringIO.new
    compiler.output_stream = output

    compiler.compile_exp([:printf, "Hello %s\\n", "World"])

    expected_output = <<EXPECTED
	movl	$.LC1, %esi
	movl	$.LC0, %edi
	call	printf
EXPECTED
    output.string.should eq(expected_output)
  end

  it "compiles function with 6 args" do
    output = StringIO.new
    compiler.output_stream = output
    
    compiler.compile_exp([:printf,"Hello %s %s %s %s %s\\n", "Cruel", "World", "Bonjour", "Monde", "Aussi"])

    expected_output = <<EXPECTED
	movl	$.LC5, %r9d
	movl	$.LC4, %r8d
	movl	$.LC3, %ecx
	movl	$.LC2, %edx
	movl	$.LC1, %esi
	movl	$.LC0, %edi
	call	printf
EXPECTED
    output.string.should eq(expected_output)
  end

  it "compiles function with 7 args" do
    output = StringIO.new
    compiler.output_stream = output
    
    compiler.compile_exp([:printf,"Hello %s %s %s %s %s %s\\n", "Cruel", "World", "Bonjour", "Monde", "Aussi", "."])

    expected_output = <<EXPECTED
	subq	$16, %rsp
	movq	$.LC6, (%rsp)
	movl	$.LC5, %r9d
	movl	$.LC4, %r8d
	movl	$.LC3, %ecx
	movl	$.LC2, %edx
	movl	$.LC1, %esi
	movl	$.LC0, %edi
	call	printf
EXPECTED
    output.string.should eq(expected_output)
  end

  it "compiles function with more than 6 args" do
    output = StringIO.new
    compiler.output_stream = output
    
    compiler.compile_exp([:printf,"%s %s %s %s %s %s %s %s %s\\n", "Hello", "World", "Again", "Oy", "Senta", "Scusi", "Bonjour", "Monde", "encore"])

    expected_output = <<EXPECTED
	subq	$32, %rsp
	movq	$.LC9, 24(%rsp)
	movq	$.LC8, 16(%rsp)
	movq	$.LC7, 8(%rsp)
	movq	$.LC6, (%rsp)
	movl	$.LC5, %r9d
	movl	$.LC4, %r8d
	movl	$.LC3, %ecx
	movl	$.LC2, %edx
	movl	$.LC1, %esi
	movl	$.LC0, %edi
	call	printf
EXPECTED
    output.string.should eq(expected_output)
  end

  it "compiles functions chained with :do" do
    output = StringIO.new
    compiler.output_stream = output

    prog = [ :do,
             [:printf, "Hello"],
             [:printf, " "],
             [:printf, "World\\n"]
           ]
    
    compiler.compile_exp(prog)
    expected_output = <<EXPECTED
	movl	$.LC0, %edi
	call	printf
	movl	$.LC1, %edi
	call	printf
	movl	$.LC2, %edi
	call	printf
EXPECTED
    output.string.should eq(expected_output)
  end

  it "compile a function definition" do
    output = StringIO.new
    compiler.output_stream = output
    
    prog = [:defun, :hello_world, [], [:puts, "Hello World"]]
    compiler.compile_exp(prog)
    compiler.output_functions
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
    output.string.should eq(expected_output)

  end

  # This intentionally fails to pick it up next time.
  it "compiles nested function calls" do
    output = StringIO.new
    compiler.output_stream = output

    prog = [:printf,"'hello world' takes %s bytes\\n",[:echo, "hello world"]]

    compiler.compile_exp(prog)
    expected_output = <<EXPECTED
	movl	$.LC0, %edi
	call	echo
	movq	%rax, %rsi
	movq    $.LC1, %rdi
	call	printf
EXPECTED
    output.string.should eq(expected_output)

  end

end
