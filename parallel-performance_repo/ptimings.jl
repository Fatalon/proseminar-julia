using BenchmarkTools


################ user choices

const HNM= Dict( "imac17" => Vector{Float64}([ 25_109_273, 24_932_399, 1.0, 15_360_094.0  ]),
                 "ipro" => Vector{Float64}([  2.74585e7, 2.76573e7, 5.08731e6, 2.148e7 ]),
                 "paulg-omen" => Vector{Float64}([ 3.58247e7, 3.66627e7, 6.94458e6, 4.63542e7 ]) )

const PT= [ "good", "medium", "bad", "diag" ]  ## ARGS choices

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 10.0  ## for more accuracy, twice the standard time


################ basics

const NTS= get(ENV, "JULIA_NUM_THREADS", "1");  @assert( Threads.nthreads()== parse(NTS), "NThreads=$(Threads.nthreads()) is not ENV $NTS [$(parse(NTS))]" )
const NT= parse( NTS ); @assert( typeof(NT) == Int64, " wth?  it is $(typeof(NT))\n ")
const NP= nprocs()

const global hostname= lowercase(replace( replace( chomp(readstring(`hostname`)), ".local", ""), ".lan", "" ))

println("$hostname: ", Dates.now())
info("$hostname: ", Dates.now())
(NP==1) && (NT==1) && versioninfo()




################################

@everywhere function sumfun(numlen::Int64)::Float64
    xs= 0.0
    for o=1:numlen; xs+=sqrt(o+xs) ; end#for
    sqrt(xs)
end;#function##


@everywhere function diagfun(numlen::Int64)::Float64
    d= diagm( rand(1000) ) ## consumes lotsa space: 8 MB
    Float64( length(d) )
end;#function##

################################################################

function simple_loop_sum(pt::Int,fun::Function=GlobalFun)
    a= Array{Float64}(GlobalNumFunCalls)
    for i=1:GlobalNumFunCalls; a[i] = fun(GlobalFunsumterms); end#for
    sum(a)
end#function##

function threads_sum(pt::Int,fun::Function=GlobalFun)
    a=Vector{Float64}(GlobalNumFunCalls)
    Threads.@threads for i=1:GlobalNumFunCalls; a[i]= fun(GlobalFunsumterms); end#for
    sum(a)
end#function

@everywhere function newFinalize(sa::SharedArray{Float64})
	foreach(sa.refs) do r
   		@spawnat r.where finalize(fetch(r))
	end
	finalize(sa.s)
	finalize(sa)
end


function sharedarray_parallel_sum(pt::Int,fun::Function=GlobalFun)
    sa = SharedArray{Float64}(GlobalNumFunCalls)
    s= @sync @parallel for i=1:GlobalNumFunCalls; sa[i] = fun(GlobalFunsumterms); end#for
    value = sum(sa)
    newFinalize(sa)
    value
end#function

function sharedarray_mapreduce(pt::Int,fun::Function=GlobalFun)
    sa=SharedArray{Float64}(GlobalNumFunCalls)
    @parallel (+) for i=1:GlobalNumFunCalls; sa[i]= fun(GlobalFunsumterms); end#for
    value = sum(sa)
    newFinalize(sa)
    value
end#function

function pmap_sum_nb(pt::Int,fun::Function=GlobalFun)
    r = pmap( i-> fun(GlobalFunsumterms), 1:GlobalNumFunCalls )
    sum(r)
end#function

function pmap_sum_b(pt::Int,fun::Function=GlobalFun)
    r = pmap( i-> fun(GlobalFunsumterms), 1:GlobalNumFunCalls, batch_size=ceil(Int,GlobalNumFunCalls/nworkers()))
    sum(r)
end#function


################################################################################################################

