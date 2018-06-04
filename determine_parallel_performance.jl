using BenchmarkTools, Compat, JSON

@everywhere function simple_loop_sum(sumOver::Int)
    logVector = Vector{Float64}(sumOver)
   for i=1:sumOver; logVector[i] = log1p(i); end#for
   return sum(logVector)
end#function##

@everywhere function threads_sum(sumOver::Int)
    logVector = Vector{Float64}(sumOver)
    Threads.@threads for i = 1:sumOver; logVector[i] = log1p(i); end#for
    return sum(logVector)
end#function

@everywhere function sharedarray_parallel_sum(sumOver::Int)
    logSharredArray = SharedArray{Float64}(sumOver)
    @sync @parallel for i=1:sumOver; logSharredArray[i] = log1p(i); end#for
    return sum(logSharredArray)
end#function

@everywhere function sharedarray_mapreduce(sumOver::Int)
    logSharredArray = SharedArray{Float64}(sumOver)
    @parallel (+) for i=1:sumOver; logSharredArray[i]= log1p(i); end#for
    sum(logSharredArray)
end#function

@everywhere function pmap_sum_nb(sumOver::Int)
    pMapCollection = pmap( i-> log1p(i), 1:sumOver)
    sum(pMapCollection)
end#function

@everywhere function pmap_sum_b(sumOver::Int)
    pMapCollection = pmap( i-> log1p(i), 1:sumOver, batch_size=ceil(Int,sumOver/nworkers()))
    sum(pMapCollection)
end#function


function testEquality()
    for value = 1:10
        @assert simple_loop_sum(value) == threads_sum(value) == sharedarray_parallel_sum(value) == sharedarray_mapreduce(value) == pmap_sum_b(value) == pmap_sum_nb(value)
    end#for
    return true
end#function

benchmarkPerformances = Dict{String,(Dict{String,Any})}()

function createTestResultDict(benchmarkResults::BenchmarkTools.Trial,usedFunction::Function,usedValue::Int)
    estimate::BenchmarkTools.TrialEstimate = minimum(benchmarkResults);
    performanceEntryValue = Dict{String,Any}("time" => time(estimate),"allocs" => allocs(estimate),"memory in KiB"=> (memory(estimate))/1024)
    testRunEntry::String = "$usedFunction with n = $usedValue"
    benchmarkPerformances[testRunEntry] = performanceEntryValue
end#function

function callFunctionsWith4DifferentValues()
    valuesForRun = 10.^(5:7)
    functions::Array{Function} = [simple_loop_sum, sharedarray_parallel_sum, sharedarray_mapreduce, pmap_sum_b]
    for fun in functions
        for value in valuesForRun
            run = @benchmark $fun($value)
            println("run " * "$fun" * " " * string((log10(value)-3)*25) *"%"* " completed.")
            createTestResultDict(run,fun,value);
        end#inner for
    end#outer for
end#function

function callThreadFunctionWith4DifferentValues()
    valuesForRun = 10.^(4:7)
    for value in valuesForRun
        run = @benchmark threads_sum($value)
        println("run " * "threads_sum" * " " * string((log10(value)-3)*25) *"%"* " completed.")
        createTestResultDict(run,threads_sum,value);
    end#outer for
end#function

function writeToJSON()
    stringdata = JSON.json(benchmarkPerformances)

    open("write_read.json", "w") do f
            write(f, stringdata)
         end
     end


function testWithMultipleProcessors()
    rmprocs(workers())
    @assert nworkers() == 1
    testEquality()
    procs = 2.^(0:3) #1,2,4,8
    addprocs(1) #initialize with one worker, no performance increase
    for i in procs
        println("procsToAdd: " * string(i))
        addprocs(i) #2,4,8,16,32
        println("currently running workers: " * string(nworkers()))
        callFunctionsWith4DifferentValues()
        #callThreadFunctionWith4DifferentValues()
    end#for
    writeToJSON()
end#function

# need to set JULIA_NUM_THREADS manuell on start

testWithMultipleProcessors()
