module Parse

using RBNF
using RBNF: Token

using ..Types

# Import shared utilities from parent module
import ..second

struct QASMLang end

# Customize struct names to avoid collisions with QASM 3.0
RBNF.typename(::Type{QASMLang}, name::Symbol) = Symbol(:QASM2_, name)

RBNF.@parser QASMLang begin
    # Define ignorances
    ignore{space, comment}

    @grammar
    # Top-level program structure
    mainprogram::MainProgram := ["OPENQASM", version = float64, ';', prog = program]
    program = statement{*}

    # Statements (QASM 2.0 specific)
    statement = (regdecl | gate | opaque | qop | ifstmt | barrier | inc)

    # QASM 2.0 specific statements
    ifstmt::IfStmt := [:if, '(', left = id, :(==), right = int, ')', body = qop]
    opaque::Opaque := [:opaque, name = id, ['(', [cargs = idlist].?, ')'].?, qargs = idlist, ';']
    regdecl::RegDecl := [type = :qreg | :creg, name = id, '[', size = int, ']', ';']
    inc::Include := [:include, file = str, ';']

    # Gate declarations and operations
    gate::Gate := [decl = gatedecl, [body = goplist].?, '}']
    gatedecl::GateDecl := [:gate, name = id, ['(', [cargs = idlist].?, ')'].?, qargs = idlist, '{']
    goplist = (uop | barrier){*}

    # Quantum operations
    qop = (uop | measure | reset)
    uop = (inst | ugate | csemantic_gate)
    inst::Instruction := [name = id, ['(', [cargs = explist].?, ')'].?, qargs = bitlist, ';']
    ugate::UGate := [:U, '(', z1 = exp, ',', y = exp, ',', z2 = exp, ')', qarg = bit, ';']
    csemantic_gate::CXGate := [:CX, ctrl = bit, ',', qarg = bit, ';']

    # Grammar rules (duplicated from QASM 2.0 for compatibility)
    # Note: Can't use function interpolation in @grammar, so these are defined inline

    # Identifier list
    idlist = @direct_recur begin
        init = [id]
        prefix = [recur..., (',', id) % second]
    end

    # Bit/qubit reference and list
    bit::Bit := [name = id, ['[', address = int, ']'].?]
    bitlist = @direct_recur begin
        init = [bit]
        prefix = [recur..., (',', bit) % second]
    end

    # Measurement, reset, barrier
    measure::Measure := [:measure, qarg = bit, :(->), carg = bit, ';']
    reset::Reset := [:reset, qarg = bit, ';']
    barrier::Barrier := [:barrier, qargs = bitlist, ';']

    # Expression list and expressions
    explist = @direct_recur begin
        init = [exp]
        prefix = [recur..., (',', exp) % second]
    end

    con = (float64 | int | :pi | id | call)
    num = (['(', exp, ')'] % second) | neg | con
    add = (:+ | :-)
    mul = (:* | :/)
    exp = @direct_recur begin
        init = term
        prefix = (recur, add, term)
    end
    term = @direct_recur begin
        init = num
        prefix = (recur, mul, term)
    end
    neg::Neg := [:-, val = num]
    call::Call := [name = fn, "(", args = exp, ")"]
    fn = (:sin | :cos | :tan | :exp | :ln | :sqrt)

    # Define tokens using shared patterns
    @token
    id := r"\G[a-z]{1}[A-Za-z0-9_]*"  # QASM 2.0: must start with lowercase letter
    float64 := r"\G([0-9]+\.[0-9]*|[0-9]*\.[0.9]+)([eE][-+]?[0-9]+)?"
    int := r"\G([1-9]+[0-9]*|0)"  # QASM 2.0: decimal only
    space := r"\G\s+"
    comment := r"\G//.*"
    str := @quote ("\"", "\\\"", "\"")
end

end # Parse
