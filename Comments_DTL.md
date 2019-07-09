# Code Review
 ## Some Good Quotes to Keep In Mind
+ "No one in the brief history of computing has ever written a piece of perfect software. It's unlikely that you'll be the first." - Andy Hunt
+ “Simplicity is prerequisite for reliability.” - Edsger W. Dijkstra
+ “So much complexity in software comes from trying to make one thing do two things.” - Ryan Singer
+ “First, solve the problem. Then, write the code.” - John Johnson
+ “One man’s constant is another man’s variable.” - Alan J. Perlis
+ "Any fool can write code that a computer can understand. Good programmers write code that humans can understand. ” - Martin Fowler



# Executive Summary for the Early Version of the `malletparseDSI` Package
Here are the key topics from a reasonably involved perusal of the code on specific topics
and a very superficial exploration on other matters.
While the goal is to review Arthur's code and solve the specific problem of speeding up the
reading of the data, another important goal is the thought process about
how to go about the former goal. 

Regarding the implementation of the current approach:

## Preallocation
Regarding speed, the essential issue comes down to the age-old problem of either
+ preallocating the vectors/matrices and inserting values into the existing cells, or
+ concatenating values to a vector/matrix and so having to reallocate it each time.
The second of these leads to exponential time increases.

## Profile Code
+ Profile slow code 
  + Either C/C++ or R code
    + gperf
	+ iprof
	+ Rprof
  + Optimize based on measurements of where the slow parts actually are.

## Reuse Existing Code - in R or elsewhere
The second lesson is to 
+ use R code until you need the speed. 
  + Premature Optimization! "Root of all evil"
  + Don't go to C/C++ as the first port
    + unless you have analytic evidence you need to.
+ Compare timings.R	
+ reuse existing code within the C code for R rather than reimplementing everything from scratch
+ rely on well-tested, debugged, and widely-used code.
  + more eyes, less bugs
+ The compression (gz) could be done with connections in R. It may be slower, but is it worth it to 
  bypass existing code?
+ Portability across platforms/operating systems is a concern. Perhaps we will always run the code
  on
   a Linux box, but if we want to pass to the "client", we may want the option of running on a 
   Windows or OSX setup.
+ "One of my most productive days was throwing away 1000 lines of code." - Ken Thompson



## Small Focused Functions versus Monolithic Functions
+ Break large functions into smaller ones
  + Wherever there is a comment that says "doing some other thing....", it is a subtask and should
    have a separate function
+ Don't define functions within R functions unless there is a good reason (closures and updates)
  + Otherwise the functions can't be reused or tested independently

## R Implementations Before C/C++ Implementations
+ Write the R version first
+ See how efficient it is.
+ Profile it
+ Improve the bottlenecks
+ Decide whether one needs to implement in C/C++
+ Or can parallelize the R code
+ The R code serves as a test of correctness for the 

## R as a Computational Tool versus Calling C/C++
There isn't much value in delegating most of the code in a package
to C/C++ and just calling that from R.
This does not take advantage of the flexibility of rapid prototyping
in R  (or other dynamic languages). Ths is just a proven use of time: program
in the high-level language and descend into C/C++, etc. for smaller portions
that are a bottlneck, and ony if it is necessary.
There are many more criteria than "efficient code".
There is 
+ programmer time to get the job done
+ how often will the code be run on inputs when the job will take a long time
 and can we wait a long time for those jobs
+ who understands the code and can maintain it
+ who can modify the code to make it do something different.
  + "Always code as if the guy who ends up maintaining your code will be a violent psychopath who knows where you live" - John Woods




## Really Need the Large Data or Intelligent Sample
An important question is why does the project require dealing with such large numbers
of observations. Can't sampling give the same qualitative answer? 
What is the scope of inference, anyway?



## malletparseDSI Package
The following are some initial thoughts when perusing the code.

+ .so in the git repository.
  + Platform specific
  + timestamp messes with Make.
+ Are the Makevars hard-coded? Yes - appears so.
  + Don't do this.
  + Users set these in ~/.R/Makevars and they are picked up from $R_HOME/etc/Makeconf.

+ using int for counts in Info in rcpp_parse_topic_state
  + Could the number exceed the max integer.
  + Why not use long or at least unsigned int?

+ CamelCase the name?
+ The package is primarily C++ code.
+ no_doc_topics_createJSON is a very long function - 51 expressions in the body.
  + combines many, many preparation steps and then the creation of the RJSON.
   + The steps are identified in the comments
    + init local variables
    + compute counts of tokens
	+ compute intertopic distances
	+ compute term frequencies as columns
	+ compute the distinctiveness and saliency of the terms
	+ Order the terms for the "default" view by decreasing saliency
	+ Collect R most relevant terms for each topic/lambda combination
    + compute ares of circles
	+ round down infrequent term occurrences
  + The preparation steps should be separated into a sequence of specific functions
    + Can reuse
	+ Can test independently.
+ "R has better facilities for column-wise operations" - 
   + in what sense?
   + and is this true for the facilities being used here?
