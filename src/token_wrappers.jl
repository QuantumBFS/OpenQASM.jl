# Type conversions for RBNF tokens
#
# RBNF's design requires extending Base.convert and RBNF.crate for token conversion.
# This is type piracy (extending methods for types we don't own), but it's unavoidable
# given RBNF's architecture.
#
# The alternative would be to modify RBNF itself to support custom wrapper types,
# which is beyond the scope of this package.

using RBNF: Token

# ========== Token conversions (type piracy - unavoidable for RBNF) ==========

Base.convert(::Type{Symbol}, t::Token{:id}) = Symbol(t.str)
Base.convert(::Type{Symbol}, t::Token{:reserved}) = Symbol(t.str)
Base.convert(::Type{String}, t::Token{:str}) = String(t.str[2:end-1])
Base.convert(::Type{String}, t::Token) = t.str
Base.convert(::Type{Int}, t::Token{:int}) = Base.parse(Int, t.str)
Base.convert(::Type{Float64}, t::Token{:float64}) = Base.parse(Float64, t.str)
Base.convert(::Type{VersionNumber}, t::Token) = VersionNumber(t.str)
Base.convert(::Type{Bool}, t::Token{:reserved}) = (t.str == "const")
Base.convert(::Type{Bool}, ::Nothing) = false

# RBNF.crate methods (type piracy - required for RBNF grammar system)
RBNF.crate(::Type{Symbol}) = gensym(:qasm)
RBNF.crate(::Type{VersionNumber}) = VersionNumber("0.0.0")
