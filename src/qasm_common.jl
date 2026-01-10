"""
Shared grammar rules, token patterns, and type conversions for OpenQASM parsers.

This module provides common functionality used by both QASM 2.0 and 3.0 parsers,
following RBNF's design patterns for parser composition and code reuse.
"""
module QASMCommon

using RBNF
using RBNF: Token

export common_id_pattern, common_float_pattern, common_int_pattern, common_str_pattern,
       common_space_pattern, common_comment_pattern,
       common_expression_rules, common_quantum_ops, common_gate_rules,
       second

# ========== Helper Functions ==========

"""
Extract second element from tuple - used in grammar rules to extract parsed values.
"""
second((a, b)) = b
second(vec::V) where {V<:AbstractArray} = vec[2]

# ========== Shared Token Patterns ==========

"""
Identifier pattern: starts with lowercase letter or underscore, followed by alphanumeric or underscore.
Supports both QASM 2.0 (lowercase start) and 3.0 (allows underscore start).
"""
const COMMON_ID_PATTERN = r"\G[a-z_][A-Za-z0-9_]*"

"""
Floating-point number pattern with optional exponent.
"""
const COMMON_FLOAT_PATTERN = r"\G([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)([eE][-+]?[0-9]+)?"

"""
Integer pattern supporting decimal, hexadecimal (0x), and binary (0b) formats.
"""
const COMMON_INT_PATTERN = r"\G(0[xX][0-9a-fA-F]+|0[bB][01]+|[1-9][0-9]*|0)"

"""
Simple integer pattern for QASM 2.0 (decimal only).
"""
const COMMON_INT_PATTERN_SIMPLE = r"\G([1-9]+[0-9]*|0)"

"""
Whitespace pattern.
"""
const COMMON_SPACE_PATTERN = r"\G\s+"

"""
Single-line comment pattern (// ...).
"""
const COMMON_COMMENT_PATTERN = r"\G//.*"

# ========== Shared Grammar Fragments ==========

"""
Common expression grammar rules used by both QASM 2.0 and 3.0.
Includes arithmetic operations, function calls, and constants.
"""
function common_expression_rules()
    quote
        # Mathematical constants
        con = (:pi | :PI | :π | :tau | :ℇ | :e)

        # Numeric literals
        num = (['(', exp, ')'] % second) | neg | con

        # Binary operators
        add = (:+ | :-)
        mul = (:* | :/)

        # Expression with addition/subtraction
        exp = @direct_recur begin
            init = term
            prefix = (recur, add, term)
        end

        # Term with multiplication/division
        term = @direct_recur begin
            init = num
            prefix = (recur, mul, term)
        end

        # Negation
        neg::Neg := [:-, val = num]

        # Function calls (sin, cos, tan, exp, ln, sqrt)
        call::Call := [name = fn, "(", args = exp, ")"]
        fn = (:sin | :cos | :tan | :exp | :ln | :sqrt)

        # Expression list (comma-separated)
        explist = @direct_recur begin
            init = [exp]
            prefix = [recur..., (',', exp) % second]
        end
    end
end

"""
Common quantum operation rules used by both QASM 2.0 and 3.0.
Includes measure, reset, barrier, and bit addressing.
"""
function common_quantum_ops()
    quote
        # Measurement operation: measure q -> c;
        measure::Measure := [:measure, qarg = bit, :(->), carg = bit, ';']

        # Reset operation: reset q;
        reset::Reset := [:reset, qarg = bit, ';']

        # Barrier operation: barrier q1, q2;
        barrier::Barrier := [:barrier, qargs = bitlist, ';']

        # Bit/qubit reference with optional array index: q[0]
        bit::Bit := [name = id, ['[', address = int, ']'].?]

        # Comma-separated list of bits
        bitlist = @direct_recur begin
            init = [bit]
            prefix = [recur..., (',', bit) % second]
        end
    end
end

"""
Common gate-related rules used by both QASM 2.0 and 3.0.
Includes identifier lists used in gate declarations.
"""
function common_gate_rules()
    quote
        # Comma-separated list of identifiers (for gate parameters)
        idlist = @direct_recur begin
            init = [id]
            prefix = [recur..., (',', id) % second]
        end
    end
end

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
