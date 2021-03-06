% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{make_dnam_se}
\alias{make_dnam_se}
\title{Transform DNA methylation array into a summarized Experiment object}
\usage{
make_dnam_se(
  dnam,
  genome = c("hg38", "hg19"),
  arrayType = c("450k", "EPIC"),
  betaToM = FALSE,
  verbose = FALSE
)
}
\arguments{
\item{dnam}{DNA methylation matrix with beta-values or m-values as data,
row as cpgs "cg07946458" or regions ("chr1:232:245") and column as samples}

\item{genome}{Human genome of reference: hg38 or hg19}

\item{arrayType}{DNA methylation array type (450k or EPIC)}

\item{betaToM}{indicates if converting methylation beta values to mvalues}

\item{verbose}{A logical argument indicating if
messages output should be provided.}
}
\value{
A summarized Experiment object with DNA methylation probes mapped to
genomic regions
}
\description{
Transform DNA methylation array into a summarized Experiment object
}
\examples{
library(dplyr)
dnam <- runif(20, min = 0,max = 1) \%>\% sort \%>\%
  matrix(ncol = 1) \%>\%  t
rownames(dnam) <- c("chr3:203727581-203728580")
colnames(dnam) <- paste0("Samples",1:20)
 se <- make_dnam_se(dnam)

}
