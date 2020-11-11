# OpenQASM

[![tests](https://github.com/QuantumBFS/OpenQASM.jl/workflows/Run%20tests/badge.svg)](https://github.com/QuantumBFS/OpenQASM.jl/actions)

Tools for parsing OpenQASM.

## Installation

<p>
OpenQASM is a &nbsp;
    <a href="https://julialang.org">
        <img src="https://raw.githubusercontent.com/JuliaLang/julia-logo-graphics/master/images/julia.ico" width="16em">
        Julia Language
    </a>
    &nbsp; package. To install OpenQASM,
    please <a href="https://docs.julialang.org/en/v1/manual/getting-started/">open
    Julia's interactive session (known as REPL)</a> and press <kbd>]</kbd> key in the REPL to use the package mode, then type the following command
</p>

```julia
pkg> add OpenQASM#master
```

## Usage

This package provides a simple function `OpenQASM.parse` to parse a QASM string to
its AST according to its BNF specification described in [OpenQASM 2.0](https://github.com/Qiskit/openqasm/tree/OpenQASM2.x).

## Roadmap

- [x] support for QASM 2.0
- [ ] support for QASM 3.0

## License

OpenQASM is released under the MIT license.
