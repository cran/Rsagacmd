% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tool-execute.R
\name{saga_execute}
\alias{saga_execute}
\title{Function to execute SAGA-GIS commands through the command line tool}
\usage{
saga_execute(
  lib,
  tool,
  senv,
  .intern = NULL,
  .all_outputs = NULL,
  .verbose = NULL,
  ...
)
}
\arguments{
\item{lib}{A character specifying the name of SAGA-GIS library to execute.}

\item{tool}{A character specifying the name of SAGA-GIS tool to execute.}

\item{senv}{A saga environment object.}

\item{.intern}{A logical specifying whether to load the outputs from the
SAGA-GIS geoprocessing operation as an R object.}

\item{.all_outputs}{A logical to specify whether to automatically output all
results from the selected SAGA tool and load them results as R objects
(default = TRUE). If .all_outputs = FALSE then the file paths to store the
tool's results will have to be manually specified in the arguments.}

\item{.verbose}{Option to output all message during the execution of
saga_cmd. Overrides the saga environment setting.}

\item{...}{Named arguments and values for SAGA tool.}
}
\value{
output of SAGA-GIS tool loaded as an R object.
}
\description{
Intended to be used internally by each function
}
