symbollut = [
    "\e[31m←\u001b[0m", 
    "\e[31m→\u001b[0m",
    "\e[31m↑\u001b[0m",
    "\e[31m↓\u001b[0m",
    "\e[31m⇇\u001b[0m",
    "\e[31m⇉\u001b[0m",
    "\e[31m⇈\u001b[0m",
    "\e[31m⇊\u001b[0m",
    "\e[36m←\u001b[0m",
    "\e[36m→\u001b[0m",
    "\e[36m↑\u001b[0m",
    "\e[36m↓\u001b[0m",
    "\e[36m⇇\u001b[0m",
    "\e[36m⇉\u001b[0m",
    "\e[36m⇈\u001b[0m",
    "\e[36m⇊\u001b[0m"
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

function iswin(b::Matrix{UInt8})
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

function isdraw(b::Matrix{UInt8})
    # PB: to check which is faster, the for below or a & of all positions then 
    #   check if it is less than 0xf0
    for p ∈ b
        if (p < 0xf0)
            return false
        end
    end
    return true
end

function render(env::QuartoEnv)
    for j ∈ 1: 4
        for i ∈ 1: 4
            if (0x0f < env.board[i, j])
                print(symbollut[(0x0f & env.board[i, j]) + 0x01])
            else
                print('.')
            end
        end
        println()
    end
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

function setaction!(env::QuartoEnv, a::Tuple{UInt8, UInt8, UInt8})
    env.board[a[1], a[2]] = (0xf0 | (a[3] - 0x01))
    env.availablepieces[a[3]] = false
    println("You placed piece $(a[3]) in ($(a[1]), $(a[2])) position.")
    env.player = !env.player
end


env = QuartoEnv()

render(env)

while !(iswin(env.board) || isdraw(env.board))
    a = getaction(env)
    setaction!(env, a)
    render(env)
end

if iswin(env.board)
    println("Player $(!env.player) won the game!")
else
    println("It's a draw!")
end