+ Why define functions locally within other functions, e.g., jensenShannon
  + jensenShannon doesn't use additional parameters via closures, so can be define outside
  + can reuse
  + can test separately
  
+ Why hard code 2 principal components?
   + It may be that you are only planning to use 2, but little cost in
    allowing the number of components be a parameter with a default value of 2.

+ quantile routine
  + Why not just call the routine in R itself?
  + If copying the code from R, need to acknowledge it explicitly
    + give reference to location in R code
	+ copyright acknowldegement
    + licensing implications

+ ¿Put the state-file.gz in the data/ directory as an RDS file so that one doesn't have to ?

### C++ code

+ "nervous about how it handles large models"

+ Why are you running on 800 million lines?
  + Why not sample?
  + Is 17 billion words really necessary for the results?
  
+ Profile the C++ code. 
  + Find the bottlenecks.

+ I suspect that you are not preallocating the terms vector and then growing that by one in each
call  to terms.push_back().  You know how long it needs to be - nterms - and can preallocate.

+ The C++ code doesn't seem to handle character encoding.  
  
+ What are the ideas you have for speeding this up?  

+ You appear to be making two passes of the file - one to count the number of lines.
+ How does terms.push_back() work in terms of allocation.
  + Given that you know the number of terms, why not preallocate it correctly.

+ Error handling when a file is not found. Just returns.  Throw an error.

+ gzstream.h
  + Is this reliable and well-tested with many people using it?
    + If not, why reinvent wheel
	+ and why not use R's connections?
	  + There are reasons, but have you timed using connections in C++?
	
  + Why not parse the binary output created by mallet? 
     + should be faster than text for long vectors of the same type.
  + or even perform the conversion by calling mallet from R (via rJava or whatever) and just converting
    in memory
	  + avoids writing to disk.



## rcpp_parse_topic_state()

+ 
```
system.time({z = rcpp_parse_topic_state("biggest_topic-state.gz", dtflag = 0)})
```
  + Well over an hour, maybe 2, maybe many, many hours - still running!
  + With preallocation
    + 10 minutes
  + All that needs to be changed is
  
```
    Rcpp::StringVector terms(info.nterms);
    Rcpp::NumericVector wf(info.nterms);
    Rcpp::StringVector docs(info.ndocs);
    Rcpp::NumericVector dc(info.ndocs);
```
versus
```
    Rcpp::StringVector terms;
    Rcpp::NumericVector wf;
    Rcpp::StringVector docs;
    Rcpp::NumericVector dc;    
```
AND
   then removing the 2 push_back() loops   which initialize the elements of the R vector.
   But we did this when we set the length when we created the vectors.
```
    if (termflag == 1)
    {
	for (int i = 0; i < info.nterms; i++)
	{
	    wf.push_back(0);
	    terms.push_back("");
	}
    }

    if (docflag == 1) 
    {
	for (int i = 0; i < info.ndocs; i++)
	{
	    dc.push_back(0);
	    docs.push_back("");
	}
    }
```
 So less code means faster!   

+ Optimization for the compiler `-O2` versus `-O0`
  gives a speed of a factor of 2.

# C++ versus C versus R

## Counting the Number of Lines in a File
Compare different approaches
+ wc -l
+ C version of wc.  
+ C++ version get_nterms()
+ See all of these in LineCount/

## Results
+ See LineCount/Results
```
     wc     wcf       c     cpp
1.00000 1.03125 1.60000 1.98750
```

## Conclusions
   + There is overhead due to C++ relative to C
   + system("wc -l", intern = TRUE) is fastest
   + Don't ignore the existing tools
     + They have been refined over many years and by many eyes.
	  + efficient
	  + fewer bugs
	  + often more features.


## R Code for topic_counts.txt   

For reading the topic_counts.txt file with 926,189 rows, we have the following comparison
of R code and the C++ code in malletparseDSI.

source("check.R", echo = TRUE)

library(malletparseDSI)
tm2 = system.time({ m2 = rcpp_parse_word_topic_counts("topic_counts.txt", 145)})
source("readTopicsMatrix.R")
tm1 = system.time({m = readTopicsM("topic_counts.txt")})

DSI machine: 
tm2
    user   system  elapsed
7660.789  157.735 7820.505
tm1
   user  system elapsed
 62.782  13.564  76.547
identical(m,m2)
[1] TRUE

R is a factor of 102 times faster.

On my OSX machine
tm2
    user   system  elapsed 
6187.062 1418.714 7629.439 
tm
   user  system elapsed  
38.877   1.491  40.706 


R is a factor of 187 times faster.


I suspect this has a lot to do with the way the C++ code does not preallocate the results.
And the approach used in the R code holds all of the data in memory. So it will become
problematic for very large input files. However, this could be done in chunks and easily
parallelized.

The moral - naive use of Rcpp makes for very slow code.
This is something I have shown in most of my courses and pointed out it applies every language.



#


# rcpp_parse_doc_topics_mallet()

```
wc -l doc_topics.txt
82833575 doc_topics.txt
```
So 83 million.

