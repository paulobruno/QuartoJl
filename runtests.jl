include("quarto.jl")

using Test


@testset "RandomPlayer" begin
    env = QuartoEnv()
    reset!(env); @test 1 ≤ run(env, RandomPlayer(), RandomPlayer()) ≤ 3
    reset!(env); @test 1 ≤ run(env, RandomPlayer(), WinningMovePlayer()) ≤ 3
    reset!(env); @test 1 ≤ run(env, RandomPlayer(), MiniMaxPlayer(1)) ≤ 3
    reset!(env); @test 1 ≤ run(env, RandomPlayer(), MiniMaxPlayer(2)) ≤ 3
    reset!(env); @test 1 ≤ run(env, RandomPlayer(), MiniMaxPlayer(3)) ≤ 3
end

@testset "WinningMovePlayer" begin
    env = QuartoEnv()
    reset!(env); @test 1 ≤ run(env, WinningMovePlayer(), RandomPlayer()) ≤ 3
    reset!(env); @test 1 ≤ run(env, WinningMovePlayer(), WinningMovePlayer()) ≤ 3
    reset!(env); @test 1 ≤ run(env, WinningMovePlayer(), MiniMaxPlayer(1)) ≤ 3
    reset!(env); @test 1 ≤ run(env, WinningMovePlayer(), MiniMaxPlayer(2)) ≤ 3
    reset!(env); @test 1 ≤ run(env, WinningMovePlayer(), MiniMaxPlayer(3)) ≤ 3
end

@testset "MiniMaxPlayer(1)" begin
    env = QuartoEnv()
    reset!(env); @test 1 ≤ run(env, MiniMaxPlayer(1), RandomPlayer()) ≤ 3
    reset!(env); @test 1 ≤ run(env, MiniMaxPlayer(1), WinningMovePlayer()) ≤ 3
    reset!(env); @test 1 ≤ run(env, MiniMaxPlayer(1), MiniMaxPlayer(1)) ≤ 3
    reset!(env); @test 1 ≤ run(env, MiniMaxPlayer(1), MiniMaxPlayer(2)) ≤ 3
    reset!(env); @test 1 ≤ run(env, MiniMaxPlayer(1), MiniMaxPlayer(3)) ≤ 3
end

@testset "MiniMaxPlayer(2)" begin
    env = QuartoEnv()
    reset!(env); @test 1 ≤ run(env, MiniMaxPlayer(2), RandomPlayer()) ≤ 3
    reset!(env); @test 1 ≤ run(env, MiniMaxPlayer(2), WinningMovePlayer()) ≤ 3
    reset!(env); @test 1 ≤ run(env, MiniMaxPlayer(2), MiniMaxPlayer(1)) ≤ 3
    reset!(env); @test 1 ≤ run(env, MiniMaxPlayer(2), MiniMaxPlayer(2)) ≤ 3
    reset!(env); @test 1 ≤ run(env, MiniMaxPlayer(2), MiniMaxPlayer(3)) ≤ 3
end

# Tests with multiple MiniMaxPlayers with levels ≥ 3 may last for several minutes,
#  therefore I am not adding them here
