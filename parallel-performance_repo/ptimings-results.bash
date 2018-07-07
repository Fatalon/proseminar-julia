#!/bin/bash

# rm ptimings-results.out

export JULIA_NUM_THREADS=0

outfile=ptimings-host-results.out

date >> $outfile

for w in good eigen medium bad; do

    ## only one master processor
    unset JULIA_NUM_THREADS
    julia -O3 ptimings.jl $w >> $outfile

    ## more than the master processor---workers, too
    for pt in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 23; do
	unset JULIA_NUM_THREADS

	echo "shell processes $pt"
	julia -O3 -p $pt ptimings.jl $w >> $outfile

	echo "shell threads $pt  (-p=1)"
	export JULIA_NUM_THREADS=$pt
	julia -O3 ptimings.jl $w >> $outfile
    done
done
