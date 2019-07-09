library(malletparseDSI)
f = "smaller_topic_counts.txt"
f = "small_topic_counts.txt"
f = "topic_counts.txt"
tm2 = system.time({ m2 = rcpp_parse_word_topic_counts(f, 145)})


source("readTopicsMatrix.R")
tm1 = system.time({m = readTopicsM(f)})
#   user  system elapsed
# 57.755   9.452  67.204



# With preallocation in the C++ code
#tm1
#   user  system elapsed 
# 26.795   0.767  27.582 
#[54:26] 13> tm2
#   user  system elapsed 
#  2.743   0.252   2.996 