The routine starts with
```
    std::ifstream infile;
    infile.open(fpath);

    int ntopics = 0;
    std::string line;
    char delim[] = " \t"; //space and tab

    if (infile.is_open())
    {
	getline(infile, line);
	char *token = strtok (&line[0u], delim);
	{
	    while (token != NULL)
	    {
		ntopics++;
		token = strtok(NULL, delim);
	    }
	}
    }//
    ntopics = ntopics -2; //the first two columns are doc id and docname
    infile.clear();
    infile.close();
```
AFAICS, this determines the number of elements in the first line of the file.
The caller may know this, so allow them to specify this.  A value of -1 or NA means
the routine should calculate it.

Firstly, it is a separate computation, so should be in its own routine.
This would make it reusable, easier to test, and make the already long
routine rcpp_parse_doc_topics_mallet() shorter and easier to read.

Every separate task of more than one or two expressions within a routine should be its own
routine.


However, we can do this so much more easily and flexibly in R.
```
length(gregexpr("\\t", readLines(infile, n = 1))[[1]]) - 1
```
(We subtract one instead of 2 since we are counting the number of delimiters which is one less than
the number of fields.)

Or
```
length(strsplit(readLines(infile, n = 1), "\\t")[[1]]) - 2
```

Note that these approaches
1. handle unicode, 
1. can deal with different types of connections (files, gzipped files,
    pipes, etc.)
1. are short
1. are easy to understand
1. are easy to modify.

Not only can we modify the approach, e.g., a different delimiter,
but we don't have to recompile and reload the shared library.



## Two Passes versus Reallocation

As we see, preallocating the R vectors makes the code much more
efficient.
So performing two passess of the file is useful to first get the number of elements
of the vectors and matrices, followed by a second pass to process the content.
However, this extra pass is not the only way to  avoid preallocation.
An old trick is to 
+ guess/estimate the number of elements 
+ use that as the initial size
+ add code to check if we are about to exceed that number, 
+ if we are, reallocate the vector to be f (> 1) times the current length
  where f is a good guess about how many more elements we are likely to need 
+ continue
+ reset the length correctly at the end.


## How many lines to Process

I like routines such as this to take the number of lines to read
so that we can test it on the target file(s) but not process  all of it.
Again, the default value can be -1 or NA to indicate all of them.



## Fuse Loops
```
	    for (int i = 0; i < ntopics; i++)
	    {
		    doctopics_vec[i] = std::stof(elem[i]);
	    }
	    sum = 0.0;
            for (int i = 0; i < ntopics; i++)
	    {
                sum = sum + doctopics_vec[i];
		}
```
can be simplified as
```
        sum = 0.0;
	    for (int i = 0; i < ntopics; i++)
	    {
		sum += (doctopics_vec[i] = std::stof(elem[i]));
	    }
```
to eliminate one loop.
While only one, there are 83 million of these.

## From Arthur

I was wondering if you had time to review my code / sit down and talk with me for a bit sometime next week. I have written a quick R package for parsing the output of MALLET (software that we are using to run topic models). The package is on bitbucket: https://bitbucket.org/digitalscholarship/malletparsedsi/src/master/. It works fine for small and medium sized files but I am nervous about how it handles large models.


For example, I estimate that it can handle 1 million lines per minute when parsing a document topics file. Currently the biggest one we have is 83 million lines, so not too bad. The next model we plan on running, however, will probably have 800 million lines. More troublesome is the topic-state file, which has one line per word in the corpus. For the next model we plan on running, there will be about 17 billion words... I have a couple ideas for speeding it up but am not sure which to pursue.


Also, I have a couple questions about my older package meant to process large text corpora https://bitbucket.org/digitalscholarship/textprocessingdsi/src.  Mainly I want to figure out a nice solution for tracking progress and to handle errors in individual processes.


Do you have time for this? Or do you think Clark might be able to help?






A large input file can be found on the datasci server at /dsl/David_Kyle_Creativeness/Newspaper_Model/output/. 145 Topics, somewhere around 83 million documents.

In that folder there is a word topic counts file (topic_counts.txt), a doc topics file (doc_topics.txt) and a topic state file (topic-state.gz).


An overview for running the code can be found at http://ds.lib.ucdavis.edu/docs/malletparseDSI/articles/malletparseDSI.html.


For this case parsing the word topic counts file would look like:

topic_terms = rcpp_parse_word_topic_counts("/dsl/David_Kyle_Creativeness/Newspaper_Model/output/topic_counts.txt", 145) 


parsing doc topics:

dtinfo = rcpp_parse_doc_topics("/dsl/David_Kyle_Creativeness/Newspaper_Model/output/doc_topics.txt", topn=200)


parsing statefile:

stateinfo = rcpp_parse_topic_state("/dsl/David_Kyle_Creativeness/Newspaper_Model/output/topic-state.gz", dtflag=0 (important to set to 0!)) 


Let me know if you want something than this.





https://made4dev.com/blogs/posts/35-inspiring-programming-quotes-with-visuals-for-developers-and-coders
