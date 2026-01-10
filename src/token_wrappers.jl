# Wrapper types to avoid type piracy
#
# RBNF's design requires extending Base.convert and RBNF.crate for token conversion.
# To avoid type piracy (extending methods for types we don't own), we create wrapper
# types that we DO own, then provide conversions for those types.
#
# This file provides wrapper types that can be used in RBNF grammars to avoid piracy,
# while also maintaining backward compatibility with the existing direct conversions.

# Note: The legacy conversions at the bottom are still type piracy and should be
# migrated away from. They exist only for backward compatibility during the transition.

using RBNF: Token

# ========== Token Wrapper - We own this type ==========

"""
    QASMToken{K}

Wrapper for RBNF.Token that we own, allowing non-piracy method extensions.
This is the primary mechanism to avoid type piracy when converting tokens.

# Example
```julia
# NOT piracy - we own QASMToken
Base.convert(::Type{Symbol}, t::QASMToken{:id}) = Symbol(t.token.str)
```
"""
struct QASMToken{K}
    token::Token{K}

    # Constructor
    QASMToken{K}(t::Token{K}) where {K} = new{K}(t)
end

# Outer constructor for convenience
QASMToken(t::Token{K}) where {K} = QASMToken{K}(t)

# Delegate string access
Base.getproperty(t::QASMToken, s::Symbol) = s === :str ? getfield(getfield(t, :token), :str) : getfield(t, s)

# ========== Conversions from QASMToken (NOT type piracy) ==========

"""
Convert QASMToken to standard Julia types.
These are NOT type piracy because we own QASMToken.
"""
Base.convert(::Type{Symbol}, t::QASMToken{:id}) = Symbol(t.str)
Base.convert(::Type{Symbol}, t::QASMToken{:reserved}) = Symbol(t.str)
Base.convert(::Type{String}, t::QASMToken{:str}) = String(t.str[2:end-1])
Base.convert(::Type{String}, t::QASMToken) = t.str
Base.convert(::Type{Int}, t::QASMToken{:int}) = Base.parse(Int, t.str)
Base.convert(::Type{Float64}, t::QASMToken{:float64}) = Base.parse(Float64, t.str)
Base.convert(::Type{VersionNumber}, t::QASMToken) = VersionNumber(t.str)
Base.convert(::Type{Bool}, t::QASMToken{:reserved}) = (t.str == "const")

# ========== TEMPORARY: Direct Token conversions (TYPE PIRACY) ==========

# WARNING: These are type piracy and exist only for backward compatibility
# with existing RBNF parsers. New code should use QASMToken wrapper instead.
#
# TODO: Migrate all parsers to use QASMToken and remove these.

Base.convert(::Type{Symbol}, t::Token{:id}) = Symbol(t.str)
Base.convert(::Type{Symbol}, t::Token{:reserved}) = Symbol(t.str)
Base.convert(::Type{String}, t::Token{:str}) = String(t.str[2:end-1])
Base.convert(::Type{String}, t::Token) = t.str
Base.convert(::Type{Int}, t::Token{:int}) = Base.parse(Int, t.str)
Base.convert(::Type{Float64}, t::Token{:float64}) = Base.parse(Float64, t.str)
Base.convert(::Type{VersionNumber}, t::Token) = VersionNumber(t.str)
Base.convert(::Type{Bool}, t::Token{:reserved}) = (t.str == "const")
Base.convert(::Type{Bool}, ::Nothing) = false

# WARNING: Type piracy for RBNF.crate
RBNF.crate(::Type{Symbol}) = gensym(:qasm)
RBNF.crate(::Type{VersionNumber}) = VersionNumber("0.0.0")
