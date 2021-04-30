using OpenQASM
using OpenQASM.Types
using OpenQASM.Tools
using MLStyle
using RBNF: Token
using Test

@testset "conversion" begin
    @test convert(String, Token{:str}("\"abc\"")) == "abc"
    @test convert(Symbol, Token{:id}("abc")) === :abc
    @test convert(Float64, Token{:float64}("0.23")) == 0.23
    @test convert(Int, Token{:int}("1")) == 1
end

@testset "qasm token helper" begin
    @test qasm_id("abc") ≈ Token{:id}("abc")
    @test qasm_id(:abc) ≈ Token{:id}("abc")
    @test qasm_int(2) ≈ Token{:int}("2")
    @test qasm_f64(2.3) ≈ Token{:float64}("2.3")
    @test qasm_str("abc") ≈ Token{:str}("\"abc\"")        
end

@testset "Bit(::String[, addrs])" begin
    bit = Bit("qreg")
    @test bit.name == qasm_id("qreg")
    @test bit.address === nothing

    @test bit = Bit("qreg", 2)
    @test bit.name == qasm_id("qreg")
    @test bit.address == qasm_int(2)
end

@testset "qasm parser" begin

    qasm = """OPENQASM 2.0;
    include "qelib1.inc";
    gate custom(lambda) a {
        u1(sin(lambda) + 1) a;
    }
    // comment
    gate g a
    {
        U(0,0,0) a;
    }

    qreg q[4];
    creg c1[1];
    creg c2[1];
    U(-1.0, pi/2+3, 3.0) q[2];
    CX q[1], q[2];
    custom(0.3) q[3];
    barrier q;
    h q[0];
    measure q[0] -> c0[0];
    if(c0==1) z q[2];
    u3(0.1 + 0.2, 0.2, 0.3) q[0];
    """

    ast = OpenQASM.parse(qasm)
    println(ast)

    @testset "mainprogram" begin
        @test ast isa MainProgram
        @test ast.version == v"2.0.0"
    end

    @test @match ast begin
        MainProgram(v"2.0.0", progs) => true
        _ => false
    end

    @testset "include" begin
        @test ast.prog[1] isa Include
        @test ast.prog[1].file isa Token{:str}
        @test ast.prog[1].file.str == "\"qelib1.inc\""

        token = @match ast.prog[1] begin
            Include(file) => file
            _ => nothing
        end
        @test token.str == "\"qelib1.inc\""
    end

    @testset "gate custom(lambda) a" begin
        @test ast.prog[2] isa Gate
        custom = ast.prog[2]
        
        @test @match custom begin
            Gate(GateDecl(name, cargs, qargs), body) => true
            _ => false
        end

        @test custom.decl.name isa Token{:id}
        @test custom.decl.name.str == "custom"
        @test length(custom.decl.cargs) == 1
        @test custom.decl.cargs[1] isa Token{:id}
        @test custom.decl.cargs[1].str == "lambda"
        @test length(custom.decl.qargs) == 1
        @test custom.decl.qargs[1] isa Token{:id}
        @test custom.decl.qargs[1].str == "a"

        @test length(custom.body) == 1
        @test custom.body[1] isa Instruction
        inst = custom.body[1]
        @test inst.name == "u1"
        @test length(inst.cargs) == 1
        @test length(inst.qargs) == 1
        @test inst.cargs[1] isa Tuple
        @test inst.qargs[1] isa Bit
        carg = inst.cargs[1]
        qarg = inst.qargs[1]
        @test length(carg) == 3
        @test carg[1] isa Call
        @test carg[2] isa Token{:reserved}
        @test carg[3] isa Token{:int}
        @test carg[1].name === :sin
        @test carg[1].args.str == "lambda"
        @test carg[2].str == "+"
        @test carg[3].str == "1"
        @test qarg.name.str == "a"
        @test qarg.address === nothing
    end

    @testset "gate g" begin
        @test ast.prog[3] isa Gate
        g = ast.prog[3]
        @test isempty(g.decl.cargs)
        @test length(g.decl.qargs) == 1
        @test g.decl.qargs[1] isa Token{:id}
        @test g.decl.qargs[1].str == "a"
        @test g.decl.name isa Token{:id}
        @test g.decl.name.str == "g"

        @test length(g.body) == 1
        @test g.body[1] isa UGate
        ugate = g.body[1]
        @test ugate.qarg isa Bit
        @test ugate.qarg.name.str == "a"
        @test ugate.qarg.address === nothing
        @test ugate.y isa Token{:int}
        @test ugate.y.str == "0"
        @test ugate.z1.str == "0"
        @test ugate.z2.str == "0"
    end

    @testset "qreg" begin
        @test ast.prog[4] isa RegDecl
        reg = ast.prog[4]
        @test reg.name isa Token{:id}
        @test reg.name.str == "q"
        @test reg.size isa Token{:int}
        @test reg.size.str == "4"
        @test reg.type isa Token{:reserved}
        @test reg.type.str == "qreg"
    end

    @testset "creg" begin
        @test ast.prog[5] isa RegDecl
        reg = ast.prog[5]
        @test reg.name isa Token{:id}
        @test reg.name.str == "c1"
        @test reg.size isa Token{:int}
        @test reg.size.str == "1"
        @test reg.type isa Token{:reserved}
        @test reg.type.str == "creg"
    end

    @testset "U" begin
        @test ast.prog[7] isa UGate
        U = ast.prog[7]
        @test U.qarg isa Bit
        @test U.y isa Tuple
        @test U.z1 isa Neg
        @test U.z2 isa Token{:float64}
        @test U.qarg.name.str == "q"
        @test U.qarg.address.str == "2"
        @test U.y[2] isa Token{:reserved}
        @test U.y[2].str == "+"
        @test U.y[1] isa Tuple
        @test U.y[1][1] isa Token{:reserved}
        @test U.y[1][2] isa Token{:reserved}
        @test U.y[1][1].str == "pi"
        @test U.y[1][2].str == "/"
    end

    @testset "CX" begin
        @test ast.prog[8] isa CXGate
        cx = ast.prog[8]
        @test cx.ctrl isa Bit
        @test cx.qarg isa Bit
        @test cx.ctrl.name.str == "q"
        @test cx.qarg.name.str == "q"
        @test cx.ctrl.address.str == "1"
        @test cx.qarg.address.str == "2"
    end

    @testset "inst" begin
        @test ast.prog[9] isa Instruction
        inst = ast.prog[9]
        @test inst.name == "custom"
        @test inst.cargs[1].str == "0.3"
        @test inst.qargs[1].name.str == "q"
        @test inst.qargs[1].address.str == "3"
    end

    @testset "barrier" begin
        @test ast.prog[10] isa Barrier
        barrier = ast.prog[10]
        @test length(barrier.qargs) == 1
        @test barrier.qargs[1] isa Bit
        @test barrier.qargs[1].name.str == "q"
        @test barrier.qargs[1].address === nothing
    end

    @testset "h q[0]" begin
        @test ast.prog[11] isa Instruction
        @test ast.prog[11].name == "h"
        @test length(ast.prog[11].qargs) == 1
        @test length(ast.prog[11].cargs) == 0
    end

    @testset "measure" begin
        m = ast.prog[12]
        @test m isa Measure
        @test m.qarg isa Bit
        @test m.carg isa Bit
        @test m.qarg.name isa Token{:id}
        @test m.qarg.name.str == "q"
        @test m.carg.name isa Token{:id}
        @test m.carg.name.str == "c0"
        @test m.qarg.address isa Token{:int}
        @test m.carg.address isa Token{:int}
        @test m.qarg.address.str == "0"
        @test m.carg.address.str == "0"
    end

    @testset "ifstmt" begin
        ifstmt = ast.prog[13]
        @test ifstmt isa IfStmt
        @test ifstmt.left isa Token{:id}
        @test ifstmt.left.str == "c0"
        @test ifstmt.right isa Token{:int}
        @test ifstmt.right.str == "1"
        @test ifstmt.body isa Instruction
        @test ifstmt.body.name == "z"
        @test length(ifstmt.body.qargs) == 1
        @test length(ifstmt.body.cargs) == 0
        @test ifstmt.body.qargs[1].name.str == "q"
        @test ifstmt.body.qargs[1].address.str == "2"
    end

    @testset "u3" begin
        inst = ast.prog[14]
        @test inst isa Instruction
        @test inst.name == "u3"
        @test length(inst.cargs) == 3
        @test inst.cargs[1][1].str == "0.1"
        @test inst.cargs[1][2].str == "+"
        @test inst.cargs[1][3].str == "0.2"
        @test inst.cargs[2].str == "0.2"
        @test inst.cargs[3].str == "0.3"
    end

