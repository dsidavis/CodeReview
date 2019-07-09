#include <stdio.h>
#include <stdlib.h>

long 
get_nlines(const char *file)
{
    FILE *f = fopen(file, "r");
    if(!f) {
	return(-1);
    }
    long ctr = 0;
    size_t nchars = 20000;
    char *p = malloc(nchars);
    while(getline(&p, &nchars, f) > 0) {
	ctr ++;
    }
    free(p);
    return(ctr);
}


#include <Rdefines.h>

SEXP
R_get_nterms(SEXP fpath)
{
    return(ScalarReal(get_nlines(CHAR(STRING_ELT(fpath, 0)))));
}

