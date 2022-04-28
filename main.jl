include("quarto.jl")


winnercount = zeros(3)

env = QuartoEnv()

for i ∈ 1:1000
    reset!(env)
    winner = run(env, RandomPlayer(), RandomPlayer(), false, false)
    winnercount[winner] += 1
end

println(winnercount)
