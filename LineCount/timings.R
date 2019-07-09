file = "topic_counts.txt"

B = 30
tm.wc = system.time(ans.wc <- replicate(B, system(paste0("wc -l ", file), intern = TRUE)))
tm.wcf = system.time(ans.wcf <- replicate(B, as.integer(gsub(" .*", "", system(paste0("wc -l ", file), intern = TRUE)))))

dyn.load("lc.so")
tm.c = system.time(ans.c <- replicate(B,  .Call("R_get_nterms", file)))
dyn.load("cpp.so")
tm.cc = system.time(ans.cc <- replicate(B, .Call("R_get_nterms_cpp", file)))

tms = list(wc = tm.wc, wcf = tm.wcf, c = tm.c, cpp = tm.cc)
e = sapply(tms, `[`, "elapsed")

names(e) = gsub(".elapsed", "", names(e))
e/min(e)

#       wc      wcf        c      cpp 
# 1.022527 1.000000 1.948090 5.802155 

# Very curious why wcf which does more than wc is consistently faster.
