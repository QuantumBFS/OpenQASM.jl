module TypesV3

using RBNF
using MLStyle
using RBNF: Token
using ..Types: ASTNode, print_kw, print_list

# Import print_qasm to extend it
import ..Types: print_qasm

export IntType, UIntType, FloatType, BitType, AngleType,
    ClassicalDecl, QubitDecl,
    IfElseStmt, WhileStmt, ForStmt, BreakStmt, ContinueStmt,
    ModifiedGate, GateModifier,
    InputDecl, OutputDecl,
    RangeExpr, DiscreteSet

# ========== Classical Type System ==========

abstract type QASMType <: ASTNode end

struct IntType <: QASMType
    width::Union{Token,Nothing}  # bit width, e.g., int[32]
end

IntType() = IntType(nothing)

struct UIntType <: QASMType
    width::Union{Token,Nothing}  # bit width, e.g., uint[32]
end

UIntType() = UIntType(nothing)

struct FloatType <: QASMType
    width::Union{Token,Nothing}  # bit width, e.g., float[64]
end

FloatType() = FloatType(nothing)

struct BitType <: QASMType
    width::Union{Token,Nothing}  # bit width, e.g., bit[5]
end

BitType() = BitType(nothing)

struct AngleType <: QASMType
    width::Union{Token,Nothing}  # bit width, e.g., angle[20]
end

AngleType() = AngleType(nothing)

# ========== Declarations ==========

struct ClassicalDecl <: ASTNode
    const_modifier::Bool
    type::QASMType
    name
    initializer::Union{Any,Nothing}
end

struct QubitDecl <: ASTNode
    name
    size::Union{Token,Nothing}  # Nothing for single qubit, Token for qubit[n]
end

# ========== Control Flow ==========

"""
Helper function to normalize block_or_stmt results.
Handles both blocks ('{', statements, '}') and single statements.
"""
function normalize_block(body)
    if body isa Tuple && length(body) == 3 && body[1] == '{'
        # It's a block: ('{', statements, '}'), extract the middle
        return Vector{Any}(body[2])
    elseif body isa AbstractVector
        # Already a vector
        return Vector{Any}(body)
    else
        # Single statement, wrap in vector
        return Any[body]
    end
end

struct IfElseStmt <: ASTNode
    condition
    if_body::Vector{Any}
    else_body::Union{Vector{Any},Nothing}

    function IfElseStmt(condition, if_body, else_body=nothing)
        new(condition, normalize_block(if_body),
            else_body === nothing ? nothing : normalize_block(else_body))
    end
end

struct WhileStmt <: ASTNode
    condition
    body::Vector{Any}

    function WhileStmt(condition, body)
        new(condition, normalize_block(body))
    end
end

struct ForStmt <: ASTNode
    type::Union{QASMType,Nothing}  # Optional type declaration
    iterator
    range  # Can be RangeExpr or DiscreteSet
    body::Vector{Any}

    function ForStmt(type, iterator, range, body)
        new(type, iterator, range, normalize_block(body))
    end
end

struct RangeExpr <: ASTNode
    start
    step::Union{Any,Nothing}  # Optional step
    stop
end

struct DiscreteSet <: ASTNode
    elements::Vector{Any}

    function DiscreteSet(elements)
        new(Vector{Any}(elements))
    end
end

struct BreakStmt <: ASTNode end

struct ContinueStmt <: ASTNode end

# ========== Gate Modifiers ==========

struct GateModifier
    type::Symbol  # :inv, :ctrl, :negctrl, :pow
    param::Union{Any,Nothing}  # For pow(n), stores n

    GateModifier(type::Symbol) = new(type, nothing)
    GateModifier(type::Symbol, param) = new(type, param)
end

struct ModifiedGate <: ASTNode
    modifiers::Vector{GateModifier}
    gate

    function ModifiedGate(modifiers, gate)
        new(Vector{GateModifier}(modifiers), gate)
    end
end

# ========== Input/Output ==========

struct InputDecl <: ASTNode
    type::QASMType
    name
end

struct OutputDecl <: ASTNode
    type::QASMType
    name
end

# ========== Pretty Printing ==========

function print_qasm(io::IO, type::IntType)
    print_kw(io, "int")
    if type.width !== nothing
        print(io, "[")
        print_qasm(io, type.width)
        print(io, "]")
    end
end

function print_qasm(io::IO, type::UIntType)
    print_kw(io, "uint")
    if type.width !== nothing
        print(io, "[")
        print_qasm(io, type.width)
        print(io, "]")
    end
end

function print_qasm(io::IO, type::FloatType)
    print_kw(io, "float")
    if type.width !== nothing
        print(io, "[")
        print_qasm(io, type.width)
        print(io, "]")
    end
end

