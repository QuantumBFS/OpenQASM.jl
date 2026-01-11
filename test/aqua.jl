using Test
using Aqua
using OpenQASM

@testset "Aqua quality assurance" begin
    # Test for type piracy
    @testset "Type piracy detection" begin
        # Type piracy is unavoidable in this package due to RBNF's architecture.
        # RBNF requires Base.convert methods for Token types and RBNF.crate methods
        # for standard types. These are documented in src/token_wrappers.jl.
        # The only alternative would be to modify RBNF itself.
        Aqua.test_piracies(OpenQASM; broken = true)
    end

    # Test for method ambiguities
    @testset "Method ambiguities" begin
        Aqua.test_ambiguities(OpenQASM)
    end

    # Test for undefined exports
    @testset "Undefined exports" begin
        Aqua.test_undefined_exports(OpenQASM)
    end

    # Test for unbound type parameters
    @testset "Unbound type parameters" begin
        Aqua.test_unbound_args(OpenQASM)
    end

    # Test for stale dependencies
    @testset "Stale dependencies" begin
        # Aqua v0.8 is only in test dependencies, which Aqua considers stale
        # This is expected and doesn't affect functionality
        Aqua.test_stale_deps(OpenQASM; ignore=[:Aqua])
    end

    # Test for persistent tasks
    @testset "Persistent tasks" begin
        Aqua.test_persistent_tasks(OpenQASM)
    end
end
