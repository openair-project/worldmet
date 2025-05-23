% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/weatherCodes.R
\docType{data}
\name{weatherCodes}
\alias{weatherCodes}
\title{Codes for weather types}
\format{
An object of class \code{tbl_df} (inherits from \code{tbl}, \code{data.frame}) with 100 rows and 2 columns.
}
\usage{
weatherCodes
}
\description{
This data frame consists of the weather description codes used in the ISD. It
is not of general use to most users.
}
\details{
\describe{
\item{pwc}{Weather code, which can be merged with the \code{pwc} column in \code{\link[=importNOAA]{importNOAA()}} datasets.}
\item{description}{Description associated with the weather codes.}
}
}
\examples{
weatherCodes
}
\keyword{datasets}
