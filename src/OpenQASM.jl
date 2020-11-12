module OpenQASM

using RBNF

include("types.jl")
include("parse.jl")

"""
    parse(qasm::String)

Parse a piece of QASM program at top-level to AST.
"""
function parse(src::String)
    ast, ctx = RBNF.runparser(Parse.mainprogram, RBNF.runlexer(Parse.QASMLang, src))
    ctx.tokens.current > ctx.tokens.length || throw(Meta.ParseError("invalid syntax in QASM program"))
    return ast
end

end
