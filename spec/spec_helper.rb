$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require 'compiler'


def compile_and_check(compiler, code, expected)
  do_and_check(compiler, code, expected) do |c,s|
    c.compile_exp(s, code)

    if block_given?
      yield(compiler)
    end
  end
end

def do_and_check(compiler, code, expected)
  output = StringIO.new
  compiler.output_stream = output

  scope = Scope.new(compiler, Function.new([], []))

  yield(compiler, scope)

  output.string.should eq(expected)
end
