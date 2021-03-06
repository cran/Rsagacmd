#' Generic methods to save R in-memory objects to file to SAGA-GIS to access
#' 
#' Designed to be used internally by Rsagacmd for automatically pass data to
#' SAGA-GIS for geoprocessing.
#'
#' @param x An R object.
#' @param ... Other parameters such as the temporary directory to use for
#'   storage.
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
  x
}


#' @export
#' @keywords internal
save_object.character <- function(x, ...) {
  paste(x, collapse = ";")
}


#' @export
#' @keywords internal
save_object.sf <- function(x, ...) {
  args <- list(...)
  temp_path <- args$temp_path
  
  if (is.null(temp_path))
    temp_path <- tempdir()
  
  temp <- tempfile(tmpdir = temp_path, fileext = ".shp")
  pkg.env$sagaTmpFiles <- append(pkg.env$sagaTmpFiles, temp)
  sf::st_write(obj = x, dsn = temp, quiet = TRUE)
  
  temp
}


#' @export
#' @keywords internal
save_object.RasterLayer <- function(x, ...) {
  args <- list(...)
  temp_path <- args$temp_path
  
  if (is.null(temp_path))
    temp_path <- tempdir()
  
  # pass file name to saga if RasterLayer from single band raster
  if (raster::nbands(x) == 1 &
    raster::inMemory(x) == FALSE &
    tools::file_ext(raster::filename(x)) != "grd") {
    x <- raster::filename(x)

    # else save band as a single band temporary file and pass temp file name
  } else if (raster::nbands(x) != 1 |
    raster::inMemory(x) == TRUE |
    tools::file_ext(raster::filename(x)) == "grd") {
    
    dtype <- raster::dataType(x)
    nodataval = switch(
      dtype,
      LOG1S = 0,
      INT1S = -127,
      INT1U = 0,
      INT2S = -32767,
      INT2U = 0,
      INT4S = -99999,
      INT4U = 0,
      FLT4S = -99999,
      FLT8S = -99999
    )
    
    temp <- tempfile(tmpdir = temp_path, fileext = ".tif")
    raster::NAvalue(x) <- nodataval
    raster::writeRaster(x, filename = temp, datatype = dtype, NAflag = nodataval)
    pkg.env$sagaTmpFiles <- append(pkg.env$sagaTmpFiles, temp)
    x <- temp
  }

  x
}


#' @export
#' @keywords internal
save_object.SpatRaster <- function(x, ...) {
  args <- list(...)
  temp_path <- args$temp_path
  
  if (is.null(temp_path))
    temp_path <- tempdir()
  
  # check for multiple layers
  if (terra::nlyr(x) > 1) {
    rlang::abort(
      "SpatRaster object contains multiple layers. SAGA-GIS requires single-layer rasters as inputs"
    )
  }
  
  # check if layer is in-memory
  if (terra::sources(x)$source == "") {
    in_memory <- TRUE
    part_of_multiband <- FALSE
  } else {
    in_memory <- FALSE
  }

  # check if layer is part of a multi-band raster
  if (!in_memory) {
    info <- rgdal::GDALinfo(terra::sources(x)$source)
    n_bands <- nrow(attr(info, "df"))
    part_of_multiband <- n_bands > 1
  }
  
  # single-band raster on disk -> filename -> saga
  if (!part_of_multiband & !in_memory)
    x <- terra::sources(x)$source
  
  # otherwise save to temporary file
  if (part_of_multiband | in_memory) {
    temp <- tempfile(tmpdir = temp_path, fileext = ".sdat")
    terra::writeRaster(x, filename = temp)
    pkg.env$sagaTmpFiles <- append(pkg.env$sagaTmpFiles, temp)
    x <- temp
  }
  
  x
}


#' @export
#' @keywords internal
save_object.RasterStack <- function(x, ...) {
  args <- list(...)
  temp_path <- args$temp_path
  
  if (is.null(temp_path))
    temp_path <- tempdir()
  
  if (raster::nlayers(x) == 1) {
    x <- raster::raster(x)
    x <- save_object(x)
  } else {
    rlang::abort("Raster object contains multiple layers. SAGA-GIS requires single layer rasters as inputs")
  }

  x
}


#' @export
#' @keywords internal
save_object.data.frame <- function(x, ...) {
  args <- list(...)
  temp_path <- args$temp_path
  
  if (is.null(temp_path))
    temp_path <- tempdir()
  
  temp <- tempfile(tmpdir = temp_path, fileext = ".txt")
  pkg.env$sagaTmpFiles <- append(pkg.env$sagaTmpFiles, temp)
  utils::write.table(x = x, file = temp, sep = "\t")
  temp
}

spatial_to_saga <- function(x, temp_path) {
  temp <- tempfile(tmpdir = temp_path, fileext = ".shp")
  pkg.env$sagaTmpFiles <- append(pkg.env$sagaTmpFiles, temp)
  rgdal::writeOGR(
    obj = x,
    dsn = temp,
    layer = 1,
    driver = "ESRI Shapefile"
  )
  
  temp
}


#' @export
#' @keywords internal
save_object.SpatialPointsDataFrame <- function(x, ...) {
  args <- list(...)
  temp_path <- args$temp_path
  
  if (is.null(temp_path))
    temp_path <- tempdir()
  
  spatial_to_saga(x, temp_path)
}


#' @export
#' @keywords internal
save_object.SpatialLinesDataFrame <- function(x, ...) {
  args <- list(...)
  temp_path <- args$temp_path
  
  if (is.null(temp_path))
    temp_path <- tempdir()
  
  spatial_to_saga(x, temp_path)
}


#' @export
#' @keywords internal
save_object.SpatialPolygonsDataFrame <- function(x, ...) {
  args <- list(...)
  temp_path <- args$temp_path
  
  if (is.null(temp_path))
    temp_path <- tempdir()
  
  spatial_to_saga(x, temp_path)
}


#' @export
#' @keywords internal
save_object.list <- function(x, ...) {
  lapply(x, save_object)
}
