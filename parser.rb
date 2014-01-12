
require 'compiler'

# prog = [:do,
#   [:defun, :parse_quoted, [:c],
#     [:while, [:and, [:ne, :c, 34], [:ne, -1, [:assign, :c, [:getchar]]]], [:do,
#         [:putchar, :c]
#       ]
#     ]
#   ],
#   [:defun, :parse, [:c,:sep], 
#     [:while, [:and, [:ne, :c, 41], [:ne, -1, [:assign, :c, [:getchar]]]], [:do,
#         [:if, [:eq,:c, 40], [:do,
#             [:printf, "["],
#             [:parse,0,0],
#             [:printf, "]"],
#             [:assign, :sep, 1]
#           ],
#           [:if, [:eq, :c, 34], [:do,
#               [:putchar,34],
#               [:parse_quoted,0],
#               [:putchar,34],
#               [:assign, :sep, 1]
#             ],
#             [:do,
#               [:if, [:and, [:isspace, :c], :sep], [:do,
#                   [:printf, ","],
#                   [:assign, :sep, 0]
#                 ]
#               ],
#               [:if, [:and, [:isalnum, :c], [:not, :sep]], [:do,
#                     [:assign, :sep, 1],
#                     [:if, [:not, [:isdigit, :c]],[:printf,":"]]
#                 ]
#               ],
#               [:putchar, :c]
#             ]
#           ]
#         ]
#       ]
#     ]
#   ],
#   [:puts, "require 'compiler'\\n"],
#   [:puts, "prog = [:do,"],
#   [:parse, 0, 0],
#   [:puts, "]\\n"],
#   [:puts, "Compiler.new.compile(prog)"]
# ]

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
