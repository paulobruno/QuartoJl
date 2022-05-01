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

run(env, HumanPlayer(), RandomPlayer(), rendergame=true, logmoves=true)
```

## Available opponents
- `HumanPlayer()` - Play against other human player
- `RandomPlayer()` - Random opponent: performs a random legal move
- `WinningMovePlayer()` - Winning move opponent: if there is an immediate win, it performs the winning move or else it will perform a random move.
- `MiniMaxPlayer(n)` - n-depth [minimax](https://en.wikipedia.org/wiki/Minimax#Minimax_algorithm_with_alternate_moves) opponent: simulates all moves for the next 'n' placements and selects the best one.
