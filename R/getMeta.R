#' Get information on meteorological sites
#'
#' This function is primarily used to find a site code that can be used to
#' access data using [importNOAA()]. Sites searches of approximately 30,000
#' sites can be carried out based on the site name and based on the nearest
#' locations based on user-supplied latitude and longitude.
#'
#' @title Find a ISD site code and other meta data
#' @param site A site name search string e.g. `site = "heathrow"`. The search
#'   strings and be partial and can be upper or lower case e.g. `site =
#'   "HEATHR"`.
#' @param lat,lon Decimal latitude and longitude (or other Y/X coordinate if
#'   using a different `crs`). If provided, the `n` closest ISD stations to this
#'   coordinate will be returned.
#' @param crs The coordinate reference system (CRS) of the data, passed to
#'   [sf::st_crs()]. By default this is [EPSG:4326](https://epsg.io/4326), the
#'   CRS associated with the commonly used latitude and longitude coordinates.
#'   Different coordinate systems can be specified using `crs` (e.g., `crs =
#'   27700` for the [British National Grid](https://epsg.io/27700)). Note that
#'   non-lat/lng coordinate systems will be re-projected to EPSG:4326 for making
#'   comparisons with the NOAA metadata plotting on the map.
#' @param country The country code. This is a two letter code. For a full
#'   listing see <https://www1.ncdc.noaa.gov/pub/data/noaa/isd-history.csv>.
#' @param state The state code. This is a two letter code.
#' @param n The number of nearest sites to search based on `latitude` and
#'   `longitude`.
#' @param end.year To help filter sites based on how recent the available data
#'   are. `end.year` can be "current", "any" or a numeric year such as 2016, or
#'   a range of years e.g. 1990:2016 (which would select any site that had an
#'   end date in that range. **By default only sites that have some data for the
#'   current year are returned**.
#' @param provider By default a map will be created in which readers may toggle
#'   between a vector base map and a satellite/aerial image. `provider` allows
#'   users to override this default; see
#'   \url{http://leaflet-extras.github.io/leaflet-providers/preview/} for a list
#'   of all base maps that can be used. If multiple base maps are provided, they
#'   can be toggled between using a "layer control" interface.
#' @param plot If `TRUE` will plot sites on an interactive leaflet map.
#' @param returnMap Should the leaflet map be returned instead of the meta data?
#'   Default is `FALSE`.
#' @return A data frame is returned with all available meta data, mostly
#'   importantly including a `code` that can be supplied to [importNOAA()]. If
#'   latitude and longitude searches are made an approximate distance, `dist` in
#'   km is also returned.
#' @export
#' @author David Carslaw
#' @family NOAA ISD functions
#' @examples
#' \dontrun{
#' ## search for sites with name beijing
#' getMeta(site = "beijing")
#' }
#'
#' \dontrun{
#' ## search for near a specified lat/lon - near Beijing airport
#' ## returns 'n' nearest by default
#' getMeta(lat = 40, lon = 116.9)
#' }
getMeta <- function(
  site = "heathrow",
  lat = NA,
  lon = NA,
  crs = 4326,
  country = NA,
  state = NA,
  n = 10,
  end.year = "current",
  provider = c("OpenStreetMap", "Esri.WorldImagery"),
  plot = TRUE,
  returnMap = FALSE
) {
  ## read the meta data

  ## download the file, else use the package version
  meta <- getMetaLive()

  # check year
  if (!any(end.year %in% c("current", "all"))) {
    if (!is.numeric(end.year)) {
      cli::cli_abort(
        "{.field end.year} should be one of 'current', 'all' or a numeric 4-digit year such as {2016}."
      )
    }
  }

  # we base the current year as the max available in the meta data
  if ("current" %in% end.year) {
    end.year <-
      max(as.numeric(format(meta$END, "%Y")), na.rm = TRUE)
  }
  if ("all" %in% end.year) {
    end.year <- 1900:2100
  }

  ## search based on name of site
  if (!missing(site)) {
    ## search for station
    meta <- meta[grep(site, meta$STATION, ignore.case = TRUE), ]
  }

  ## search based on country codes
  if (!missing(country) && !is.na(country)) {
    ## search for country
    id <- which(meta$CTRY %in% toupper(country))
    meta <- meta[id, ]
  }

  ## search based on state codes
  if (!missing(state)) {
    ## search for state
    id <- which(meta$ST %in% toupper(state))
    meta <- meta[id, ]
  }

  # make sure no missing lat / lon
  id <- which(is.na(meta$LON))

  if (length(id) > 0) {
    meta <- meta[-id, ]
  }

  id <- which(is.na(meta$LAT))
  if (length(id) > 0) {
    meta <- meta[-id, ]
  }

  # filter by end year
  id <- which(format(meta$END, "%Y") %in% end.year)
  meta <- meta[id, ]

  ## approximate distance to site
  if (!is.na(lat) && !is.na(lon)) {
    point <-
      sf::st_as_sf(
        data.frame(lon = lon, lat = lat),
        coords = c("lon", "lat"),
        crs = sf::st_crs(crs)
      ) |>
      sf::st_transform(crs = sf::st_crs(4326))

    meta_sf <-
      sf::st_as_sf(meta, coords = c("LON", "LAT"), crs = 4326)

    meta$dist <- as.numeric(sf::st_distance(meta_sf, point)) / 1000L

    ## sort and return top n nearest
    meta <- dplyr::slice_min(meta, order_by = .data$dist, n = n)
  }

  dat <- dplyr::rename(meta, latitude = "LAT", longitude = "LON")

  names(dat) <- tolower(names(dat))

  if (plot) {
    content <- paste(
      paste0("<b>", dat$station, "</b>"),
      paste("<hr><b>Code:</b>", dat$code),
      paste("<b>Start:</b>", dat$begin),
      paste("<b>End:</b>", dat$end),
      sep = "<br/>"
    )

    if ("dist" %in% names(dat)) {
      content <- paste(
        content,
        paste("<b>Distance:</b>", round(dat$dist, 1), "km"),
        sep = "<br/>"
      )
    }

    m <- leaflet::leaflet(dat)

    for (i in provider) {
      m <- leaflet::addProviderTiles(map = m, provider = i, group = i)
    }

    m <-
      leaflet::addMarkers(
        map = m,
        ~longitude,
        ~latitude,
        popup = content,
        clusterOptions = leaflet::markerClusterOptions()
      )

    if (!is.na(lat) && !is.na(lon)) {
      m <- leaflet::addCircles(
        map = m,
        data = point,
        weight = 20,
        radius = 200,
        stroke = TRUE,
        color = "red",
        popup = paste(
          "Search location",
          paste("Lat =", dat$latitude),
          paste("Lon =", dat$longitude),
          sep = "<br/>"
        )
      )
    }

    if (length(provider) > 1) {
      m <-
        leaflet::addLayersControl(
          map = m,
          baseGroups = provider,
          options = leaflet::layersControlOptions(
            collapsed = FALSE,
            autoZIndex = FALSE
          )
        )
    }

    print(m)
  }

  if (returnMap) {
    return(m)
  } else {
    return(dat)
  }
}


