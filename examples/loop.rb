require 'compiler'

prog = [:do,
        [:defun, :loop, [:i],
         [:do,
          [:while, [:ne, :i, 10],
           [:do, [:printf, "--- %d\\n", :i], [:assign, :i, [:add, :i, 1]]]
          ]
         ]
        ],
        [:loop, 0]]

Compiler.new.compile(prog)
