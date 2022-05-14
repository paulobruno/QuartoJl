import REPL
using REPL.TerminalMenus


struct RandomPlayer end
struct HumanPlayer end
struct WinningMovePlayer end
struct MiniMaxPlayer
    depth::Integer
end

Player = Union{
    HumanPlayer, 
    RandomPlayer, 
    WinningMovePlayer, 
    MiniMaxPlayer
}


@inline red(c::Char) = string("\e[31m", c, "\u001b[0m")
@inline blue(c::Char) = string("\e[36m", c, "\u001b[0m")

const symbollut = (red('↔'),  red('—'),  red('↕'),  red('|'),  red('⇆'),  red('='),  red('⇅'),  red('‖'),
                  blue('↔'), blue('—'), blue('↕'), blue('|'), blue('⇆'), blue('='), blue('⇅'), blue('‖'))


mutable struct QuartoEnv
    board::Matrix{UInt8}
    availablepieces::Vector{UInt8}
    availablepositions::Vector{UInt8}
    numpieces::UInt8
    numpositions::UInt8
    player::Bool
end


function QuartoEnv()::QuartoEnv
    board = fill(0x00, 4, 4)
    pieces = UInt8.(1:16)
    positions = UInt8.(1:16)
    QuartoEnv(board, pieces, positions, 0x10, 0x10, true)
end

function copy(env::QuartoEnv)::QuartoEnv
    return QuartoEnv(Base.copy(env.board), 
                     Base.copy(env.availablepieces),
                     Base.copy(env.availablepositions),
                     Base.copy(env.numpieces),
                     Base.copy(env.numpositions),
                     Base.copy(env.player))
end

function reset!(env::QuartoEnv)::QuartoEnv
    fill!(env.board, 0x00)
    env.availablepieces = UInt8.(1:16)
    env.availablepositions = UInt8.(1:16)
    env.numpieces = 0x10
    env.numpositions = 0x10
    env.player = true
    return env
end


function iswin(env::QuartoEnv)::Bool
    f(p1, p2, p3, p4) = (p1 & p2 & p3 & p4 ≥ 0xf0) && ((p1 ⊻ p2) | (p2 ⊻ p3) | (p3 ⊻ p4) < 0x0f)
    b = env.board
    return f(b[1,1], b[2,1], b[3,1], b[4,1]) ||
           f(b[1,2], b[2,2], b[3,2], b[4,2]) ||
           f(b[1,3], b[2,3], b[3,3], b[4,3]) ||
           f(b[1,4], b[2,4], b[3,4], b[4,4]) ||
           f(b[1,1], b[1,2], b[1,3], b[1,4]) ||
           f(b[2,1], b[2,2], b[2,3], b[2,4]) ||
           f(b[3,1], b[3,2], b[3,3], b[3,4]) ||
           f(b[4,1], b[4,2], b[4,3], b[4,4]) ||
           f(b[1,1], b[2,2], b[3,3], b[4,4]) ||
           f(b[1,4], b[2,3], b[3,2], b[4,1])
end

function isdraw(env::QuartoEnv)::Bool
    return env.numpieces == 0 && !iswin(env)
end


function render(env::QuartoEnv)::Nothing
    for j ∈ 1:4
        for i ∈ 1:4
            if (0x0f < env.board[i, j])
                print(' ', symbollut[(0x0f & env.board[i, j]) + 0x01])
            else
                print(" ·")
            end
        end
        println()
    end
    println()
end


function getavailablepieces(env::QuartoEnv)::Vector{UInt8}
    return env.availablepieces[0x01:env.numpieces]
end


function setaction(env::QuartoEnv, positionidx::UInt8, pieceidx::UInt8)::QuartoEnv
    copyenv = copy(env)
    setaction!(copyenv, positionidx, pieceidx, false)
    return copyenv
end

