#' Import station metadata for the Integrated Surface Databse
#'
#' This function is primarily used to find a site code that can be used to
#' access data using [import_isd_hourly()]. Sites searches of approximately
#' 30,000 sites can be carried out based on the site name and based on the
#' nearest locations based on user-supplied latitude and longitude.
#'
#' @inheritParams import_ghcn_stations
#'
#' @param site A site name search string e.g. `site = "heathrow"`. The search
#'   strings and be partial and can be upper or lower case e.g. `site =
#'   "HEATHR"`.
#'
#' @param country The country code. This is a two letter code. For a full
#'   listing see <https://www.ncei.noaa.gov/pub/data/noaa/isd-history.csv>.
#'
#' @param state The state code. This is a two letter code.
#'
#' @param end_year To help filter sites based on how recent the available data
#'   are. `end_year` can be "current", "any" or a numeric year such as 2016, or
#'   a range of years e.g. 1990:2016 (which would select any site that had an
#'   end date in that range. **By default only sites that have some data for the
#'   current year are returned**.
#'
#' @return A data frame is returned with all available meta data, mostly
#'   importantly including a `code` that can be supplied to [importNOAA()]. If
#'   latitude and longitude searches are made an approximate distance, `dist` in
#'   km is also returned.
#'
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
#' ## search for near a specified lat/lng - near Beijing airport
#' ## returns 'n_max' nearest by default
#' getMeta(lat = 40, lng = 116.9)
#' }
import_isd_stations <- function(
  site = NULL,
  country = NULL,
  state = NULL,
  lat = NULL,
  lng = NULL,
  crs = 4326,
  n_max = 10,
  end_year = "current",
  provider = c("OSM" = "OpenStreetMap", "Satellite" = "Esri.WorldImagery"),
  return = c("table", "sf", "map")
) {
  ## read the meta data

  ## download the file, else use the package version
  meta <- import_isd_stations_live()
  return <- rlang::arg_match(return, c("table", "sf", "map"))

  # check year
  if (!any(end_year %in% c("current", "all"))) {
    if (!is.numeric(end_year)) {
      cli::cli_abort(
        "{.field end_year} should be one of 'current', 'all' or a numeric 4-digit year such as {2016}."
      )
    }
  }

  # we base the current year as the max available in the meta data
  if ("current" %in% end_year) {
    end_year <-
      max(as.numeric(format(meta$END, "%Y")), na.rm = TRUE)
  }
  if ("all" %in% end_year) {
    end_year <- 1900:2100
  }

  ## search based on name of site
  if (!is.null(site)) {
    ## search for station
    meta <- meta[grep(site, meta$STATION, ignore.case = TRUE), ]
  }

  ## search based on country codes
  if (!is.null(country)) {
    ## search for country
    id <- which(meta$CTRY %in% toupper(country))
    meta <- meta[id, ]
  }

  ## search based on state codes
  if (!is.null(state)) {
    ## search for state
    id <- which(meta$ST %in% toupper(state))
    meta <- meta[id, ]
  }

  # make sure no missing lat / lng
  id <- which(is.na(meta$LON))

  if (length(id) > 0) {
    meta <- meta[-id, ]
  }

  id <- which(is.na(meta$LAT))
  if (length(id) > 0) {
    meta <- meta[-id, ]
  }

  # filter by end year
  id <- which(format(meta$END, "%Y") %in% end_year)
  meta <- meta[id, ]

  ## approximate distance to site
  if (!is.null(lat) && !is.null(lng)) {
    point <-
      sf::st_as_sf(
        data.frame(lng = lng, lat = lat),
        coords = c("lng", "lat"),
        crs = sf::st_crs(crs)
      ) |>
      sf::st_transform(crs = sf::st_crs(4326))

    meta_sf <-
      sf::st_as_sf(meta, coords = c("LON", "LAT"), crs = 4326)

    meta$dist <- as.numeric(sf::st_distance(meta_sf, point)) / 1000L

    ## sort and return top n nearest
    meta <- dplyr::slice_min(meta, order_by = .data$dist, n = n_max)
  }

  dat <- dplyr::rename(meta, latitude = "LAT", longitude = "LON")

  names(dat) <- tolower(names(dat))

  meta <- dat

  if (return %in% c("sf", "map")) {
    meta <- sf::st_as_sf(
      meta,
      coords = c("longitude", "latitude"),
      crs = 4326,
      remove = FALSE
    )

    if (return == "map") {
      rlang::check_installed("leaflet")

      fmt_val <- function(x) {
        ifelse(
          is.na(x),
          "<span style='color: #bbb;'>N/A</span>",
          as.character(x)
        )
      }

      content <- paste0(
        "<div style='font-family: Arial, sans-serif; min-width: 220px; max-width: 280px;'>",

        # Combined name + code header
        "<div style='background: #2c9b6e; color: white; padding: 8px 12px; margin: -10px -10px 10px; border-radius: 4px 4px 0 0;'>",
        "<div style='font-size: 14px; font-weight: bold; margin-bottom: 4px;'>",
        dat$station,
        "</div>",
        "<div style='font-family: monospace; font-size: 12px; background: rgba(0,0,0,0.2); display: inline-block; padding: 2px 6px; border-radius: 3px; letter-spacing: 0.5px;'>",
        dat$code,
        "</div>",
        "</div>",

        # Temporal section
        "<div style='margin-bottom: 8px;'>",
        "<div style='font-size: 11px; font-weight: bold; text-transform: uppercase; color: #888; margin-bottom: 4px; border-bottom: 1px solid #eee; padding-bottom: 2px;'>Coverage</div>",
        "<table style='font-size: 12px; width: 100%; border-collapse: collapse;'>",
        "<tr><td style='color: #555; padding: 2px 0;'><b>Start</b></td><td>",
        fmt_val(dat$begin),
        "</td></tr>",
        "<tr><td style='color: #555; padding: 2px 0;'><b>End</b></td><td>",
        fmt_val(dat$end),
        "</td></tr>",
        "</table>",
        "</div>",

        # Geography section
        "<div style='margin-bottom: 8px;'>",
        "<div style='font-size: 11px; font-weight: bold; text-transform: uppercase; color: #888; margin-bottom: 4px; border-bottom: 1px solid #eee; padding-bottom: 2px;'>Geography</div>",
        "<table style='font-size: 12px; width: 100%; border-collapse: collapse;'>",
        "<tr><td style='color: #555; padding: 2px 0;'><b>Country</b></td><td>",
        fmt_val(dat$ctry),
        "</td></tr>",
        "<tr><td style='color: #555; padding: 2px 0;'><b>State</b></td><td>",
        fmt_val(dat$st),
        "</td></tr>",
        "<tr><td style='color: #555; padding: 2px 0;'><b>Elevation</b></td><td>",
        ifelse(
          is.na(dat$`elev(m)`),
          fmt_val(dat$`elev(m)`),
          paste(dat$`elev(m)`, "m")
        ),
        "</td></tr>",
        "</table>",
        "</div>",

        "</div>"
      )

      if ("dist" %in% names(dat)) {
        content <- paste0(
          content,
          "<div style='margin-top: 8px;'>",
          "<div style='font-size: 11px; font-weight: bold; text-transform: uppercase; color: #888; margin-bottom: 4px; border-bottom: 1px solid #eee; padding-bottom: 2px;'>Distance from search</div>",
          "<div style='font-family: monospace; font-size: 12px; background: #f4f4f4; border-left: 3px solid #c0392b; padding: 3px 8px; border-radius: 0 3px 3px 0;'>",
          round(dat$dist, 1),
          " km",
          "</div>",
          "</div>",
          "</div>" # closes the outer wrapper div
        )
      }

      m <- leaflet::leaflet(dat) |>
        leaflet::addControl(
          html = paste0(
            "<div style='font-family: Arial, sans-serif; background: white; padding: 8px 14px; border-radius: 4px; box-shadow: 0 1px 5px rgba(0,0,0,0.3);'>",
            "<div style='font-size: 13px; font-weight: bold; color: #2c9b6e;'>ISD Stations</div>",
            "<div style='font-size: 11px; color: #888; margin-top: 2px;'>Integrated Surface Database</div>",
            "</div>"
          ),
          position = "bottomleft"
        )

      if (!rlang::is_named(provider)) {
        provider <- stats::setNames(provider, provider)
      }
      for (i in seq_along(provider)) {
        m <- leaflet::addProviderTiles(
          m,
          provider = provider[[i]],
          group = names(provider)[[i]]
        )
      }

      m <-
        leaflet::addMarkers(
          map = m,
          ~longitude,
          ~latitude,
          popup = content,
          clusterOptions = leaflet::markerClusterOptions(),
          group = "Stations"
        )
      overlays <- "Stations"

      if (!is.null(lat) && !is.null(lng)) {
        overlays <- c(overlays, "Target")
        m <- leaflet::addAwesomeMarkers(
          map = m,
          data = point,
          group = "Target",
          icon = leaflet::makeAwesomeIcon(
            icon = "circle",
            library = "fa",
            markerColor = "red",
            iconColor = "#FFFFFF"
          ),
          popup = paste0(
            "<div style='font-family: Arial, sans-serif; min-width: 200px; max-width: 260px;'>",

            # Header
            "<div style='background: #c0392b; color: white; padding: 8px 12px; margin: -10px -10px 10px; border-radius: 4px 4px 0 0;'>",
            "<div style='font-size: 14px; font-weight: bold;'>Search Location</div>",
            "</div>",

            # Coordinates section
            "<div style='margin-bottom: 8px;'>",
            "<div style='font-size: 11px; font-weight: bold; text-transform: uppercase; color: #888; margin-bottom: 4px; border-bottom: 1px solid #eee; padding-bottom: 2px;'>Coordinates</div>",
            "<table style='font-size: 12px; width: 100%; border-collapse: collapse;'>",
            "<tr><td style='color: #555; padding: 2px 0;'><b>Latitude</b></td><td style='font-family: monospace;'>",
            lat,
            "</td></tr>",
            "<tr><td style='color: #555; padding: 2px 0;'><b>Longitude</b></td><td style='font-family: monospace;'>",
            lng,
            "</td></tr>",
            "<tr><td style='color: #555; padding: 2px 0;'><b>CRS</b></td><td style='font-family: monospace;'>EPSG:",
            crs,
            "</td></tr>",
            "</table>",
            "</div>",

            "</div>"
          )
        )
      }

      m <-
        leaflet::addLayersControl(
          map = m,
          baseGroups = names(provider),
          overlayGroups = overlays,
          options = leaflet::layersControlOptions(
            collapsed = FALSE,
            autoZIndex = TRUE
          )
        )

      meta <- m
    }
  }

  return(meta)
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
#' meta <- import_isd_stations_live()
#' head(meta)
#' }
#' @export
import_isd_stations_live <- function(...) {
  ## downloads the whole thing fresh
  warn_isd()
  url <- "https://www.ncei.noaa.gov/pub/data/noaa/isd-history.csv"
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
      "File not available, check {.url https://www.ncei.noaa.gov/pub/data/noaa/} for potential server problems.",
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
