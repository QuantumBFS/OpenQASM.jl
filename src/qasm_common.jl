# Shared utilities for OpenQASM parsers
#
# This file provides common functionality used by both QASM 2.0 and 3.0 parsers.
# It's included directly (not as a module).
#
# Note: RBNF does not support function interpolation in @grammar blocks, so grammar
# rules cannot be shared via functions and must be defined inline in each parser.
#
# Type conversions are now in token_wrappers.jl to better handle type piracy issues.

# ========== Helper Functions ==========

"""
    second(x)

Extract second element from tuple or array - used in grammar rules to extract parsed values.
"""
second((a, b)) = b
second(vec::V) where {V<:AbstractArray} = vec[2]
