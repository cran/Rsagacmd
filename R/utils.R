#' Calculate the t_slope value based on DEM resolution for MRVBF
#'
#' Calculates the t_slope value for the Multiresolution Index of Valley Bottom
#' Flatness (Gallant and Dowling, 2003) based on input DEM resolution. MRVBF
#' identified valley bottoms based on classifying slope angle and identifying
#' low areas by ranking elevation in respect to the surrounding topography
#' across a range of DEM resolutions. The MRVBF algorithm was developed using a
#' 25 m DEM, and so if the input DEM has a different resolution then the slope
#' threshold t_slope needs to be adjusted from its default value of 16 in order
#' to maintain the relationship between slope and DEM resolution. This function
#' provides a convenient way to perform that calculation.
#'
#' @param res numeric, DEM resolution
#'
#' @return numeric, t_slope value for MRVBF
#' @export
#'
#' @examples
#' mrvbf_threshold(res = 10)
mrvbf_threshold <- function(res) {
  t_slope <- 116.57 * (res**-0.62)
  return(t_slope)
}


#' Split a raster grid into tiles for tile-based processing
#'
#' Split a raster grid into tiles. The tiles are saved as Rsagacmd
#' temporary files, and are loaded as a list of R objects for further
#' processing. This is a function to make the the SAGA-GIS
#' grid_tools / tiling tool more convenient to use.
#'
#' @param x A `saga` object.
#' @param grid A path to a GDAL-supported raster to apply tiling, or a
#'   SpatRaster.
#' @param nx An integer with the number of x-pixels per tile.
#' @param ny An integer with the number of y-pixels per tile.
#' @param overlap An integer with the number of overlapping pixels.
#' @param file_path An optional file file path to store the raster tiles.
#'
#' @return A list of SpatRaster objects representing tiled data.
#' @export
#' @examples
#' \dontrun{
#' # Initialize a saga object
#' saga <- saga_gis()
#'
#' # Generate a random DEM
#' dem <- saga$grid_calculus$random_terrain(radius = 15, iterations = 500)
#'
#' # Return tiled version of DEM
#' tiles <- tile_geoprocessor(x = saga, grid = dem, nx = 20, ny = 20)
#' }
tile_geoprocessor <- function(x, grid, nx, ny, overlap = 0, file_path = NULL) {
  if (is.null(file_path)) {
    include_as_tempfiles <- TRUE
    file_path <-
      file.path(tempdir(), paste0("tiles", floor(stats::runif(1, 0, 1e6))))
    
    if (!dir.exists(file_path)) {
      dir.create(file_path)
    }
  } else {
    include_as_tempfiles <- FALSE
  }
  
  x$grid_tools$tiling(
    grid = grid,
    overlap = overlap,
    nx = nx,
    ny = ny,
    tiles_path = file_path,
    tiles_save = TRUE,
    .all_outputs = FALSE,
    .intern = FALSE
  )
  
  tile_sdats <- list.files(file_path, pattern = "*.sdat$", full.names = TRUE)
  
  if (include_as_tempfiles) {
    pkg.env$sagaTmpFiles <- append(pkg.env$sagaTmpFiles, tile_sdats)
  }
  
  senv <- environment(x[[1]][[1]])$senv
  
  if (senv$raster_backend == "terra") {
    tiles <- sapply(tile_sdats, terra::rast)
  }
  
  if (senv$raster_backend == "stars") {
    tiles <- sapply(tile_sdats, stars::read_stars)
  }
  
  tiles
}
