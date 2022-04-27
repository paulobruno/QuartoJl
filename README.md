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
- `'3'` - 3-depth minmax opponent: simulates all moves for the next three placements and selects the best one.
- `'2'` - 2-depth minmax opponent: simulates all moves for the next two placements and selects the best one.
- `'1'` - 1-depth minmax opponent: simulates all moves for the next placements and selects the best one.
