N = 10^(1:9)
f = function(n)
{    
    x = c()
    for(i in 1:n)
        x[i] = i
    x
}


f2 = function(n)
{    
    x = integer(n)
    for(i in 1:n)
        x[i] = i
    x
}

tm1 = sapply(N, function(n)system.time(f(n)))
tm2 = sapply(N, function(n)system.time(f2(n)))

tm1[3,]/tm2[3,]


#tm1 = system.time(sapply(N, f))
#tm2 = system.time(sapply(N, f2))

# For max 1:8
#  32.728 versus 8.259 - factor of 4 

