foo = A -> .+ 1
addprocs(2);
#=
A = rand(2,2)
remotecall_fetch(() -> foo(A),2)
A = rand(2,2)
remotecall_fetch(() -> foo(A),3)
@spawnat 1 whos();
@spawnat 2 whos();
@spawnat 3 whos();

x = remotecall_fetch(()-> A, 2)
y = remotecall_fetch(()-> A, 3)
=#
println(A);
println("///////////////////")
remotecall_fetch(()-> A,2)
B = rand(2,2)
let B = B
    remotecall_fetch(()-> B,2)
end;
@spawnat 2 whos();

nheads = @parallel (+) for i = 1:200000000
    Int(rand(Bool))
end
f = (() -> + 1)
a = zeros(100000)
@parallel for i = 1:100000
    a[i] = i
end
a = randn(1000)
@parallel (+) for i = 1:100000
    f(a[rand(1:end)])
end

a[rand(1:end)]
M = Matrix{Float64}[rand(1000,1000) for i = 1:10];

pmap(svd,M);

function producer(c::Channel)
           put!(c, "start")
           for n=1:4
               put!(c, 2n)
           end
           put!(c, "stop")
       end;

taskref = Ref{Task}()

@everywhere function foo(A::Array{Float64,2})
    return A.+1
end

#=
a = zeros(4)

@ parallel for i = 1:4
    a[i]=i
end
addprocs(2)
A = rand(10,10)
b = remotecall_fetch(()->foo(A), 2) # worker 2
A = rand(10,10)
c = remotecall_fetch(()->foo(A), 3) # worker 3
A = nothing

=#
M = Matrix{Float64}[rand(800,800),rand(600,600),rand(800,800), rand(600,600)];
@btime pmap(svd,M); #different behavior when on process calculates all big Arrays
# Given Channels c1 and c2,
c1 = Channel(32)
c2 = Channel(32)

# and a function `foo()` which reads items from from c1, processes the item read
# and writes a result to c2,
function foo2()
    while true
        data = take!(c1)
        [...]               # process data
        put!(c2, result)    # write out result
    end
end

# we can schedule `n` instances of `foo()` to be active concurrently.
for _ in 1:n
    @schedule foo()
end
##### test.jl
for arg in ARGS
    println(arg)
    print(1)
end
print(1)

resultat = begin
              x = 5;
              y = 7;
              x+y
            end
 println(resultat)

 println("\t\tProgramm zur Berechnung der Quadratwurzel\n\n")
print("Zahl? ") # einfaches prompt
eingabe = parse(Float64, readline()) # einlesen über readline()

try
    println("Das Resultat ist $(sqrt(eingabe))") # berechnung + ausgabe
catch e
    println("Negative Eingabe: Sie erhalten ein komplexes Ergebnis!") # warnhinweis
    println("Resultat ist $(sqrt(complex(eingabe)))") # berechnung + ausgabe
end
@everywhere function foo(x)
    myid()
end

workers()

testPmapWithBatchSize1() = pmap(foo, 1:100, batch_size = 1)

testPmapWithBatchSize10() = pmap(foo, 1:100, batch_size = 10)

a = pmap(foo, 1:100, batch_size = 33)

a == z

z == x

x == y
