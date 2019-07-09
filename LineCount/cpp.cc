#include <iostream>
#include <sstream>
#include <fstream>

int get_nterms (std::string fpath);

#include <Rdefines.h>

extern "C"
SEXP
R_get_nterms_cpp(SEXP fpath)
{
    std::string f(CHAR(STRING_ELT(fpath, 0)));
    return(ScalarInteger(get_nterms(f)));
}

int get_nterms (std::string fpath)
{
    int nterms = 0;
    std::ifstream infile(fpath);
    if (infile.is_open())
    {
	std::string line;
	while (getline(infile, line))
	{
	    nterms++;
	}//for each line
    }//if 
    return nterms;
}//get_nterms

