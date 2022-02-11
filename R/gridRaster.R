#' @title Make grid polygon
#'
#' @param mat matrix with coordinates.
#' @param proj4 string, proj4string of the original raster.
#' @param ID integer, ID of the polygon (can be anything as lons as unique).
gridPolygon <- function(mat, proj4, ID) {
  pol <- sp::SpatialPolygons(
    list(
      sp::Polygons(
        list(
          sp::Polygon(
            mat
          )
        ),
        ID = 1
      )
    ),
    proj4string = sp::CRS(proj4)
  )
  sp::SpatialPolygonsDataFrame(pol, data = data.frame(ID = ID))
}

#' @title Create spatial grid
#'
#' @param x RasterLayer.
#' @param split.hor integer, number of horizontal splits.
#' @param split.vert integer, number of vertical splits.
#' @param proj4 string, proj4string of the original raster.
gridRaster <- function(x, split.hor, split.vert) {
  # get proj4string of the CRS
  proj4 <- sp::proj4string(x)
  # get corner points
  x <- seq(raster::xmin(r), raster::xmax(r), length.out = split.hor)
  y <- seq(raster::ymin(r), raster::ymax(r), length.out = split.vert)
  # create polygons
  pols <- list()

  grids <- c()
  id <- 0
  for (i in seq_len(split.hor - 1)) {
    for (j in seq_len(split.vert - 1)) {
      id <- id + 1
      mat <- matrix(c(
        x[i], y[j],
        x[i + 1], y[j],
        x[i + 1], y[j + 1],
        x[i], y[j + 1],
        x[i], y[j]
      ),
      ncol = 2,
      byrow = TRUE)

      pol <- gridPolygon(mat, proj4, ID = id)
      if (length(grids) == 0) {
        grids <- pol
      } else {
        grids <- rbind(grids, pol)
      }
    }
  }
  return(grids)
}

#' @title Split raster into cells
#'
#' @param x RasterLayer.
#' @param y SpatialPolygonsDataFrame, polygon grid (as created using
#'   gridRaster()),
#' @param buffer TRUE/FALSE, if to create a small buffer around the polygon to
#'   avoid missing values at the polygon border when merging back together.
#' @param out.dir string, output directory; default to tempdir().
splitRaster <- function(x, y, buffer = TRUE, out.dir = tempdir()) {
  for (i in seq_along(y)) {
    pol <- y[i, ]
    if (buffer) pol <- raster::buffer(pol, max(raster::res(x)) * 2)
    cropped <- raster::crop(x, pol)
    raster::writeRaster(cropped, paste0(out.dir, "/grid-", i, ".tif"))
  }
}

#' @title Project splitted raster
#'
#' @param proj4 string, proj4string of the target raster.
#' @param in.dir string, input directory; default to tempdir()
#' @param out.dir string, output directory; default to tempdir()
#'
#' @examples
#' \dontrun{
#' r <- raster::raster("~/Documents/calvana.tif")
#' proj4 <- readLines("~/Proj/nepal/data/proj4.txt")
#' r2 <- raster::projectRaster(r, crs = proj4)
#' g <- gridRaster(r, 5, 5)
#' splitRaster(r, g)
#' t_crs <- sp::proj4string(sp::CRS("EPSG:3226"))
#' reprojectRaster(t_crs)
#' raster::plot(r)
#' raster::lines(g)
#' }
reprojectRaster <- function(proj4, in.dir = tempdir(), out.dir = tempdir()) {
  input <- list.files(in.dir, pattern = "grid-", full.names = TRUE)
  for (x in input) {
    i <- gsub("[.]tif", "", strsplit(x, split = "-")[[1]][2])
    repr <- raster::raster(x)
    repr <- raster::projectRaster(repr, crs = proj4)
    raster::writeRaster(repr, paste0(out.dir, "/reprojected-", i, ".tif"), overwrite = TRUE)
  }
}