function print_qasm(io::IO, type::BitType)
    print_kw(io, "bit")
    if type.width !== nothing
        print(io, "[")
        print_qasm(io, type.width)
        print(io, "]")
    end
end

function print_qasm(io::IO, type::AngleType)
    print_kw(io, "angle")
    if type.width !== nothing
        print(io, "[")
        print_qasm(io, type.width)
        print(io, "]")
    end
end

function print_qasm(io::IO, decl::ClassicalDecl)
    if decl.const_modifier
        print_kw(io, "const ")
    end
    print_qasm(io, decl.type)
    print(io, " ")
    print_qasm(io, decl.name)
    if decl.initializer !== nothing
        print(io, " = ")
        print_qasm(io, decl.initializer)
    end
    print(io, ";")
end

function print_qasm(io::IO, decl::QubitDecl)
    print_kw(io, "qubit")
    if decl.size !== nothing
        print(io, "[")
        print_qasm(io, decl.size)
        print(io, "]")
    end
    print(io, " ")
    print_qasm(io, decl.name)
    print(io, ";")
end

function print_qasm(io::IO, stmt::IfElseStmt)
    print_kw(io, "if ")
    print(io, "(")
    print_qasm(io, stmt.condition)
    print(io, ") {")
    println(io)
    for s in stmt.if_body
        print(io, " "^2)
        print_qasm(io, s)
        println(io)
    end
    print(io, "}")
    if stmt.else_body !== nothing
        print_kw(io, " else ")
        print(io, "{")
        println(io)
        for s in stmt.else_body
            print(io, " "^2)
            print_qasm(io, s)
            println(io)
        end
        print(io, "}")
    end
end

function print_qasm(io::IO, stmt::WhileStmt)
    print_kw(io, "while ")
    print(io, "(")
    print_qasm(io, stmt.condition)
    print(io, ") {")
    println(io)
    for s in stmt.body
        print(io, " "^2)
        print_qasm(io, s)
        println(io)
    end
    print(io, "}")
end

function print_qasm(io::IO, stmt::ForStmt)
    print_kw(io, "for ")
    if stmt.type !== nothing
        print_qasm(io, stmt.type)
        print(io, " ")
    end
    print_qasm(io, stmt.iterator)
    print_kw(io, " in ")
    print_qasm(io, stmt.range)
    print(io, " {")
    println(io)
    for s in stmt.body
        print(io, " "^2)
        print_qasm(io, s)
        println(io)
    end
    print(io, "}")
end

function print_qasm(io::IO, range::RangeExpr)
    print(io, "[")
    print_qasm(io, range.start)
    if range.step !== nothing
        print(io, ":")
        print_qasm(io, range.step)
    end
    print(io, ":")
    print_qasm(io, range.stop)
    print(io, "]")
end

function print_qasm(io::IO, set::DiscreteSet)
    print(io, "{")
    for (i, elem) in enumerate(set.elements)
        print_qasm(io, elem)
        if i != length(set.elements)
            print(io, ", ")
        end
    end
    print(io, "}")
end

function print_qasm(io::IO, ::BreakStmt)
    print_kw(io, "break")
    print(io, ";")
end

function print_qasm(io::IO, ::ContinueStmt)
    print_kw(io, "continue")
    print(io, ";")
end

function print_qasm(io::IO, mod::GateModifier)
    if mod.type == :inv
        print_kw(io, "inv")
    elseif mod.type == :ctrl
        print_kw(io, "ctrl")
    elseif mod.type == :negctrl
        print_kw(io, "negctrl")
    elseif mod.type == :pow
        print_kw(io, "pow")
        print(io, "(")
        print_qasm(io, mod.param)
        print(io, ")")
    end
end

function print_qasm(io::IO, gate::ModifiedGate)
    for (i, mod) in enumerate(gate.modifiers)
        print_qasm(io, mod)
        print(io, " ")
    end
    print(io, "@ ")
    print_qasm(io, gate.gate)
end

function print_qasm(io::IO, decl::InputDecl)
    print_kw(io, "input ")
    print_qasm(io, decl.type)
    print(io, " ")
    print_qasm(io, decl.name)
    print(io, ";")
end

function print_qasm(io::IO, decl::OutputDecl)
    print_kw(io, "output ")
    print_qasm(io, decl.type)
    print(io, " ")
    print_qasm(io, decl.name)
    print(io, ";")
end

# MLStyle pattern matching support
@as_record IntType
@as_record UIntType
@as_record FloatType
@as_record BitType
@as_record AngleType
@as_record ClassicalDecl
@as_record QubitDecl
@as_record IfElseStmt
@as_record WhileStmt
@as_record ForStmt
@as_record RangeExpr
@as_record DiscreteSet
@as_record BreakStmt
@as_record ContinueStmt
@as_record ModifiedGate
@as_record InputDecl
@as_record OutputDecl

end