end

@testset "is ast similar" begin
    qasm1 = """OPENQASM 2.0;
    include "qelib1.inc";
    gate custom(lambda) a {
        u1(sin(lambda) + 1) a;
    }
    // comment
    gate g a
    {
        U(0,0,0) a;
    }

    qreg q[4];
    creg c1[1];
    creg c2[1];
    U(-1.0, pi/2+3, 3.0) q[2];
    CX q[1], q[2];
    custom(0.3) q[3];
    barrier q;
    h q[0];
    measure q[0] -> c0[0];
    if(c0==1) z q[2];
    u3(0.1 + 0.2, 0.2, 0.3) q[0];
    """

    qasm2 = """OPENQASM 2.0;
    include "qelib1.inc";
    gate custom(lambda) a {
        u1(sin(lambda) + 1) a;
    }
    // comment
    gate g a
    {
        U(0,0,0) a;
    }

    qreg q[4];
    creg c1[1];
    creg c2[1];
    U(-1.0, pi/2+3, 3.0) q[2];
    CX q[1], q[2];
    custom(0.3) q[3];
    barrier q;
    h q[0];
    measure q[0] -> c0[0];
    if(c0==1) z q[2];
    """

    ast1 = OpenQASM.parse(qasm1)
    ast2 = OpenQASM.parse(qasm2)
    println(ast1)
    println(ast2)

    @test !(ast1 ≈ ast2)
    @test ast1 ≈ ast1
    @test ast2 ≈ ast2

    s = """
    gate test_gate(theta, phi) qreg_2, qreg_3, qreg_1 {
    x qreg_1;
    z qreg_2;
    rx(-(sin(theta))+2.0) qreg_3;
    rx(sin(theta)+tan(phi)) qreg_3;
    ry(cos(phi)-ln(phi)) qreg_3;
    ry(cos(phi)*sqrt(phi)) qreg_3;
    CX qreg_1, qreg_3;
    }
    """
    ast3 = OpenQASM.parse_gate(s)
    println(ast3)
    @test ast3 ≈ ast3
end
