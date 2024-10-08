#' Generic methods to save R in-memory objects to file to SAGA-GIS to access
#'
#' Designed to be used internally by Rsagacmd for automatically pass data to
#' SAGA-GIS for geoprocessing.
#'
#' @param x An R object.
#' @param ... Other parameters such as the temporary directory or the
#'   vector/raster format used to write spatial datasets to file.
#'
#' @return A character that specifies the file path to where the R object was
#'   saved.
#' @export
#'
#' @keywords internal
save_object <- function(x, ...) {
  UseMethod("save_object", x)
}


#' @export
#' @keywords internal
save_object.default <- function(x, ...) {
  return(x)
}


#' @export
#' @keywords internal
save_object.character <- function(x, ...) {
  return(paste(x, collapse = ";"))
}


#' @export
#' @keywords internal
save_object.sf <-
  function(x,
           temp_path = tempdir(),
           vector_format,
           ...) {
    temp <-
      tempfile(tmpdir = temp_path, fileext = vector_format)

    pkg.env$sagaTmpFiles <- append(pkg.env$sagaTmpFiles, temp)

    sf::st_write(obj = x, dsn = temp, quiet = TRUE)

    return(temp)
  }

#' @export
#' @keywords internal
save_object.SpatVector <-
  function(x,
           temp_path = tempdir(),
           vector_format,
           ...) {
    temp <-
      tempfile(tmpdir = temp_path, fileext = vector_format)
    
    pkg.env$sagaTmpFiles <- append(pkg.env$sagaTmpFiles, temp)
    
    terra::writeVector(x, filename = temp)
    
    return(temp)
  }

#' @export
#' @keywords internal
save_object.SpatVectorProxy <- function(x, ...) {
  src <- terra::sources(x)
  return(src)
}

#' @export
#' @keywords internal
save_object.SpatRaster <-
  function(x,
           temp_path = tempdir(),
           raster_format,
           ...) {
    # get data source of SpatRaster object
    source_tbl <- terra::sources(x, nlyr = TRUE, bands = TRUE)

    # check if the SpatRaster contains multiple layers
    if (any(source_tbl$nlyr > 1) | nrow(source_tbl) > 1) {
      rlang::abort(
        "SpatRaster object contains multiple layers. SAGA-GIS requires single-layer rasters as inputs"
      )
    }

    # check if SpatRaster is in-memory
    in_memory <- terra::inMemory(x)

    if (!in_memory) {
      # check if the SpatRaster represents a single layer within a multilayer file
      n_bands <- terra::nlyr(terra::rast(source_tbl$source[[1]]))
      part_of_multiband <- n_bands > 1
    } else {
      part_of_multiband <- terra::nlyr(x) > 1
    }

    # single-band raster on disk -> filename -> saga
    if (!part_of_multiband & !in_memory) {
      x <- source_tbl$source[[1]]
    } else {
      temp <- tempfile(tmpdir = temp_path, fileext = raster_format)
      temp <- convert_sagaext_r(temp)
      terra::writeRaster(x, filename = temp)
      pkg.env$sagaTmpFiles <- append(pkg.env$sagaTmpFiles, temp)
      x <- temp
    }

    return(x)
  }

#' @export
#' @keywords internal
save_object.stars <-
  function(x,
           temp_path = tempdir(),
           raster_format,
           ...) {
    if (length(x) > 1) {
      rlang::abort(
        paste(
          "`stars` object contains multiple attributes.",
          "SAGA-GIS requires single layer rasters as inputs"
        )
      )
    }

    fp <- tempfile(tmpdir = temp_path, fileext = raster_format)
    fp <- convert_sagaext_r(fp)
    stars::write_stars(x, fp)

    return(fp)
  }

#' @export
#' @keywords internal
save_object.data.frame <- function(x, temp_path = tempdir(), ...) {
  temp <- tempfile(tmpdir = temp_path, fileext = ".txt")
  pkg.env$sagaTmpFiles <- append(pkg.env$sagaTmpFiles, temp)
  utils::write.table(x = x, file = temp, sep = "\t")

  return(temp)
}

spatial_to_saga <-
  function(x,
           temp_path = tempdir(),
           vector_format) {
    temp <- tempfile(tmpdir = temp_path, fileext = vector_format)
    pkg.env$sagaTmpFiles <- append(pkg.env$sagaTmpFiles, temp)
    x <- sf::st_as_sf(x)
    sf::write_sf(x, dsn = temp, layer = 1, quiet = TRUE)

    return(temp)
  }

#' @export
#' @keywords internal
save_object.SpatialPointsDataFrame <-
  function(x,
           temp_path = tempdir(),
           vector_format,
           ...) {
    spatial_to_saga(x, temp_path, vector_format = vector_format)
  }

#' @export
#' @keywords internal
save_object.SpatialLinesDataFrame <-
  function(x,
           temp_path = tempdir(),
           vector_format,
           ...) {
    spatial_to_saga(x, temp_path, vector_format = vector_format)
  }

#' @export
#' @keywords internal
save_object.SpatialPolygonsDataFrame <-
  function(x,
           temp_path = tempdir(),
           vector_format,
           ...) {
    spatial_to_saga(x, temp_path, vector_format = vector_format)
  }

#' @export
#' @keywords internal
save_object.list <- function(x, ...) {
  lapply(x, save_object, ...)
}
