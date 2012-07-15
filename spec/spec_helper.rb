$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require 'compiler'


def compile_and_check(compiler, code, expected)
  do_and_check(compiler, code, expected) do |c|
    c.compile_exp(code)

    if block_given?
      yield(compiler)
    end
  end
end

def do_and_check(compiler, code, expected)
  output = StringIO.new
  compiler.output_stream = output

  yield(compiler)

  output.string.should eq(expected)
end