#' Obtain site meta data from NOAA server
#'
#' Download all NOAA meta data, allowing for re-use and direct querying.
#'
#' @param ... Currently unused.
#'
#' @return a [tibble][tibble::tibble-package]
#'
#' @family NOAA ISD functions
#'
#' @examples
#' \dontrun{
#' meta <- getMetaLive()
#' head(meta)
#' }
#' @export
getMetaLive <- function(...) {
  ## downloads the whole thing fresh

  url <- "https://www1.ncdc.noaa.gov/pub/data/noaa/isd-history.csv"
  meta <- readr::read_csv(
    url,
    skip = 21,
    col_names = FALSE,
    col_types = readr::cols(
      X1 = readr::col_character(),
      X2 = readr::col_character(),
      X3 = readr::col_character(),
      X4 = readr::col_character(),
      X5 = readr::col_character(),
      X6 = readr::col_character(),
      X7 = readr::col_double(),
      X8 = readr::col_double(),
      X9 = readr::col_double(),
      X10 = readr::col_date(format = "%Y%m%d"),
      X11 = readr::col_date(format = "%Y%m%d")
    ),
    progress = FALSE
  )

  # if not available e.g. due to US Government shutdown, flag and exit
  # some header data may still be read, so check column number
  if (ncol(meta) == 1L) {
    cli::cli_abort(
      "File not available, check {.url https://www1.ncdc.noaa.gov/pub/data/noaa/} for potential server problems.",
      call. = FALSE
    )
  }

  ## names in the meta file
  names(meta) <- c(
    "USAF",
    "WBAN",
    "STATION",
    "CTRY",
    "ST",
    "CALL",
    "LAT",
    "LON",
    "ELEV(M)",
    "BEGIN",
    "END"
  )

  ## full character string of site id
  meta$USAF <-
    formatC(meta$USAF, width = 6, format = "d", flag = "0")

  ## code used to query data
  meta$code <- paste0(meta$USAF, "-", meta$WBAN)

  return(meta)
}
