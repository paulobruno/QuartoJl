using LinearAlgebra

import REPL
using REPL.TerminalMenus


symbollut = [
    "\e[31m↔\u001b[0m", 
    "\e[31m—\u001b[0m",
    "\e[31m↕\u001b[0m",
    "\e[31m|\u001b[0m",
    "\e[31m⇆\u001b[0m",
    "\e[31m=\u001b[0m",
    "\e[31m⇅\u001b[0m",
    "\e[31m‖\u001b[0m",
    "\e[36m↔\u001b[0m",
    "\e[36m—\u001b[0m",
    "\e[36m↕\u001b[0m",
    "\e[36m|\u001b[0m",
    "\e[36m⇆\u001b[0m",
    "\e[36m=\u001b[0m",
    "\e[36m⇅\u001b[0m",
    "\e[36m‖\u001b[0m"
]


Base.:!(b::UInt8) = ~(b ⊻ 0xf0)


mutable struct QuartoEnv
    board::Matrix{UInt8}
    availablepieces::Vector{UInt8}
    availablepositions::Vector{UInt8}
    numpieces::UInt8
    numpositions::UInt8
    player::Bool
end


function QuartoEnv()
    board = fill(0x00, 4, 4)
    pieces = collect(UInt8, 1:16)
    positions = collect(UInt8, 1:16)
    QuartoEnv(board, pieces, positions, 0x10, 0x10, true)
end


function copy(env::QuartoEnv)
    return QuartoEnv(Base.copy(env.board), 
                     Base.copy(env.availablepieces),
                     Base.copy(env.availablepositions),
                     Base.copy(env.numpieces),
                     Base.copy(env.numpositions),
                     Base.copy(env.player))
end

function reset!(env::QuartoEnv)
    fill!(env.board, 0x00)
    env.availablepieces = collect(UInt8, 1:16)
    env.availablepositions = collect(UInt8, 1:16)
    env.numpieces = 0x10
    env.numpositions = 0x10
    env.player = true
end

function iswin(env::QuartoEnv)
    b = env.board
    return ((b[1,1] & b[2,1] & b[3,1] & b[4,1]) > 0xf0) ||
        ((b[1,2] & b[2,2] & b[3,2] & b[4,2]) > 0xf0) ||
        ((b[1,3] & b[2,3] & b[3,3] & b[4,3]) > 0xf0) ||
        ((b[1,4] & b[2,4] & b[3,4] & b[4,4]) > 0xf0) ||
        ((b[1,1] & b[1,2] & b[1,3] & b[1,4]) > 0xf0) ||
        ((b[2,1] & b[2,2] & b[2,3] & b[2,4]) > 0xf0) ||
        ((b[3,1] & b[3,2] & b[3,3] & b[3,4]) > 0xf0) ||
        ((b[4,1] & b[4,2] & b[4,3] & b[4,4]) > 0xf0) ||
        ((b[1,1] & b[2,2] & b[3,3] & b[4,4]) > 0xf0) ||
        ((b[1,4] & b[2,3] & b[3,2] & b[4,1]) > 0xf0) ||
        ((!b[1,1] & !b[2,1] & !b[3,1] & !b[4,1]) > 0xf0) ||
        ((!b[1,2] & !b[2,2] & !b[3,2] & !b[4,2]) > 0xf0) ||
        ((!b[1,3] & !b[2,3] & !b[3,3] & !b[4,3]) > 0xf0) ||
        ((!b[1,4] & !b[2,4] & !b[3,4] & !b[4,4]) > 0xf0) ||
        ((!b[1,1] & !b[1,2] & !b[1,3] & !b[1,4]) > 0xf0) ||
        ((!b[2,1] & !b[2,2] & !b[2,3] & !b[2,4]) > 0xf0) ||
        ((!b[3,1] & !b[3,2] & !b[3,3] & !b[3,4]) > 0xf0) ||
        ((!b[4,1] & !b[4,2] & !b[4,3] & !b[4,4]) > 0xf0) ||
        ((!b[1,1] & !b[2,2] & !b[3,3] & !b[4,4]) > 0xf0) ||
        ((!b[1,4] & !b[2,3] & !b[3,2] & !b[4,1]) > 0xf0)
