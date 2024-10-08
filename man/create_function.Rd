% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tool-function.R
\name{create_function}
\alias{create_function}
\title{Function generate text that will be parsed into R code}
\usage{
create_function(lib, tool)
}
\arguments{
\item{lib}{A character, name of SAGA-GIS library.}

\item{tool}{A character, name of SAGA-GIS tool.}
}
\value{
A character, text that is to be parsed into a function definition.
}
\description{
Internal variable `args` is derived by capturing the names and values of the
calling function. The interval `senv` variable is the SAGA-GIS library
settings (generated by `saga_env`) and comes from the environment of when the
dynamic function was generated.
}
\keyword{internal}