function showoff(i::Int, s::String, t::BenchmarkTools.Trial)
    benchbaseline= HNM[ hostname ][ pt ]
    asmem( m::Int )::String =  (m>2^29) ? string(round(m/2^20,1),"g") : (m>2^19) ? string(round(m/2^20,1),"m") : (m>2^9) ? string(round(m/2^10,1),"k") : string(m,"b")

    println( @sprintf("| %7.7s | %-24.24s |  %2d |  %2d,%2d |  %8.2f |  %-6.6s |", PT[pt], s, NP+NT, NP, NT, median(t.times)/benchbaseline, asmem(t.memory) ) )
    info( @sprintf("| %7.7s | %-24.24s |  %2d |  %2d,%2d |  %8.2f |  %-6.6s |", PT[pt], s, NP+NT, NP, NT, median(t.times)/benchbaseline, asmem(t.memory) ) )
    open("ptimings-$hostname-results.csv", "a") do ftr;
        nt= (NT>0)?(NT-1):0  ## actually, this compensates for the NP.  1P 2T = 2.  1P 3T = 3.  2P 0T = 2
        println(ftr, join( [ PT[pt], i, s, NP+nt, NP, NT, round(median(t.times)/benchbaseline,2), asmem(t.memory) ], " , "));
    end#do
    round(median(t.times)/benchbaseline,2)
end#function##


################################################################

## fill in the parameters for your computer

if (!( hostname in keys(HNM) ))
    info("Creating Baseline for Host $hostname first")

    HNM[ hostname ] = [ 1.0, 1.0, 1.0, 1.0 ]

    results= Vector{Float64}(0)
    global pt
    for pt=1:4
        global GlobalFun= (pt==4) ? diagfun : sumfun
        global GlobalNumFunCalls= 2^( (pt==1) ? 4 : (pt==2) ? 12 : (pt==3) ? 15 : 5)   ## this is the global number of calls to the function.
        global GlobalFunsumterms= 2^( (pt==1) ? 18 : (pt==2) ? 10 : (pt==3) ? 3 : 0)  ## this is a parameter to change how long each function call takes
        t= @benchmark simple_loop_sum( $pt )
        v= showoff( 0, "benchmark baseline", t)
        push!(results, v)
    end
    info("\n\n\nPlease edit the top of ptimings for the equivalent of\n\n\tHNM[$hostname]=$results\n\nto reflect your computer's baseline.  Then rerun this program (e.g., julia -O3 -p5 ptimings.jl).\n\n")
    exit(0)
end#if


## now parse arguments

@assert( (length(ARGS)>0), "Usage: ptimings.jl [good | medium | bad | diag]" )
const verbose= ( length(ARGS)>=2 );  (verbose) && info("VERBOSE BRIEF MODE")

@assert( ARGS[1] in PT, "Usage: ptimings.jl one of $PT, not $(ARGS[1])" )
const global pt= findfirst( PT, ARGS[1] );
const global GlobalFun= (pt==4) ? diagfun : sumfun
const GlobalNumFunCalls= 2^( (pt==1) ? 4 : (pt==2) ? 12 : (pt==3) ? 15 : 5)   ## this is the global number of calls to the function.
const GlobalFunsumterms= 2^( (pt==1) ? 18 : (pt==2) ? 10 : (pt==3) ? 3 : 0)  ## this is a parameter to change how long each function call takes


################

info("$hostname: Number of Processors: $NP.  Number of Threads: $NT.  Program $(PT[pt]) ($pt=$(Threads.nthreads()))")
println("\n$hostname: Number of Processors: $NP.  Number of Threads: $NT.  Type $(PT[pt]) ($pt)")

if ((NT>1) && (NP==1))

    if (verbose); info( threads_sum( pt ) ); exit(0); end#if

    t=@benchmark threads_sum( pt );  showoff(2, "threads_sum", t)  ## print("threads_sum $NP $NT:\t");

else

    if (verbose)
        info( simple_loop_sum( pt ) )
        info( sharedarray_parallel_sum( pt ) )
        info( sharedarray_mapreduce( pt ) )
        info( pmap_sum_nb( pt ) )
        info( pmap_sum_b( pt ) )
        exit(0)
    end#if

    t=@benchmark simple_loop_sum( pt );  showoff( 1, "simple loop", t)
    t=@benchmark sharedarray_parallel_sum( pt );  showoff( 3, "parallel", t)
    t=@benchmark sharedarray_mapreduce( pt );  showoff( 4, "mapreduce", t)
    t=@benchmark pmap_sum_nb( pt );  showoff( 5, "pmapsum1", t)
    t=@benchmark pmap_sum_b( pt );  showoff( 6, "pmapsum2", t)

end#if

println()
