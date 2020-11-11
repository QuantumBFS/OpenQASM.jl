module OpenQASM

using RBNF

include("types.jl")
include("parse.jl")

"""
    parse(qasm::String)

Parse a piece of QASM program at top-level to AST.
"""
function parse(src::String)
    ast, _ = RBNF.runparser(Parse.mainprogram, RBNF.runlexer(Parse.QASMLang, src))
    return ast
end


end
