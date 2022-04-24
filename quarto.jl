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
    player::Bool
    availablepositions::BitMatrix
    availablepieces::BitVector
end


function QuartoEnv()
    board = fill(0x00, 4, 4)
    positions = trues(4, 4)
    pieces = trues(16)
    QuartoEnv(board, true, positions, pieces)
end


function copy(env::QuartoEnv)
    return QuartoEnv(Base.copy(env.board), 
                     Base.copy(env.player), 
                     Base.copy(env.availablepositions),
                     Base.copy(env.availablepieces))
end

function reset!(env::QuartoEnv)
    fill!(env.board, 0x00)
    fill!(env.availablepositions, true)
    fill!(env.availablepieces, true)
    env.player = true
end

function iswin(line::SubArray{UInt8})
    cond1 = (line[1] & line[2] & line[3] & line[4]) > 0xf0
    cond2 = (!line[1] & !line[2] & !line[3] & !line[4]) > 0xf0
    return cond1 || cond2
end

function iswin(env::QuartoEnv)
    b = env.board
    return iswin(@view b[:,1]) ||
           iswin(@view b[:,2]) ||
           iswin(@view b[:,3]) ||
           iswin(@view b[:,4]) ||
           iswin(@view b[1,:]) ||
           iswin(@view b[2,:]) ||
           iswin(@view b[3,:]) ||
           iswin(@view b[4,:]) ||
           iswin(@view b[1:5:16]) ||
           iswin(@view b[4:3:13])
end

function isdraw(env::QuartoEnv)
    for p ∈ env.board
        if (p < 0xf0)
            return false
        end
    end
    return !iswin(env)
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
    return findall(env.availablepieces)
end

function getavailablepositions(env::QuartoEnv)
    return findall(env.availablepositions)
end

function getaction(env::QuartoEnv, piece::UInt8)
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
    
    return (col, row, piece)
end

function setaction(env::QuartoEnv, a::Tuple{UInt8, UInt8, UInt8})
    copyenv = copy(env)
    copyenv.availablepositions[a[1], a[2]] = false
    copyenv.availablepieces[a[3]] = false
    copyenv.board[a[1], a[2]] = (0xf0 | (a[3] - 0x01))
    copyenv.player = !copyenv.player
    return copyenv
end

function setaction!(env::QuartoEnv, a::Tuple{UInt8, UInt8, UInt8}, log::Bool=false)
    env.board[a[1], a[2]] = (0xf0 | (a[3] - 0x01))
    env.availablepositions[a[1], a[2]] = false
    env.availablepieces[a[3]] = false
    log && println("Player '$(env.player)' placed piece $(symbollut[a[3]]) in ($(a[2]), $(a[1])) position.")
end

function minmaxmove(env::QuartoEnv, depth::Integer)
    if iswin(env)
        return -2 * env.player + 1
    elseif (depth == 0)  || isdraw(env)
        return 0
    end

    for a ∈ getavailablepieces(env)
        for p ∈ getavailablepositions(env)
            copyenv = setaction(env, (UInt8(p[1]), UInt8(p[2]), UInt8(a)))
            result = minmaxmove(copyenv, depth-1)
            # prune minmax
            if env.player && result == 1
                return 1
            elseif !env.player && result == -1
                return -1
            end
        end
    end

    return 0
end

function performminmaxaction(env::QuartoEnv, depth::Integer, log::Bool=false)
    if depth == 0
        performrandommove(env, log)
    end

    outcomes = Vector{Integer}()

    for a ∈ getavailablepieces(env)
        for p ∈ getavailablepositions(env)
            copyenv = setaction(env, (UInt8(p[1]), UInt8(p[2]), UInt8(a)))
            push!(outcomes, minmaxmove(copyenv, depth-1))
        end
    end

    bestactions = Vector{Integer}()

    if env.player
        bestactions = findall(outcomes .== maximum(outcomes))
    else
        bestactions = findall(outcomes .== minimum(outcomes))
    end

    move = rand(bestactions)

    a = div(move-1, length(getavailablepositions(env))) + 1
    p = mod(move-1, length(getavailablepositions(env))) + 1

    a = getavailablepieces(env)[a]
    p = getavailablepositions(env)[p]

    setaction!(env, (UInt8(p[1]), UInt8(p[2]), UInt8(a)), log)
end

function performrandommove(env::QuartoEnv, piece::UInt8, log::Bool=false)
    position = rand(getavailablepositions(env))
    setaction!(env, (UInt8(position[1]), UInt8(position[2]), piece), log)
end

function performwinningmmove(env::QuartoEnv, piece::UInt8, log::Bool=false)
    for p ∈ getavailablepositions(env)
        copyenv = setaction(env, (UInt8(p[1]), UInt8(p[2]), piece))
        if iswin(copyenv)
            setaction!(env, (UInt8(p[1]), UInt8(p[2]), piece), log)
            return
        end
    end
    performrandommove(env, piece, log)
end

function performaction(player::Char, env::QuartoEnv, piece::UInt8, log::Bool=false)
    if player == 'h'
        a = getaction(env, piece)
        setaction!(env, a, log)
    elseif player == 'r'
        performrandommove(env, piece, log)
    elseif player == 'w'
        performwinningmmove(env, piece, log)
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
    piece = UInt8(rand(getavailablepieces(env)))
    log && println("Player '$(env.player)' selected piece $(symbollut[piece]).")
    return piece
end

function selectpiecehuman(env::QuartoEnv, log::Bool=false)
    menu = RadioMenu([symbollut[i] for i in getavailablepieces(env)], pagesize=5)
    
    choice = -1

    while (-1 == choice)
        choice = request("Player '$(env.player)' please select a piece:", menu)
    end

    piece = UInt8(getavailablepieces(env)[choice])

    log && println("Player '$(env.player)' selected piece $(symbollut[piece]).")

    return piece
end

function selectpiece(env::QuartoEnv, player::Char, log::Bool=false)
    if player == 'h'
        piece = selectpiecehuman(env, log)
    elseif player == 'r'
        piece = selectpiecerandom(env, log)
    elseif player == 'w'
        piece = selectpiecerandom(env, log)
    # elseif player == '3'
    #     performminmaxaction(env, 3, log)
    # elseif player == '2'
    #     performminmaxaction(env, 2, log)
    # elseif player == '1'
    #     performminmaxaction(env, 1, log)
    # else
    #     #println("Unrecognized player type '$(player)'. Options are 'h', 'r', or 'w'. Using random player.")
    #     performrandommove(env, log)
    end

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
