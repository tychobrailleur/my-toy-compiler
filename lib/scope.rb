class Scope
  def initialize(compiler, function)
    @compiler = compiler
    @function = function
  end

  def get_arg(a)
    a = a.to_sym
    @function.args.each_with_index do |arg, i|
      return [:arg, i] if arg == a
    end
    return [:atom, a]
  end
end
