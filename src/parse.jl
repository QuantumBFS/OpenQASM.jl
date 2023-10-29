module Parse

using RBNF
using RBNF: Token

using ..Types

struct QASMLang end

second((a, b)) = b
second(vec::V) where {V<:AbstractArray} = vec[2]

# roses are red
# violets are blue
# pirates are good
RBNF.crate(::Type{Symbol}) = gensym(:qasm)
RBNF.crate(::Type{VersionNumber}) = VersionNumber("0.0.0")

Base.convert(::Type{VersionNumber}, t::Token) = VersionNumber(t.str)
Base.convert(::Type{String}, t::Token) = t.str
Base.convert(::Type{Int}, t::Token{:int}) = Base.parse(Int, t.str)
Base.convert(::Type{Float64}, t::Token{:float64}) = Base.parse(Float64, t.str)
Base.convert(::Type{Symbol}, t::Token{:id}) = Symbol(t.str)
Base.convert(::Type{Symbol}, t::Token{:reserved}) = Symbol(t.str)
Base.convert(::Type{String}, t::Token{:str}) = String(t.str[2:end-1])

RBNF.@parser QASMLang begin
    # define ignorances
    ignore{space, comment}

    @grammar
    # define grammars
    mainprogram::MainProgram := ["OPENQASM", version = float64, ';', prog = program]
    program = statement{*}
    statement = (regdecl | gate | opaque | qop | ifstmt | barrier | inc)
    # stmts
    ifstmt::IfStmt := [:if, '(', left = id, :(==), right = int, ')', body = qop]
    opaque::Opaque := [:opaque, name = id, ['(', [cargs = idlist].?, ')'].?, qargs = idlist, ';']
    barrier::Barrier := [:barrier, qargs = bitlist, ';']
    regdecl::RegDecl := [type = :qreg | :creg, name = id, '[', size = int, ']', ';']
    inc::Include := [:include, file = str, ';']
    # gate
    gate::Gate := [decl = gatedecl, [body = goplist].?, '}']
    gatedecl::GateDecl := [:gate, name = id, ['(', [cargs = idlist].?, ')'].?, qargs = idlist, '{']

    goplist = (uop | barrier){*}

    # qop
    qop = (uop | measure | reset)
    reset::Reset := [:reset, qarg = bit, ';']
    measure::Measure := [:measure, qarg = bit, :(->), carg = bit, ';']

    uop = (inst | ugate | csemantic_gate)
    inst::Instruction := [name = id, ['(', [cargs = explist].?, ')'].?, qargs = bitlist, ';']
    ugate::UGate := [:U, '(', z1 = exp, ',', y = exp, ',', z2 = exp, ')', qarg = bit, ';']
    csemantic_gate::CXGate := [:CX, ctrl = bit, ',', qarg = bit, ';']

    idlist = @direct_recur begin
        init = [id]
        prefix = [recur..., (',', id) % second]
    end

    bit::Bit := [name = id, ['[', address = int, ']'].?]
    bitlist = @direct_recur begin
        init = [bit]
        prefix = [recur..., (',', bit) % second]
    end

    explist = @direct_recur begin
        init = [exp]
        prefix = [recur..., (',', exp) % second]
    end

    con = (float64 | int | :pi | id | call)
    num = (['(', exp, ')'] % second) | neg | con
    add = ( :+ | :- )
    mul = ( :* | :/ )
    exp = @direct_recur begin
        init = term
        prefix = (recur, add, term)
    end
    term = @direct_recur begin
        init = num
        prefix = (recur, mul, term)
    end
    # term = (add | sub | num)
    neg::Neg := [:-, val = num]
    call::Call := [name=fn, "(", args = exp, ")"]    
    fn = (:sin | :cos | :tan | :exp | :ln | :sqrt)
    # binop = (:+ | :- | :* | :/)

    # define tokens
    @token
    id := r"\G[a-z]{1}[A-Za-z0-9_]*"
    float64 := r"\G([0-9]+\.[0-9]*|[0-9]*\.[0.9]+)([eE][-+]?[0-9]+)?"
    int := r"\G([1-9]+[0-9]*|0)"
    space := r"\G\s+"
    comment := r"\G//.*"
    str := @quote ("\"", "\\\"", "\"")
end

end # Parse
