module Tools

export kw_qreg, kw_creg, kw_gate, qasm_id, qasm_int, qasm_f64, qasm_str

using ..Types
using MLStyle
using RBNF: Token

const kw_qreg = Token{:reserved}("qreg")
const kw_creg = Token{:reserved}("creg")
const kw_gate = Token{:reserved}("gate")

qasm_id(s) = qasm_id(string(s))
qasm_id(s::String) = Token{:id}(s)
qasm_int(n::Int) = Token{:int}(string(n))
qasm_f64(x) = Token{:float64}(string(Float64(x)))
qasm_str(x) = Token{:str}(string("\"", x, "\""))

Base.isapprox(lhs::ASTNode, rhs::ASTNode) = cmp_ast(lhs, rhs)
Base.isapprox(lhs::Token, rhs::Token) = cmp_ast(lhs, rhs)

function cmp_ast(lhs::Token{A}, rhs::Token{B}) where {A, B}
    A === B || return false
    return lhs.str == rhs.str
end

function cmp_ast(x::Vector, y::Vector)
    length(x) == length(y) || return false
    for (x_stmt, y_stmt) in zip(x, y)
        cmp_ast(x_stmt, y_stmt) || return false
    end
    return true
end

cmp_ast(lhs::ASTNode, rhs::ASTNode) = false
function cmp_ast(lhs::T, rhs::T) where {T <: ASTNode}
    for name in fieldnames(T)
        a = getfield(lhs, name)
        b = getfield(rhs, name)
        cmp_ast(a, b) || return false
    end
    return true
end

function cmp_ast(lhs::Instruction, rhs::Instruction)
    lhs.name == rhs.name || return false
    all(map(cmp_exp, lhs.cargs, rhs.cargs)) || return false
    return cmp_ast(lhs.qargs, rhs.qargs)
end

function cmp_exp(lhs::Tuple, rhs::Tuple)
    length(lhs) == length(rhs) || return false
    return all(map(cmp_ast, lhs, rhs))
end

cmp_exp(lhs, rhs) = cmp_ast(lhs, rhs)
cmp_ast(lhs, rhs) = lhs == rhs

@deprecate issimilar(x, y) cmp_ast(x, y)

end
