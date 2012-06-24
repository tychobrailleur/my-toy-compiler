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
	movq	$.LC6,(%rsp)
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
	movq	$.LC9,24(%rsp)
	movq	$.LC8,16(%rsp)
	movq	$.LC7,8(%rsp)
	movq	$.LC6,(%rsp)
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

end
