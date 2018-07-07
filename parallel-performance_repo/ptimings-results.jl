"""
    print nice markdown table output for timings-results.csv
"""

ln= readlines( open("ptimings-paulg-omen-results.csv" ) )  # change the name to reflect your host

linematches(heystack::String, needle::String, field::Int) =  contains( split( heystack, "," )[field], needle )
linematches(heystack::String, needle::Int, field::Int) =  parse( split( heystack, "," )[field] )== needle

timeval(heystack::String) = ( x=split( heystack, "," )[7]; @sprintf("%7.2f", parse(x)) )
memval(heystack::String) = ( x=split( heystack, "," )[8]; @sprintf("%7.1f", parse(x)) )

for p in ( "good", "medium", "bad", "diag" )

    println( "\n\n#### $p Parallelism\n" )
    println("|  **Cores** |  **Non-Par**  |  **Threads**  |  **Parallel**  |  **Reduce**  |  **PMap1**  |  **PMap2**  |")

    lnc= ln[ linematches.(ln, p, 1) ]
    for np=1:25
        lncnp= lnc[ linematches.(lnc, np, 4 ) ]
        (length(lncnp)==0) && continue
        print("|  ")

        print( @sprintf("%2d", np), " |  ")

        for b=1:6
            lncnpb= lncnp[ linematches.(lncnp, b, 2) ]

            print( (length(lncnpb)>0) ? timeval( lncnpb[1] ) : "       ")
            print( " |  ")

        end#for b

        println()
    end## for np

    println("\n\n")

end##for p


