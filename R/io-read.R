#' Read a spatial vector data set that is output by saga_cmd
#'
#' @param x list, a `options` object that was created by the `create_tool`
#'   function that contains the parameters for a particular tool and its
#'   outputs.
#' @param vector_backend character for vector backend to use.
#'
#' @return an `sf` object.
#'
#' @keywords internal
read_shapes <- function(x, vector_backend) {
  if (vector_backend == "sf") {
    result <- sf::st_read(x$files, quiet = TRUE)  
  }
  
  if (vector_backend == "SpatVector") {
    suppressWarnings(result <- terra::vect(x$files))
  }
  
  if (vector_backend == "SpatVectorProxy") {
    suppressWarnings(result <- terra::vect(x$files, proxy = TRUE))
  }
  
  return(result)
}


#' Read a tabular data set that is output by saga_cmd
#'
#' @param x list, a `options` object that was created by the `create_tool`
#'   function that contains the parameters for a particular tool and its
#'   outputs.
#'
#' @return a `tibble`.
#'
#' @keywords internal
read_table <- function(x) {
  if (tools::file_ext(x$files) == "txt") {
    object <- utils::read.table(x$files, header = T, sep = "\t")
    object <- tibble::as_tibble(object)
  } else if (tools::file_ext(x$files) == "csv") {
    object <- utils::read.csv(x$files)
    object <- tibble::as_tibble(object)
  } else if (tools::file_ext(x$files) == "dbf") {
    object <- foreign::read.dbf(x$files)
    object <- tibble::as_tibble(object)
  }

  object
}


#' Read a raster data set that is output by saga_cmd
#'
#' @param x list, a `options` object that was created by the `create_tool`
#'   function that contains the parameters for a particular tool and its
#'   outputs.
#' @param backend character, either "raster", "terra" or "stars".
#'
#' @return either a `raster` or `SpatRaster` object
#'
#' @keywords internal
read_grid <- function(x, backend) {
  if (backend == "terra") {
    object <- terra::rast(x$files)
  }

  if (backend == "stars") {
    object <- stars::read_stars(x$files)
  }

  object
}


#' Read a semi-colon separated list of grids that are output by saga_cmd
#'
#' @param x list, a `options` object that was created by the `create_tool`
#'   function that contains the parameters for a particular tool and its
#'   outputs.
#' @param backend character, either "raster" or "terra"
#'
#' @return list, containing multiple `raster` or `SpatRaster` objects.
#'
#' @keywords internal
read_grid_list <- function(x, backend) {
  x$files <- strsplit(x$files, ";")[[1]]

  if (backend == "terra") {
    object <- lapply(x$files, terra::rast)
  }

  if (backend == "stars") {
    object <- lapply(x$files, stars::read_stars)
  }

  names(object) <- paste(x$alias, seq_along(x$files), sep = "_")

  # unlist if grid list but just a single output
  if (length(object) == 1) {
    object <- object[[1]]
  }

  object
}


#' Primary function to read data sets (raster, vector, tabular) that are output
#' by saga_cmd
#'
#' @param output list, a `options` object that was created by the `create_tool`
#'   function that contains the parameters for a particular tool and its
#'   outputs.
#' @param raster_backend character, either "raster" or "terra"
#' @param vector_backend character, either "sf", "SpatVector" or
#'   "SpatVectorProxy"
#' @param .intern logical, whether to load the output as an R object
#'
#' @return the loaded objects, or NULL is `.intern = FALSE`.
#'
#' @keywords internal
read_output <- function(output, raster_backend, vector_backend, .intern,
                        .all_outputs) {
  output$files <- convert_sagaext_r(output$files)

  if (.intern) {
    object <- tryCatch(expr = {
      switch(output$feature,
        "Shape" = read_shapes(output, vector_backend),
        "Table" = read_table(output),
        "Grid" = read_grid(output, raster_backend),
        "Raster" = read_grid(output, raster_backend),
        "Grid list" = read_grid_list(output, raster_backend),
        "File path" = output$files
      )
    }, error = function(e) {
      if (.all_outputs) {
        message(
          paste(
            "No geoprocessing output for", output$alias,
            ". Results may require other input parameters to be specified"
          )
        )
      }
      return(NULL)
    })
  } else {
    object <- output$files
  }

  object
}
