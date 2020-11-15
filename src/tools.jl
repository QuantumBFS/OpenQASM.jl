module Tools

export issimilar

using ..Types
using RBNF: Token

function issimilar(x::Vector, y::Vector)
    length(x) == length(y) || return false
    for (x_stmt, y_stmt) in zip(x, y)
        issimilar(x_stmt, y_stmt) || return false
    end
    return true
end

function issimilar(x::Token{ta}, y::Token{tb}) where {ta, tb}
    ta === tb || return false
    return x.str == y.str
end

function issimilar(x::ASTNode, y::ASTNode)
    x_t = typeof(x)
    y_t = typeof(y)
    x_t == y_t || return false

    for (xname, yname) in zip(fieldnames(x_t), fieldnames(y_t))
        a = getfield(x, xname)
        b = getfield(y, yname)
        issimilar(a, b) || return false
    end
    return true
end

issimilar(x, y) = x == y

end
