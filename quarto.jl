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
    availablepieces::BitArray{1}
end


function QuartoEnv()
    board = Matrix{UInt8}(undef, 4, 4)
    fill!(board, 0x00)
    pieces = BitArray(undef, 16)
    fill!(pieces, true)
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

function iswin(line::Vector{UInt8})
    cond1 = (line[1] & line[2] & line[3] & line[4]) > 0xf0
    cond2 = (!line[1] & !line[2] & !line[3] & !line[4]) > 0xf0
    return cond1 || cond2
end

function iswin(env::QuartoEnv)
    b = env.board
    return iswin(b[:,1]) ||
           iswin(b[:,2]) ||
           iswin(b[:,3]) ||
           iswin(b[:,4]) ||
           iswin(b[1,:]) ||
           iswin(b[2,:]) ||
           iswin(b[3,:]) ||
           iswin(b[4,:]) ||
           iswin([b[1,1], b[2,2], b[3,3], b[4,4]]) ||
           iswin([b[1,4], b[2,3], b[3,2], b[4,1]])
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
    for j ∈ 1: 4
        for i ∈ 1: 4
            if (0x0f < env.board[i, j])
                print(symbollut[(0x0f & env.board[i, j]) + 0x01], ' ')
            else
                print(". ")
            end
        end
        println()
    end
    println()
end

function showavailablepieces(env)
    for i ∈ 1:length(env.availablepieces)
        env.availablepieces[i] && println("\t$(i): ", symbollut[i])
    end
end

function getavailablepieces(env)
    return findall(env.availablepieces)
end

function getavailablepositions(env)
    return findall(x -> (x & 0xf0) == 0x00, env.board)
end

function getaction(env::QuartoEnv)
    print("Player '$(env.player)' please enter the piece number (1-16): ")
    p = parse(UInt8, readline())
    
    while ((0x01 > p) || (0x10 < p) || (false == env.availablepieces[p]))
        println("Please select one available piece. The available pieces are:")
        showavailablepieces(env)
        print("Player '$(env.player)' please enter the piece number: ")
        p = parse(UInt8, readline())
    end
    
    r = 0
    c = 0
    
    while true
        print("Player '$(env.player)' please enter the row number (1-4): ")
        r = parse(UInt8, readline())

        while ((r > 4) || (r < 1))
            print("Invalid row. Please select one row position from 1 to 4: ")
            r = parse(UInt8, readline())
        end
        
        print("Player '$(env.player)' please enter the column number (1-4): ")    
        c = parse(UInt8, readline())
        
        while ((c > 4) || (c < 1))
            print("Invalid row. Please select one column position from 1 to 4: ")
            c = parse(UInt8, readline())
        end
        
        if (0x0f < env.board[c, r])
            println("Invalid move, there is already a piece in ($c, $r).")
        else
            break
        end
    end 
            
    return (c, r, p)
end

function setaction(env, a::Tuple{UInt8, UInt8, UInt8})
    copyenv = copy(env)
    copyenv.availablepieces[a[3]] = false
    copyenv.board[a[1], a[2]] = (0xf0 | (a[3] - 0x01))
    copyenv.player = !copyenv.player
    return copyenv
end

function setaction!(env::QuartoEnv, a::Tuple{UInt8, UInt8, UInt8})
    env.board[a[1], a[2]] = (0xf0 | (a[3] - 0x01))
    env.availablepieces[a[3]] = false
    println("Player '$(env.player)' placed piece $(a[3]) in ($(a[2]), $(a[1])) position.")
    env.player = !env.player
end

function performrandommove(env)
    action = rand(getavailablepieces(env))
    position = rand(getavailablepositions(env))
    setaction!(env, (UInt8(position[1]), UInt8(position[2]), UInt8(action)))
end

function performwinningmmove(env)
    for a ∈ getavailablepieces(env)
        for p ∈ getavailablepositions(env)
            copyenv = setaction(env, (UInt8(p[1]), UInt8(p[2]), UInt8(a)))
            if iswin(copyenv)
                setaction!(env, (UInt8(p[1]), UInt8(p[2]), UInt8(a)))
                return
            end
        end
    end
    performrandommove(env)
end


env = QuartoEnv()

render(env)

while !(isdraw(env) || iswin(env))
    if env.player
        a = getaction(env)
        setaction!(env, a)
    else
        performrandommove(env)
    end
    render(env)
end

if isdraw(env)
    println("It's a draw!")
else
    println("Player '$(!env.player)' won the game!")
end
