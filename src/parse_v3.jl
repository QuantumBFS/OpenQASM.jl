module ParseV3

using RBNF
using RBNF: Token

using ..Types
using ..TypesV3
using ..QASMCommon

# Import shared utilities
using ..QASMCommon: second

struct QASM3Lang end

# Customize struct names to avoid collisions with QASM 2.0
RBNF.typename(::Type{QASM3Lang}, name::Symbol) = Symbol(:QASM3_, name)

# QASM 3.0 specific type conversions (only define what's unique to v3.0)
Base.convert(::Type{Bool}, t::Token{:reserved}) = (t.str == "const")
Base.convert(::Type{Bool}, ::Nothing) = false

# RBNF crate methods for QASM 3.0 specific types
RBNF.crate(::Type{TypesV3.QASMType}) = TypesV3.IntType()
RBNF.crate(::Type{TypesV3.IntType}) = TypesV3.IntType()
RBNF.crate(::Type{TypesV3.UIntType}) = TypesV3.UIntType()
RBNF.crate(::Type{TypesV3.FloatType}) = TypesV3.FloatType()
RBNF.crate(::Type{TypesV3.BitType}) = TypesV3.BitType()
RBNF.crate(::Type{TypesV3.AngleType}) = TypesV3.AngleType()
RBNF.crate(::Type{TypesV3.GateModifier}) = TypesV3.GateModifier(:inv)

