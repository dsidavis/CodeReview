readTopicsM =
    #
    #  for small_topic_counts.txt with 100000
    #  system.time({m = readTopicsM("small_topic_counts.txt")})
    #  system.time({m2 = rcpp_parse_word_topic_counts("small_topic_counts.txt", 145)})
    #
    #  7.7 versus 63.832 - 16 seconds of system time for m2.  
    #
function(f, ll = readLines(f), ntopics = 145)
{
    ans = matrix(0, ntopics, length(ll))
    els = strsplit(ll, "[ :]")
    rows = lapply(els, function(e) e[seq(3, by = 2, length = length(e)/2 - 1)])
    cols = rep(1:length(els), sapply(rows, length))

    values = lapply(els, function(e) e[seq(4, by = 2, length = length(e)/2 - 1)])
    values = unlist(values)
    idx = cbind(as.integer(unlist(rows)) + 1L, cols)
    ans[ idx ] <- as.numeric(values)
    #colnames
    colnames(ans) = sapply(els, `[`, 2)
    ans

}