end

function isdraw(env::QuartoEnv)
    b = env.board
    a = (b[1,1] & b[2,1] & b[3,1] & b[4,1] &
        b[1,2] & b[2,2] & b[3,2] & b[4,2] &
        b[1,3] & b[2,3] & b[3,3] & b[4,3] &
        b[1,4] & b[2,4] & b[3,4] & b[4,4])

    return (a < 0xf0) ? false : !iswin(env)
end

function render(env::QuartoEnv)
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

function showavailablepieces(env::QuartoEnv)
    for i ∈ 1:length(env.availablepieces)
        env.availablepieces[i] && println("\t$(i): ", symbollut[i])
    end
end

function getavailablepieces(env::QuartoEnv)
    return env.availablepieces[0x01:env.numpieces]
end

function getavailablepositions(env::QuartoEnv)
    return env.availablepositions[0x01:env.numpositions]
end

function getaction(env::QuartoEnv)
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
    
    return (col-0x01) * 0x04 + row
end

function setaction(env::QuartoEnv, positionidx::UInt8, pieceidx::UInt8)
    copyenv = copy(env)
    
    position = copyenv.availablepositions[positionidx]
    copyenv.availablepositions[positionidx] = copyenv.availablepositions[copyenv.numpositions]
    copyenv.numpositions = copyenv.numpositions - 1

    row = mod(position-1, 4) + 1
    col = div(position-1, 4) + 1

    piece = copyenv.availablepieces[pieceidx]
    copyenv.availablepieces[pieceidx] = copyenv.availablepieces[copyenv.numpieces]
    copyenv.numpieces = copyenv.numpieces - 1

    copyenv.board[col, row] = (0xf0 | (piece - 0x01))

    return copyenv
end

function setaction!(env::QuartoEnv, positionidx::UInt8, pieceidx::UInt8, log::Bool=false)
    position = env.availablepositions[positionidx]
    env.availablepositions[positionidx] = env.availablepositions[env.numpositions]
    env.numpositions = env.numpositions - 1

    row = mod(position-1, 4) + 1
    col = div(position-1, 4) + 1

    piece = env.availablepieces[pieceidx]
    env.availablepieces[pieceidx] = env.availablepieces[env.numpieces]
    env.numpieces = env.numpieces - 1

    env.board[col, row] = (0xf0 | (piece - 0x01))

    log && println("Player '$(env.player)' placed piece $(symbollut[piece]) in ($(row), $(col)) position.")
end

function minmaxpositions(env::QuartoEnv, pieceidx::UInt8, depth::Integer)
    numpositions = env.numpositions

    if (depth == 0) || (numpositions == 1)
        return zeros(Integer, numpositions)
    end

    positionvalues = Vector{Integer}(undef, numpositions)

    for i ∈ 0x01:numpositions
        copyenv = setaction(env, i, pieceidx)

        if iswin(copyenv)
            positionvalues[i] = 2 * env.player - 1
        else
            piecevalues = minmaxpieces(copyenv, depth-1)

            if env.player
                positionvalues[i] = maximum(piecevalues)
            else
                positionvalues[i] = minimum(piecevalues)
            end
        end
    end

    return positionvalues
end

function performminmaxaction(env::QuartoEnv, pieceidx::UInt8, depth::Integer, log::Bool=false)
    positionvalues = minmaxpositions(env, pieceidx, depth)

    if env.player
        bestpositions = findall(positionvalues .== maximum(positionvalues))
    else
        bestpositions = findall(positionvalues .== minimum(positionvalues))
    end

    pos = UInt8(rand(bestpositions))

    setaction!(env, pos, pieceidx, log)
end

function performrandommove(env::QuartoEnv, pieceidx::UInt8, log::Bool=false)
    idx = rand(0x01:env.numpositions)
    setaction!(env, idx, pieceidx, log)
end

