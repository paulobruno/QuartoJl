# QuartoJl
Julia implementation of the board game Quarto

## Play a game against random opponent
```
include("quarto.jl")

env = QuartoEnv()

run(env, 'h', 'r', true, true)
```