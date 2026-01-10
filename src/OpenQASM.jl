module OpenQASM

using RBNF

# Include modules in dependency order
include("types.jl")          # Base AST types for QASM 2.0
include("types_v3.jl")       # AST types for QASM 3.0
include("qasm_common.jl")    # Shared utilities and type conversions
include("parse.jl")          # QASM 2.0 parser
include("parse_v3.jl")       # QASM 3.0 parser
include("tools.jl")          # Utilities

using .Types: print_qasm
using .Tools: cmp_ast

export parse, parse_v2, parse_v3, parse_gate, detect_version

"""
    detect_version(src::String)

Detect the OpenQASM version from the source code.
Returns `v"2.0.0"` by default if no version is found.
"""
function detect_version(src::String)
    m = match(r"OPENQASM\s+([\d.]+)", src)
    m === nothing && return v"2.0.0"  # Default to 2.0
    return VersionNumber(m.captures[1])
end

"""
    parse(src::String; version=:auto)

Parse a piece of QASM program to AST with automatic version detection.

# Arguments
- `src::String`: The QASM source code
- `version`: Version to use for parsing. Can be:
  - `:auto` (default): Auto-detect from source
  - `2` or `v"2.0"`: Force QASM 2.0 parser
  - `3` or `v"3.0"`: Force QASM 3.0 parser

# Examples
```julia
# Auto-detect version
parse("OPENQASM 2.0; qreg q[2];")  # Uses QASM 2.0 parser
parse("OPENQASM 3.0; qubit[2] q;")  # Uses QASM 3.0 parser

# Force specific version
parse(src, version=2)
parse(src, version=3)
```
"""
function parse(src::String; version=:auto)
    if version == :auto
        detected = detect_version(src)
        return detected >= v"3.0" ? parse_v3(src) : parse_v2(src)
    elseif version == 2 || version == v"2.0"
        return parse_v2(src)
    elseif version == 3 || version == v"3.0"
        return parse_v3(src)
    else
        throw(ArgumentError("Unsupported QASM version: $version"))
    end
end

"""
    parse_v2(src::String)

Parse a QASM 2.0 program to AST.
"""
function parse_v2(src::String)
    ast, ctx = RBNF.runparser(Parse.mainprogram, RBNF.runlexer(Parse.QASMLang, src))
    ctx.tokens.current > ctx.tokens.length || throw(Meta.ParseError("invalid syntax in QASM 2.0 program"))
    return ast
end

"""
    parse_v3(src::String)

Parse a QASM 3.0 program to AST.
"""
function parse_v3(src::String)
    ast, ctx = RBNF.runparser(ParseV3.mainprogram, RBNF.runlexer(ParseV3.QASM3Lang, src))
    ctx.tokens.current > ctx.tokens.length || throw(Meta.ParseError("invalid syntax in QASM 3.0 program"))
    return ast
end

"""
    parse_gate(src::String)

Parse a piece of QASM 2.0 gate program.
"""
function parse_gate(src::String)
    ast, ctx = RBNF.runparser(Parse.gate, RBNF.runlexer(Parse.QASMLang, src))
    ctx.tokens.current > ctx.tokens.length || throw(Meta.ParseError("invalid syntax in QASM program"))
    return ast
end

end