function performwinningmmove(env::QuartoEnv, pieceidx::UInt8, log::Bool=false)
    for i ∈ 0x01:env.numpositions
        copyenv = setaction(env, i, pieceidx)
        if iswin(copyenv)
            setaction!(env, i, pieceidx, log)
            return
        end
    end
    performrandommove(env, pieceidx, log)
end

function performaction(player::Char, env::QuartoEnv, piece::UInt8, log::Bool=false)
    if player == 'h'
        a = getaction(env)
        setaction!(env, a, piece, log)
    elseif player == 'r'
        performrandommove(env, piece, log)
    elseif player == 'w'
        performwinningmmove(env, piece, log)
    elseif player == '4'
        performminmaxaction(env, piece, 4, log)
    elseif player == '3'
        performminmaxaction(env, piece, 3, log)
    elseif player == '2'
        performminmaxaction(env, piece, 2, log)
    elseif player == '1'
        performminmaxaction(env, piece, 1, log)
    else
        #println("Unrecognized player type '$(player)'. Options are 'h', 'r', or 'w'. Using random player.")
        performrandommove(env, log)
    end
end

function selectpiecerandom(env::QuartoEnv, log::Bool=false)
    return rand(0x01:env.numpieces)
end

function selectpiecehuman(env::QuartoEnv, log::Bool=false)
    menu = RadioMenu([symbollut[i] for i in getavailablepieces(env)], pagesize=5)
    
    choice = -1

    while (-1 == choice)
        choice = request("Player '$(env.player)' please select a piece:", menu)
    end

    return UInt8(choice)
end

function minmaxpieces(env::QuartoEnv, depth::Integer)
    numpieces = env.numpieces
    
    if (depth == 0) || (numpieces == 1)
        return zeros(Integer, numpieces)
    end

    piecevalues = Vector{Integer}(undef, numpieces)
    
    for i ∈ 0x01:numpieces
        env.player = !env.player

        positionvalues = minmaxpositions(env, i, depth)

        env.player = !env.player

        if env.player
            piecevalues[i] = minimum(positionvalues)
        else
            piecevalues[i] = maximum(positionvalues)
        end
    end

    return piecevalues
end

function selectpieceminmax(env::QuartoEnv, depth::Integer, log::Bool=false)
    piecevalues = minmaxpieces(env, depth)

    if env.player
        bestpieces = findall(piecevalues .== maximum(piecevalues))
    else
        bestpieces = findall(piecevalues .== minimum(piecevalues))
    end

    p = rand(bestpieces)

    return UInt8(p)
end

function selectpiece(env::QuartoEnv, player::Char, log::Bool=false)
    if player == 'h'
        piece = selectpiecehuman(env, log)
    elseif player == 'r'
        piece = selectpiecerandom(env, log)
    elseif player == 'w'
        piece = selectpiecerandom(env, log)
    elseif player == '4'
        piece = selectpieceminmax(env, 4, log)
    elseif player == '3'
        piece = selectpieceminmax(env, 3, log)
    elseif player == '2'
        piece = selectpieceminmax(env, 2, log)
    elseif player == '1'
        piece = selectpieceminmax(env, 1, log)
    else
        #println("Unrecognized player type '$(player)'. Options are 'h', 'r', or 'w'. Using random player.")
        performrandommove(env, log)
    end

    actualpiece = env.availablepieces[piece]
    log && println("Player '$(env.player)' selected piece $(symbollut[actualpiece]).")

    env.player = !env.player

    return piece
end

function run(env::QuartoEnv, player1::Char, player2::Char, rendergame::Bool=false, logmove::Bool=false)
    rendergame && render(env)

    while !(isdraw(env) || iswin(env))
        if env.player
            piece = selectpiece(env, player1, logmove)
            performaction(player2, env, piece, logmove)
        else
            piece = selectpiece(env, player2, logmove)
            performaction(player1, env, piece, logmove)
        end
        
        rendergame && render(env)
    end

    if isdraw(env)
        logmove && println("It's a draw!")
        return 3
    else
        logmove && println("Player '$(env.player)' won the game!")
        return env.player ? 1 : 2
    end
end
