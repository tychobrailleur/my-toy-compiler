require 'compiler'

prog = [:do,
        [:defun, :foo, [:s, :t],
         [:do, [:puts, :s], [:puts, :t]]],
         [:foo, "Hello", "World!"]]

Compiler.new.compile(prog)
        
