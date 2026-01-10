# Shared utilities for OpenQASM parsers
#
# This file provides common functionality used by both QASM 2.0 and 3.0 parsers.
# It's included directly (not as a module) to avoid type piracy issues.
#
# Note: RBNF does not support function interpolation in @grammar blocks, so grammar
# rules cannot be shared via functions and must be defined inline in each parser.

# ========== Helper Functions ==========

"""
    second(x)

Extract second element from tuple or array - used in grammar rules to extract parsed values.
"""
second((a, b)) = b
second(vec::V) where {V<:AbstractArray} = vec[2]

# ========== Shared Type Conversions ==========

# These conversions are needed by RBNF's parser generator.
# They're defined here once to avoid duplication between QASM 2.0 and 3.0 parsers.
#
# Note: These extend Base methods for types we don't own, which is necessary for
# RBNF to work but should be done carefully. They're scoped to the OpenQASM module.

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
Base.convert(::Type{VersionNumber}, t::RBNF.Token) = VersionNumber(t.str)
Base.convert(::Type{String}, t::RBNF.Token) = t.str
Base.convert(::Type{Int}, t::RBNF.Token{:int}) = Base.parse(Int, t.str)
Base.convert(::Type{Float64}, t::RBNF.Token{:float64}) = Base.parse(Float64, t.str)
Base.convert(::Type{Symbol}, t::RBNF.Token{:id}) = Symbol(t.str)
Base.convert(::Type{Symbol}, t::RBNF.Token{:reserved}) = Symbol(t.str)
Base.convert(::Type{String}, t::RBNF.Token{:str}) = String(t.str[2:end-1])