function setaction!(env::QuartoEnv, positionidx::UInt8, pieceidx::UInt8, log::Bool=false)::QuartoEnv
    position = env.availablepositions[positionidx]
    env.availablepositions[positionidx] = env.availablepositions[env.numpositions]
    env.numpositions -= 0x01

    row = mod(position-0x01, 0x04) + 0x01
    col = div(position-0x01, 0x04) + 0x01

    piece = env.availablepieces[pieceidx]
    env.availablepieces[pieceidx] = env.availablepieces[env.numpieces]
    env.numpieces -= 0x01

    env.board[col, row] = (0xf0 | (piece - 0x01))

    log && println("Player '$(env.player)' placed piece $(symbollut[piece]) in ($(row), $(col)) position.")
    
    return env
end


function getaction(env::QuartoEnv)::UInt8
    row = 0
    col = 0
    
    while true
        print("Player '$(env.player)' please enter the row number (1-4): ")
        row = parse(UInt8, readline())

        while ((row > 4) || (row < 1))
            print("Invalid row. Please select one row position from 1 to 4: ")
            row = parse(UInt8, readline())
        end
        
        print("Player '$(env.player)' please enter the column number (1-4): ")    
        col = parse(UInt8, readline())
        
        while ((col > 4) || (col < 1))
            print("Invalid row. Please select one column position from 1 to 4: ")
            col = parse(UInt8, readline())
        end
        
        if (0x0f < env.board[col, row])
            println("Invalid move, there is already a piece in ($(row), $(col)).")
        else
            break
        end
    end

    positionvalue = (col-0x01) * 0x04 + row

    for i ∈ 0x01:env.numpositions
        if env.availablepositions[i] == positionvalue
            return i
        end
    end
end

function minimaxpositions(env::QuartoEnv, pieceidx::UInt8, depth::Integer)::Vector{Integer}
    numpositions = env.numpositions

    if (depth == 0) || (numpositions == 0x01)
        return zeros(Integer, numpositions)
    end

    positionvalues = Vector{Integer}(undef, numpositions)

    for i ∈ 0x01:numpositions
        copyenv = setaction(env, i, pieceidx)

        if iswin(copyenv)
            positionvalues[i] = 2 * env.player - 1
        else
            piecevalues = minimaxpieces(copyenv, depth-1)

            if env.player
                positionvalues[i] = maximum(piecevalues)
            else
                positionvalues[i] = minimum(piecevalues)
            end
        end
    end

    return positionvalues
end

function performminimaxaction!(env::QuartoEnv, pieceidx::UInt8, depth::Integer, log::Bool=false)::QuartoEnv
    positionvalues = minimaxpositions(env, pieceidx, depth)

    if env.player
        bestpositions = findall(positionvalues .== maximum(positionvalues))
    else
        bestpositions = findall(positionvalues .== minimum(positionvalues))
    end

    pos = UInt8(rand(bestpositions))

    setaction!(env, pos, pieceidx, log)
end

function performrandommove!(env::QuartoEnv, pieceidx::UInt8, log::Bool=false)::QuartoEnv
    idx = rand(0x01:env.numpositions)
    setaction!(env, idx, pieceidx, log)
end

function performwinningmmove!(env::QuartoEnv, pieceidx::UInt8, log::Bool=false)::QuartoEnv
    for i ∈ 0x01:env.numpositions
        copyenv = setaction(env, i, pieceidx)
        if iswin(copyenv)
            return setaction!(env, i, pieceidx, log)
        end
    end
    performrandommove!(env, pieceidx, log)
end


function performaction!(player::HumanPlayer, env::QuartoEnv, pieceidx::UInt8, log::Bool=false)::QuartoEnv
    positionidx = getaction(env)
    setaction!(env, positionidx, pieceidx, log)
end

function performaction!(player::RandomPlayer, env::QuartoEnv, pieceidx::UInt8, log::Bool=false)::QuartoEnv
    performrandommove!(env, pieceidx, log)
