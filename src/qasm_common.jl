"""
Shared utilities and type conversions for OpenQASM parsers.

This module provides common functionality used by both QASM 2.0 and 3.0 parsers:
- Helper functions for parsing
- Shared type conversions to avoid method overwriting

Note: RBNF does not support function interpolation in @grammar blocks, so grammar
rules cannot be shared via functions and must be defined inline in each parser.
"""
module QASMCommon

using RBNF
using RBNF: Token

export second

# ========== Helper Functions ==========

"""
    second(x)

Extract second element from tuple or array - used in grammar rules to extract parsed values.
"""
second((a, b)) = b
second(vec::V) where {V<:AbstractArray} = vec[2]

# ========== Shared Type Conversions ==========

# These conversions are shared between QASM 2.0 and 3.0
# They're defined here once to avoid duplication and method overwriting

"""
RBNF crate methods for creating default values.
Used by the parser generator to create placeholder values.
"""
RBNF.crate(::Type{Symbol}) = gensym(:qasm)
RBNF.crate(::Type{VersionNumber}) = VersionNumber("0.0.0")

"""
Type conversions from RBNF tokens to Julia types.
These are used during parsing to convert token values.
"""
Base.convert(::Type{VersionNumber}, t::Token) = VersionNumber(t.str)
Base.convert(::Type{String}, t::Token) = t.str
Base.convert(::Type{Int}, t::Token{:int}) = Base.parse(Int, t.str)
Base.convert(::Type{Float64}, t::Token{:float64}) = Base.parse(Float64, t.str)
Base.convert(::Type{Symbol}, t::Token{:id}) = Symbol(t.str)
Base.convert(::Type{Symbol}, t::Token{:reserved}) = Symbol(t.str)
Base.convert(::Type{String}, t::Token{:str}) = String(t.str[2:end-1])

end # module QASMCommon