RBNF.@parser QASM3Lang begin
    # Define ignorances
    ignore{space, comment}

    @grammar
    # Top-level program structure
    mainprogram::MainProgram := ["OPENQASM", version = float64, ';', prog = program]
    program = statement{*}

    # Statements - QASM 3.0 includes more types than 2.0
    statement = (
        classical_decl | qubit_decl | legacy_regdecl |
        gate_decl | gate_call |
        control_stmt | quantum_stmt |
        io_decl | include_stmt
    )

    # ========== Classical Declarations ==========

    classical_decl::ClassicalDecl := [
        [const_modifier = :const].?,
        type = qasm_type,
        name = id,
        ['=', initializer = expr].?,
        ';'
    ]

    # Classical type system
    qasm_type = (int_type | uint_type | float_type | bit_type | angle_type)

    int_type::IntType := [:int, ['[', width = int, ']'].?]
    uint_type::UIntType := [:uint, ['[', width = int, ']'].?]
    float_type::FloatType := [:float, ['[', width = int, ']'].?]
    bit_type::BitType := [:bit, ['[', width = int, ']'].?]
    angle_type::AngleType := [:angle, ['[', width = int, ']'].?]

    # ========== Quantum Declarations ==========

    # New QASM 3.0 syntax: qubit[n] name;
    qubit_decl::QubitDecl := [:qubit, ['[', size = int, ']'].?, name = id, ';']

    # Legacy QASM 2.0 syntax (still supported in 3.0)
    legacy_regdecl::RegDecl := [type = :qreg | :creg, name = id, '[', size = int, ']', ';']

    # ========== Control Flow ==========

    control_stmt = (if_else_stmt | while_stmt | for_stmt | break_stmt | continue_stmt)

    if_else_stmt::IfElseStmt := [
        :if, '(', condition = expr, ')',
        if_body = block_or_stmt,
        [:else, else_body = block_or_stmt].?
    ]

    while_stmt::WhileStmt := [
        :while, '(', condition = expr, ')',
        body = block_or_stmt
    ]

    for_stmt::ForStmt := [
        :for,
        [type = qasm_type].?,
        iterator = id,
        :in,
        range = range_or_set,
        body = block_or_stmt
    ]

    range_or_set = (range_expr | discrete_set)

    range_expr::RangeExpr := [
        '[',
        start = expr,
        [[':', step = expr].?, ':', stop = expr].?,
        ']'
    ]

    discrete_set::DiscreteSet := ['{', elements = expr_list, '}']

    break_stmt::BreakStmt := [:break, ';']
    continue_stmt::ContinueStmt := [:continue, ';']

    # Block or single statement
    block_or_stmt = ('{', statement{*}, '}') | statement

    # ========== Gate Declarations and Calls ==========

    # Gate declarations (from QASM 2.0)
    gate_decl::Gate := [decl = gatedecl, [body = goplist].?, '}']
    gatedecl::GateDecl := [:gate, name = id, ['(', [cargs = idlist].?, ')'].?, qargs = idlist, '{']
    goplist = (uop | barrier){*}
    opaque::Opaque := [:opaque, name = id, ['(', [cargs = idlist].?, ')'].?, qargs = idlist, ';']

    # Gate calls - can be modified or simple
    gate_call = (modified_gate | simple_gate_call)

    # Modified gates: inv @ h q; ctrl @ x q[0], q[1]; pow(2) @ s q;
    modified_gate::ModifiedGate := [modifiers = modifier_list, '@', gate = simple_gate_call]

    modifier_list = @direct_recur begin
        init = [gate_modifier]
        prefix = [recur..., gate_modifier]
    end

    gate_modifier = (inv_modifier | ctrl_modifier | negctrl_modifier | pow_modifier)
    inv_modifier = :inv => GateModifier(:inv)
    ctrl_modifier = :ctrl => GateModifier(:ctrl)
    negctrl_modifier = :negctrl => GateModifier(:negctrl)
    pow_modifier::GateModifier := [:pow, '(', param = expr, ')']

    # Simple gate calls (unmodified)
    simple_gate_call = (inst | ugate | csemantic_gate | barrier | opaque)

    # ========== Quantum Operations ==========

    quantum_stmt = (measure | reset | barrier)

    # Basic quantum operations (inst and ugate are QASM 3.0 specific due to enhanced expressions)
    uop = (ugate | inst | csemantic_gate | barrier)
    inst::Instruction := [name = id, ['(', [cargs = expr_list].?, ')'].?, qargs = bitlist, ';']
    ugate::UGate := ['U', '(', z1 = expr, ',', y = expr, ',', z2 = expr, ')', qarg = bit, ';']
    csemantic_gate::CXGate := [:CX, ctrl = bit, ',', qarg = bit, ';']  # QASM 2.0 compatibility

    # Shared quantum operations (defined inline - RBNF doesn't support function interpolation in @grammar)
    measure::Measure := [:measure, qarg = bit, :(->), carg = bit, ';']
    reset::Reset := [:reset, qarg = bit, ';']
    barrier::Barrier := [:barrier, qargs = bitlist, ';']

    bit::Bit := [name = id, ['[', address = int, ']'].?]
    bitlist = @direct_recur begin
        init = [bit]
        prefix = [recur..., (',', bit) % second]
    end

    idlist = @direct_recur begin
        init = [id]
        prefix = [recur, ',', id]
    end

    # ========== Input/Output Declarations ==========

    io_decl = (input_decl | output_decl)
    input_decl::InputDecl := [:input, type = qasm_type, name = id, ';']
    output_decl::OutputDecl := [:output, type = qasm_type, name = id, ';']

    # ========== Include Statements ==========

    include_stmt::Include := [:include, file = str, ';']

    # ========== Expressions ==========

    # Expression grammar with operator precedence
    # Supports: logical (&&, ||), comparison (==, !=, <, >, <=, >=), arithmetic (+, -, *, /, %), power (**)

    expr = logical_or_expr

    # Logical operators - match as sequences since lexer splits multi-char operators
    logical_or_expr = @direct_recur begin
        init = logical_and_expr
        prefix = (recur, '|', '|', logical_and_expr)
    end

    logical_and_expr = @direct_recur begin
        init = comparison_expr
        prefix = (recur, '&', '&', comparison_expr)
    end

    comparison_expr = @direct_recur begin
        init = arith_expr
        prefix = (recur, comp_op, arith_expr)
    end

    # Comparison operators - need to match multi-char as sequences since lexer splits them
    comp_op = (
        ['=', '='] | ['!', '='] | ['<', '='] | ['>', '='] |
        '<' | '>'
    )

    add = (:+ | :-)

    arith_expr = @direct_recur begin
        init = term
        prefix = (recur, add, term)
    end
    mul = (:* | :/)

    # Base case for expressions - similar to QASM 2.0
    con = (float64 | int | :pi | :PI | :π | :tau | :ℇ | :e | id | call | bit)
    num = (['(', expr, ')'] % second) | neg | con

    term = @direct_recur begin
        init = num
        prefix = (recur, mul, term)
    end

    # QASM 3.0 specific: enhanced function calls and factors
    call::Call := [name = id, '(', args = expr, ')']
    neg::Neg := ['-', val = num]

    # ========== Lists ==========

    # Expression list for QASM 3.0 (uses enhanced expr instead of exp)
    expr_list = @direct_recur begin
        init = expr
        prefix = (recur, ',', expr)
    end

    # Define tokens using shared patterns
    @token
    id := r"\G[a-z_][A-Za-z0-9_]*"  # QASM 3.0: can start with underscore
    float64 := r"\G([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)([eE][-+]?[0-9]+)?"
    int := r"\G(0[xX][0-9a-fA-F]+|0[bB][01]+|[1-9][0-9]*|0)"  # QASM 3.0: hex/binary support
    str := @quote ("\"", "\\\"", "\"")
    space := r"\G\s+"
    comment := r"\G//.*"
end

end # ParseV3