end

function performaction!(player::WinningMovePlayer, env::QuartoEnv, pieceidx::UInt8, log::Bool=false)::QuartoEnv
    performwinningmmove!(env, pieceidx, log)
end

function performaction!(player::MiniMaxPlayer, env::QuartoEnv, pieceidx::UInt8, log::Bool=false)::QuartoEnv
    performminimaxaction!(env, pieceidx, player.depth, log)
end


function selectpiecerandom(env::QuartoEnv)::UInt8
    return rand(0x01:env.numpieces)
end

function selectpiecehuman(env::QuartoEnv)::UInt8
    menu = RadioMenu([symbollut[i] for i ∈ getavailablepieces(env)], pagesize=5)
    
    choice = -1

    while (-1 == choice)
        choice = request("Player '$(env.player)' please select a piece:", menu)
    end

    return UInt8(choice)
end

function minimaxpieces(env::QuartoEnv, depth::Integer)::Vector{Integer}
    numpieces = env.numpieces
    
    if (depth == 0)
        return zeros(Integer, numpieces)
    end

    if (numpieces == 0x01)
        copyenv = setaction(env, env.availablepositions[1], env.availablepieces[1])
        if iswin(copyenv)
            return Integer.([-2 * env.player + 1])
        end
        return zeros(Integer, 1)
    end

    piecevalues = Vector{Integer}(undef, numpieces)
    
    for i ∈ 0x01:numpieces
        env.player = !env.player

        positionvalues = minimaxpositions(env, i, depth)

        env.player = !env.player

        if env.player
            piecevalues[i] = minimum(positionvalues)
        else
            piecevalues[i] = maximum(positionvalues)
        end
    end

    return piecevalues
end

function selectpieceminimax(env::QuartoEnv, depth::Integer)::UInt8
    piecevalues = minimaxpieces(env, depth)

    if env.player
        bestpieces = findall(piecevalues .== maximum(piecevalues))
    else
        bestpieces = findall(piecevalues .== minimum(piecevalues))
    end

    p = rand(bestpieces)

    return UInt8(p)
end


function setpiece(env::QuartoEnv, pieceidx::UInt8, log::Bool=false)::UInt8
    actualpiece = env.availablepieces[pieceidx]
    log && println("Player '$(env.player)' selected piece $(symbollut[actualpiece]).")

    env.player = !env.player

    return pieceidx
end


function selectpiece(env::QuartoEnv, player::HumanPlayer, log::Bool=false)::UInt8
    pieceidx = selectpiecehuman(env)
    return setpiece(env, pieceidx, log)
end

function selectpiece(env::QuartoEnv, player::RandomPlayer, log::Bool=false)::UInt8
    pieceidx = selectpiecerandom(env)
    return setpiece(env, pieceidx, log)
end

function selectpiece(env::QuartoEnv, player::WinningMovePlayer, log::Bool=false)::UInt8
    pieceidx = selectpiecerandom(env)
    return setpiece(env, pieceidx, log)
end

function selectpiece(env::QuartoEnv, player::MiniMaxPlayer, log::Bool=false)::UInt8
    pieceidx = selectpieceminimax(env, player.depth)
    return setpiece(env, pieceidx, log)
end


function run(env::QuartoEnv, player1::Player, player2::Player; rendergame::Bool=false, logmoves::Bool=false)::Integer
    rendergame && render(env)

    while !(isdraw(env) || iswin(env))
        if env.player
            piece = selectpiece(env, player1, logmoves)
            performaction!(player2, env, piece, logmoves)
        else
            piece = selectpiece(env, player2, logmoves)
            performaction!(player1, env, piece, logmoves)
        end
        
        rendergame && render(env)
    end

    if isdraw(env)
        logmoves && println("It's a draw!")
        return 3
    else
        logmoves && println("Player '$(env.player)' won the game!")
        return env.player ? 1 : 2
    end
end
