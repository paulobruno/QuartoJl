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
    availablepieces::BitVector
end


function QuartoEnv()
    board = fill(0x00, 4, 4)
    pieces = trues(16)
    QuartoEnv(board, true, pieces)
end


function copy(env::QuartoEnv)
    return QuartoEnv(Base.copy(env.board), Base.copy(env.player), Base.copy(env.availablepieces))
end

function reset!(env::QuartoEnv)
    fill!(env.board, 0x00)
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
           iswin(view(b, diagind(b))) ||
           iswin(view(view(b, :, [4,3,2,1]), diagind(b)))
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
    return findall(x -> (x & 0xf0) == 0x00, env.board)
end

function getaction(env::QuartoEnv)
    menu = RadioMenu([symbollut[i] for i in getavailablepieces(env)], pagesize=5)
    
    choice = -1

    while (-1 == choice)
        choice = request("Player '$(env.player)' please select a piece:", menu)
    end

    piece = UInt8(getavailablepieces(env)[choice])
    
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
    copyenv.availablepieces[a[3]] = false
    copyenv.board[a[1], a[2]] = (0xf0 | (a[3] - 0x01))
    copyenv.player = !copyenv.player
    return copyenv
end

function setaction!(env::QuartoEnv, a::Tuple{UInt8, UInt8, UInt8}, log::Bool=false)
    env.board[a[1], a[2]] = (0xf0 | (a[3] - 0x01))
    env.availablepieces[a[3]] = false
    log && println("Player '$(env.player)' placed piece $(a[3]) in ($(a[2]), $(a[1])) position.")
    env.player = !env.player
end

function performrandommove(env::QuartoEnv, log::Bool=false)
    action = rand(getavailablepieces(env))
    position = rand(getavailablepositions(env))
    setaction!(env, (UInt8(position[1]), UInt8(position[2]), UInt8(action)), log)
end

function performwinningmmove(env::QuartoEnv, log::Bool=false)
    for a ∈ getavailablepieces(env)
        for p ∈ getavailablepositions(env)
            copyenv = setaction(env, (UInt8(p[1]), UInt8(p[2]), UInt8(a)))
            if iswin(copyenv)
                setaction!(env, (UInt8(p[1]), UInt8(p[2]), UInt8(a)), log)
                return
            end
        end
    end
    performrandommove(env, log)
end

function performaction(player::Char, env::QuartoEnv, log::Bool=false)
    if player == 'h'
        a = getaction(env)
        setaction!(env, a, log)
    elseif player == 'r'
        performrandommove(env, log)
    elseif player == 'w'
        performwinningmmove(env, log)
    else
        #println("Unrecognized player type '$(player)'. Options are 'h', 'r', or 'w'. Using random player.")
        performrandommove(env, log)
    end
end

function run(env::QuartoEnv, player1::Char, player2::Char, rendergame::Bool=false, logmove::Bool=false)
    rendergame && render(env)

    while !(isdraw(env) || iswin(env))
        if env.player
            performaction(player1, env, logmove)
        else
            performaction(player2, env, logmove)
        end
        rendergame && render(env)
    end

    if isdraw(env)
        logmove && println("It's a draw!")
        return 3
    else
        logmove && println("Player '$(!env.player)' won the game!")
        return env.player ? 2 : 1
    end
end
