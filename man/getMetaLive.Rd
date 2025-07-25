% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getMeta.R
\name{getMetaLive}
\alias{getMetaLive}
\title{Obtain site meta data from NOAA server}
\usage{
getMetaLive(...)
}
\arguments{
\item{...}{Currently unused.}
}
\value{
a \link[tibble:tibble-package]{tibble}
}
\description{
Download all NOAA meta data, allowing for re-use and direct querying.
}
\examples{
\dontrun{
meta <- getMetaLive()
head(meta)
}
}
\seealso{
Other NOAA ISD functions: 
\code{\link{getMeta}()},
\code{\link{importNOAA}()},
\code{\link{importNOAAlite}()}
}
\concept{NOAA ISD functions}
