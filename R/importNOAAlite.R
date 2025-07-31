#' Import "Lite" Meteorological data from the NOAA Integrated Surface Database
#' (ISD)
#'
#' This function is an alternative to [importNOAA()], and provides access to the
#' "Lite" format of the data. This a subset of the larger [importNOAA()] dataset
#' featuring eight common climatological variables. As it assigns the nearest
#' measurement to the "top of the hour" to the data, specific values are likely
#' similar but different to those returned by [importNOAA()]. Read the
#' [technical
#' document](https://www.ncei.noaa.gov/pub/data/noaa/isd-lite/isd-lite-technical-document.pdf)
#' for more information.
#'
#' Note the following units for the main variables:
#'
#' \describe{
#'
#' \item{date}{Date/time in POSIXct format. **Note the time zone is UTC
#' and may need to be adjusted to merge with other local data.}
#'
#' \item{latitude}{Latitude in decimal degrees (-90 to 90).}
#'
#' \item{longitude}{Longitude in decimal degrees (-180 to 180). Negative numbers
#' are west of the Greenwich Meridian.}
#'
#' \item{elev}{Elevation of site in metres.}
#'
#' \item{ws}{Wind speed in m/s.}
#'
#' \item{wd}{Wind direction in degrees. 90 is from the east.}
#'
#' \item{air_temp}{Air temperature in degrees Celcius.}
#'
#' \item{atmos_pres}{The sea level pressure in millibars.}
#'
#' \item{dew_point}{The dew point temperature in degrees Celcius.}
#'
#' \item{precip_6}{6-hour precipitation in mm.}
#'
#' \item{precip_1}{1-hour precipitation in mm.}
#'
#' \item{sky}{Sky Condition Total Coverage Code.}
#' }
#'
#' The data are returned in GMT (UTC). It may be necessary to adjust the time
#' zone when combining with other data. For example, if air quality data were
#' available for Beijing with time zone set to "Etc/GMT-8" (note the negative
#' offset even though Beijing is ahead of GMT. See the `openair` package and
#' manual for more details), then the time zone of the met data can be changed
#' to be the same. One way of doing this would be `attr(met$date, "tzone") <-
#' "Etc/GMT-8"` for a meteorological data frame called `met`. The two data sets
#' could then be merged based on `date`.
#'
#' @param code The identifying code as a character string. The code is a
#'   combination of the USAF and the WBAN unique identifiers. The codes are
#'   separated by a \dQuote{-} e.g. `code = "037720-99999"`.
#' @param year The year to import. This can be a vector of years e.g. `year =
#'   2000:2005`.
#' @param quiet If `FALSE`, print missing sites / years to the screen, and show
#'   a progress bar if multiple sites are imported.
#' @export
#' @return Returns a data frame of surface observations. The data frame is
#'   consistent for use with the `openair` package. Note that the data are
#'   returned in GMT (UTC) time zone format. Users may wish to express the data
#'   in other time zones, e.g., to merge with air pollution data. The
#'   [lubridate][lubridate::lubridate-package] package is useful in this
#'   respect.
#' @family NOAA ISD functions
#' @seealso [getMeta()] to obtain the codes based on various site search
#'   approaches.
#' @author Jack Davison
#' @examples
#'
#' \dontrun{
#' heathrow_lite <- importNOAAlite(code = "037720-99999", year = 2025)
#' }
importNOAAlite <- function(
  code = "037720-99999",
  year = 2025,
  quiet = FALSE
) {
  meta <- getMeta(returnMap = F, plot = F)

  import_lite <- function(code, year) {
    station_name <- meta[meta$code == code, ]$station
    latitude <- meta[meta$code == code, ]$latitude
    longitude <- meta[meta$code == code, ]$longitude
    elevation <- meta[meta$code == code, ]$`elev(m)`

    path <- "https://www.ncei.noaa.gov/pub/data/noaa/isd-lite/DATAYEAR/DATACODE-DATAYEAR.gz"
    path <- gsub("DATACODE", code, path)
    path <- gsub("DATAYEAR", year, path)

    t <- tempfile(fileext = ".gz")

    utils::download.file(path, t, quiet = TRUE)

    utils::read.fwf(
      t,
      widths = c(5, 3, 3, 2, 6, 6, 6, 6, 6, 6, 6, 6),
      col.names = c(
        "year",
        "month",
        "day",
        "hour",
        "air_temp",
        "dew_point",
        "atmos_pres",
        "wd",
        "ws",
        "sky",
        "precip_1",
        "precip_6"
      )
    ) |>
      dplyr::tibble() |>
      dplyr::mutate(
        dplyr::across(
          dplyr::where(is.numeric),
          \(x) dplyr::na_if(x, -9999)
        )
      ) |>
      dplyr::mutate(
        date = ISOdate(
          year = .data$year,
          month = .data$month,
          day = .data$day,
          hour = .data$hour,
          tz = "UTC"
        ),
        .before = 0,
        .keep = "unused"
      ) |>
      dplyr::mutate(
        air_temp = .data$air_temp / 10,
        dew_point = .data$dew_point / 10,
        atmos_pres = .data$atmos_pres / 10,
        ws = .data$ws / 10,
        precip_1 = .data$precip_1 / 10,
        precip_6 = .data$precip_6 / 10
      ) |>
      dplyr::mutate(
        code = code,
        station = station_name,
        latitude = latitude,
        longitude = longitude,
        elev = elevation,
        .before = 0
      ) |>
      dplyr::relocate(
        "code",
        "station",
        "date",
        "latitude",
        "longitude",
        "elev",
        "ws",
        "wd",
        "air_temp",
        "atmos_pres",
        "dew_point",
        "precip_6",
        "precip_1",
        "sky"
      )
  }

  tidyr::crossing(
    code = code,
    year = year
  ) |>
    purrr::pmap(purrr::possibly(import_lite), .progress = !quiet) |>
    dplyr::bind_rows()
}
