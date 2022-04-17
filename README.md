# QuartoJl
Julia implementation of the board game [Quarto](https://en.wikipedia.org/wiki/Quarto_(board_game)).

## Piece properties
**Color**: red or blue.  
**Orientation**: vertical or horizontal.  
**Arrows**: with or without arrows.  
**Quantity**: one or two lines.

## Play a game against random opponent
```
include("quarto.jl")

env = QuartoEnv()

run(env, 'h', 'r', true, true)
```

## Available opponents
- `'h'` - Human player
- `'r'` - Random opponent: performs a random legal move
- `'w'` - Winning move opponent: if there is an immediate win, it performs the winning move, else it will perform a random move.
