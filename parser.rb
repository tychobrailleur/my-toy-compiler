require 'compiler'

prog = [:do,
  [:puts, "require 'compiler'\\n"],
  [:puts, "prog = [:puts,'Program goes here']"],
  [:puts, ""],
  [:puts, "Compiler.new.compile(prog)"]
]

Compiler.new.compile(prog)
