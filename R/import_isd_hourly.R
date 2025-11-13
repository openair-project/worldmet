#' Import Meteorological data from the NOAA Integrated Surface Database (ISD)
#'
#' This is the main function to import data from the NOAA Integrated Surface
#' Database (ISD). The ISD contains detailed surface meteorological data from
#' around the world for over 30,000 locations. For general information of the
#' ISD see
#' [https://www.ncei.noaa.gov/products/land-based-station/integrated-surface-database](https://www.ncei.noaa.gov/products/land-based-station/integrated-surface-database)
#' and the map here
#' [https://gis.ncdc.noaa.gov/maps/ncei](https://gis.ncdc.noaa.gov/maps/ncei).
#'
#' Note the following units for the main variables:
#'
#' \describe{
#'
#' \item{date}{Date/time in POSIXct format. **Note the time zone is GMT (UTC)
#' and may need to be adjusted to merge with other local data. See details
#' below.**}
#'
#' \item{latitude}{Latitude in decimal degrees (-90 to 90).}
#'
#' \item{longitude}{Longitude in decimal degrees (-180 to 180). Negative numbers
#' are west of the Greenwich Meridian.}
#'
#' \item{elevation}{Elevation of site in metres.}
#'
#' \item{wd}{Wind direction in degrees. 90 is from the east.}
#'
#' \item{ws}{Wind speed in m/s.}
#'
#' \item{ceil_hgt}{The height above ground level (AGL) of the lowest cloud or
#' obscuring phenomena layer aloft with 5/8 or more summation total sky cover,
#' which may be predominantly opaque, or the vertical visibility into a
#' surface-based obstruction.}
#'
#' \item{visibility}{The visibility in metres.}
#'
#' \item{air_temp}{Air temperature in degrees Celcius.}
#'
#' \item{dew_point}{The dew point temperature in degrees Celcius.}
#'
#' \item{atmos_pres}{The sea level pressure in millibars.}
#'
#' \item{RH}{The relative humidity (%).}
#'
#' \item{cl_1,  ...,  cl_3}{Cloud cover for different layers in Oktas (1-8).}
#'
#' \item{cl}{Maximum of cl_1 to cl_3 cloud cover in Oktas (1-8).}
#'
#' \item{cl_1_height, ..., cl_3_height}{Height of the cloud base for each later
#' in metres.}
#'
#' \item{precip_12}{12-hour precipitation in mm. The sum of this column should
#' give the annual precipitation.}
#'
#' \item{precip_6}{6-hour precipitation in mm.}
#'
#' \item{precip}{This value of precipitation spreads the 12-hour total across
#' the previous 12 hours.}
#'
#'
#' \item{pwc}{The description of the present weather description (if
#' available).}
#'
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
#' @inheritSection import_ghcn_hourly Parallel Processing
#'
#' @param code The identifying code as a character string. The code is a
#'   combination of the USAF and the WBAN unique identifiers. The codes are
#'   separated by a \dQuote{-} e.g. `code = "037720-99999"`.
#'
#' @param year The year to import. This can be a vector of years e.g. `year =
#'   2000:2005`.
#'
#' @param hourly Should hourly means be calculated? The default is `TRUE`. If
#'   `FALSE` then the raw data are returned.
#'
#' @param source The NOAA ISD service stores files in two formats; as delimited
#'   CSV files (`"delim"`) and as fixed width files (`"fwf"`).
#'   [import_isd_hourly()] defaults to `"delim"` but, if the delimited data
#'   store is down, users may wish to try `"fwf"` instead. Both data sources
#'   should be identical to one another.
#'
#' @param progress Show a progress bar when importing many stations/years?
#'   Defaults to `TRUE` in interactive R sessions. Passed to `.progress` in
#'   [purrr::map()] and/or [purrr::pmap()].
#'
#' @param quiet Print missing sites/years to the screen? Defaults to `FALSE`.
#'
#' @export
#' @return Returns a data frame of surface observations. The data frame is
#'   consistent for use with the `openair` package. Note that the data are
#'   returned in GMT (UTC) time zone format. Users may wish to express the data
#'   in other time zones, e.g., to merge with air pollution data.
#'
#' @family NOAA ISD functions
#' @author David Carslaw
#' @examples
#'
#' \dontrun{
#' # import some data
#' beijing_met <- import_isd_hourly(code = "545110-99999", year = 2010:2011)
#'
#' # importing lots of data? use mirai for parallel processing
#' mirai::daemons(4)
#' beijing_met2 <- import_isd_hourly(code = "545110-99999", year = 2010:2025)
#' }
import_isd_hourly <- function(
  code = "037720-99999",
  year = 2014,
  hourly = TRUE,
  source = c("delim", "fwf"),
  progress = rlang::is_interactive(),
  quiet = FALSE
) {
  warn_isd()
  source <- rlang::arg_match(source)

  # main web site https://www.ncei.noaa.gov/products/land-based-station/integrated-surface-database
  # formats document https://www.ncei.noaa.gov/data/global-hourly/doc/isd-format-document.pdf
  # brief csv file description https://www.ncei.noaa.gov/data/global-hourly/doc/CSV_HELP.pdf
  # gis map https://gis.ncdc.noaa.gov/map/viewer/#app=cdo&cfg=cdo&theme=hourly&layers=1
  # go through each of the years selected, use parallel processing

  # sites and years to process
  site_process <- expand.grid(
    code = code,
    year = year,
    stringsAsFactors = FALSE
  )

  # read in files - in_parallel defaults to sequential if no cores, will
  # use parallelism if daemons are set
  if (source == "delim") {
    dat <-
      purrr::pmap(
        site_process,
        purrr::in_parallel(
          \(code, year) getDatDelim(code = code, year = year, hourly = hourly),
          getDatDelim = getDatDelim,
          hourly = hourly
        ),
        .progress = progress
      ) |>
      purrr::list_rbind()
  }

  if (source == "fwf") {
    dat <-
      purrr::pmap(
        site_process,
        purrr::in_parallel(
          \(code, year) {
            getDatFwf(
              code = code,
              year = year,
              hourly = hourly,
              precip = TRUE,
              PWC = TRUE
            )
          },
          getDatFwf = getDatFwf,
          hourly = hourly
        ),
        .progress = progress
      ) |>
      purrr::list_rbind()
  }

  if (is.null(dat) || nrow(dat) == 0) {
    # get source not used
    trysource <- c("fwf", "delim")
    trysource <- trysource[trysource != source]

    # message
    cli::cli_inform(
      c(
        "x" = "Specified {.field site}-{.field year} combinations do not exist.",
        "i" = "Is the ISD service down? Check {.url https://www.ncei.noaa.gov/data/global-hourly/}.",
        "i" = 'Try {.code import_isd_hourly(..., source = "{trysource}")} to access an alternative data store.'
      )
    )
    return()
  }

  # check to see what is missing and print to screen
  actual <- dplyr::select(dat, "code", "date", "station") |>
    dplyr::mutate(year = as.numeric(format(.data$date, "%Y"))) |>
    dplyr::slice(1, .by = c("code", "year"))

  actual <- dplyr::left_join(site_process, actual, by = c("code", "year"))

  if (length(which(is.na(actual$date))) > 0 && !quiet) {
    cli::cli_h1("The following sites / years are missing:")
    cli::cli_ul(id = "worldmetmissing")
    missing <- dplyr::filter(actual, is.na(.data$date))
    for (i in seq_len(nrow(missing))) {
      df_i <- missing[i, ]
      cli::cli_li(
        items = "{.field site:} {df_i$code} in {.field year:} {df_i$year}"
      )
    }
    cli::cli_end(id = "worldmetmissing")
  }

  return(dat)
}

#' @noRd
getDatDelim <- function(code, year, hourly) {
  ## location of data
  file.name <- paste0(
    "https://www.ncei.noaa.gov/data/global-hourly/access/",
    year,
    "/",
    gsub(pattern = "-", "", code),
    ".csv"
  )

  # suppress warnings because some fields might be missing in the list
  # Note that not all available data is returned - just what I think is most useful
  met_data <- try(
    suppressWarnings(readr::read_csv(
      file.name,
      col_types = readr::cols_only(
        STATION = readr::col_character(),
        DATE = readr::col_datetime(format = ""),
        SOURCE = readr::col_double(),
        LATITUDE = readr::col_double(),
        LONGITUDE = readr::col_double(),
        ELEVATION = readr::col_double(),
        NAME = readr::col_character(),
        REPORT_TYPE = readr::col_character(),
        CALL_SIGN = readr::col_double(),
        QUALITY_CONTROL = readr::col_character(),
        WND = readr::col_character(),
        CIG = readr::col_character(),
        VIS = readr::col_character(),
        TMP = readr::col_character(),
        DEW = readr::col_character(),
        SLP = readr::col_character(),
        AA1 = readr::col_character(),
        AW1 = readr::col_character(),
        GA1 = readr::col_character(),
        GA2 = readr::col_character(),
        GA3 = readr::col_character()
      ),
      progress = FALSE
    )),
    silent = TRUE
  )

  if (class(met_data)[1] == "try-error") {
    met_data <- NULL
    return()
  }

  met_data <- dplyr::rename(
    met_data,
    code = "STATION",
    station = "NAME",
    date = "DATE",
    latitude = "LATITUDE",
    longitude = "LONGITUDE",
    elev = "ELEVATION"
  )

  met_data$code <- code

  # separate WND column

  if ("WND" %in% names(met_data)) {
    met_data <- tidyr::separate(
      data = met_data,
      col = "WND",
      into = c("wd", "x", "y", "ws", "z")
    )

    met_data <- dplyr::mutate(
      met_data,
      wd = as.numeric(.data$wd),
      wd = ifelse(.data$wd == 999, NA, .data$wd),
      ws = as.numeric(.data$ws),
      ws = ifelse(.data$ws == 9999, NA, .data$ws),
      ws = .data$ws / 10
    )
  }

  # separate TMP column
  if ("TMP" %in% names(met_data)) {
    met_data <- tidyr::separate(
      data = met_data,
      col = "TMP",
      into = c("air_temp", "flag_temp"),
      sep = ","
    )

    met_data <- dplyr::mutate(
      met_data,
      air_temp = as.numeric(.data$air_temp),
      air_temp = ifelse(.data$air_temp == 9999, NA, .data$air_temp),
      air_temp = .data$air_temp / 10
    )
  }

  # separate VIS column
  if ("VIS" %in% names(met_data)) {
    met_data <- tidyr::separate(
      data = met_data,
      col = "VIS",
      into = c("visibility", "flag_vis1", "flag_vis2", "flag_vis3"),
      sep = ",",
      fill = "right"
    )

    met_data <- dplyr::mutate(
      met_data,
      visibility = as.numeric(.data$visibility),
      visibility = ifelse(
        .data$visibility %in% c(9999, 999999),
        NA,
        .data$visibility
      )
    )
  }

  # separate DEW column
  if ("DEW" %in% names(met_data)) {
    met_data <- tidyr::separate(
      data = met_data,
      col = "DEW",
      into = c("dew_point", "flag_dew"),
      sep = ","
    )

    met_data <- dplyr::mutate(
      met_data,
      dew_point = as.numeric(.data$dew_point),
      dew_point = ifelse(.data$dew_point == 9999, NA, .data$dew_point),
      dew_point = .data$dew_point / 10
    )
  }
  # separate SLP column
  if ("SLP" %in% names(met_data)) {
    met_data <- tidyr::separate(
      data = met_data,
      col = "SLP",
      into = c("atmos_pres", "flag_pres"),
      sep = ",",
      fill = "right"
    )

    met_data <- dplyr::mutate(
      met_data,
      atmos_pres = as.numeric(.data$atmos_pres),
      atmos_pres = ifelse(
        .data$atmos_pres %in% c(99999, 999999),
        NA,
        .data$atmos_pres
      ),
      atmos_pres = .data$atmos_pres / 10
    )
  }

  # separate CIG (sky condition) column
  if ("CIG" %in% names(met_data)) {
    met_data <- tidyr::separate(
      data = met_data,
      col = "CIG",
      into = c("ceil_hgt", "flag_sky1", "flag_sky2", "flag_sky3"),
      sep = ",",
      fill = "right"
    )

    met_data <- dplyr::mutate(
      met_data,
      ceil_hgt = as.numeric(.data$ceil_hgt),
      ceil_hgt = ifelse(.data$ceil_hgt == 99999, NA, .data$ceil_hgt)
    )
  }

  ## relative humidity - general formula based on T and dew point
  met_data$RH <- 100 *
    ((112 - 0.1 * met_data$air_temp + met_data$dew_point) /
      (112 + 0.9 * met_data$air_temp))^8

  if ("GA1" %in% names(met_data)) {
    # separate GA1 (cloud layer 1 height, amount) column
    met_data <- tidyr::separate(
      data = met_data,
      col = "GA1",
      into = c(
        "cl_1",
        "code_1",
        "cl_1_height",
        "code_2",
        "cl_1_type",
        "code_3"
      ),
      sep = ","
    )

    met_data <- dplyr::mutate(
      met_data,
      cl_1 = as.numeric(.data$cl_1),
      cl_1 = ifelse(
        (is.na(.data$cl_1) & .data$ceil_hgt == 22000),
        0,
        .data$cl_1
      ),
      cl_1 = ifelse(.data$cl_1 == 99, NA, .data$cl_1),
      cl_1_height = as.numeric(.data$cl_1_height),
      cl_1_height = ifelse(.data$cl_1_height == 99999, NA, .data$cl_1_height)
    )
  }

  if ("GA2" %in% names(met_data)) {
    met_data <- tidyr::separate(
      data = met_data,
      col = "GA2",
      into = c(
        "cl_2",
        "code_1",
        "cl_2_height",
        "code_2",
        "cl_2_type",
        "code_3"
      ),
      sep = ","
    )

    met_data <- dplyr::mutate(
      met_data,
      cl_2 = as.numeric(.data$cl_2),
      cl_2 = ifelse(.data$cl_2 == 99, NA, .data$cl_2),
      cl_2_height = as.numeric(.data$cl_2_height),
      cl_2_height = ifelse(.data$cl_2_height == 99999, NA, .data$cl_2_height)
    )
  }

  if ("GA3" %in% names(met_data)) {
    met_data <- tidyr::separate(
      data = met_data,
      col = "GA3",
      into = c(
        "cl_3",
        "code_1",
        "cl_3_height",
        "code_2",
        "cl_3_type",
        "code_3"
      ),
      sep = ","
    )

    met_data <- dplyr::mutate(
      met_data,
      cl_3 = as.numeric(.data$cl_3),
      cl_3 = ifelse(.data$cl_3 == 99, NA, .data$cl_3),
      cl_3_height = as.numeric(.data$cl_3_height),
      cl_3_height = ifelse(.data$cl_3_height == 99999, NA, .data$cl_3_height)
    )
  }

  ## for cloud cover, make new 'cl' max of 3 cloud layers
  if ("cl_3" %in% names(met_data)) {
    met_data$cl <- pmax(
      met_data$cl_1,
      met_data$cl_2,
      met_data$cl_3,
      na.rm = TRUE
    )
  }

  # PRECIP AA1
  if ("AA1" %in% names(met_data)) {
    met_data <- tidyr::separate(
      data = met_data,
      col = "AA1",
      into = c("precip_code", "precip_raw", "code_1", "code_2"),
      sep = ","
    )

    met_data <- dplyr::mutate(
      met_data,
      precip_raw = as.numeric(.data$precip_raw),
      precip_raw = ifelse(.data$precip_raw == 9999, NA, .data$precip_raw),
      precip_raw = .data$precip_raw / 10
    )

    # deal with 6 and 12 hour precip
    id <- which(met_data$precip_code == "06")

    if (length(id) > 0) {
      met_data$precip_6 <- NA
      met_data$precip_6[id] <- met_data$precip_raw[id]
    }

    id <- which(met_data$precip_code == "12")

    if (length(id) > 0) {
      met_data$precip_12 <- NA
      met_data$precip_12[id] <- met_data$precip_raw[id]
    }
  }

  # weather codes, AW1

  if ("AW1" %in% names(met_data)) {
    met_data <- tidyr::separate(
      data = met_data,
      col = "AW1",
      into = c("pwc", "code_1"),
      sep = ",",
      fill = "right"
    )

    met_data <- dplyr::left_join(met_data, worldmet::weatherCodes, by = "pwc")
    met_data <- dplyr::select(met_data, -"pwc") |>
      dplyr::rename(pwc = "description")
  }

  ## select the variables we want
  met_data <- dplyr::select(
    met_data,
    dplyr::any_of(c(
      "date",
      "code",
      "station",
      "latitude",
      "longitude",
      "elev",
      "ws",
      "wd",
      "air_temp",
      "atmos_pres",
      "visibility",
      "dew_point",
      "RH",
      "ceil_hgt",
      "cl_1",
      "cl_2",
      "cl_3",
      "cl",
      "cl_1_height",
      "cl_2_height",
      "cl_3_height",
      "pwc",
      "precip_12",
      "precip_6",
      "precip"
    ))
  )

  ## present weather is character and cannot be averaged, take first
  if ("pwc" %in% names(met_data) && hourly) {
    pwc <- met_data[c("date", "pwc")]
    pwc$date2 <- format(pwc$date, "%Y-%m-%d %H") ## nearest hour
    tmp <- pwc[which(!duplicated(pwc$date2)), ]
    dates <- as.POSIXct(paste0(unique(pwc$date2), ":00:00"), tz = "GMT")

    pwc <- data.frame(date = dates, pwc = tmp$pwc)
  }

  ## average to hourly
  if (hourly) {
    met_data <-
      worldmet_time_average(
        met_data,
        avg.time = "hour",
        type = c("code", "station")
      )
  }

  ## add pwc back in
  if (exists("pwc")) {
    met_data <- dplyr::left_join(met_data, pwc, by = "date")
  }

  ## add precipitation - based on 12 HOUR averages, so work with hourly data

  ## spread out precipitation across each hour

  ## only do this if precipitation exists
  if ("precip_12" %in% names(met_data) && hourly) {
    ## make new precip variable
    met_data$precip <- NA

    ## id where there is 12 hour data
    id <- which(!is.na(met_data$precip_12))

    if (length(id) == 0L) {
      return()
    }

    id <- id[id > 11] ## make sure we don't run off beginning

    for (i in seq_along(id)) {
      met_data$precip[(id[i] - 11):id[i]] <- met_data$precip_12[id[i]] / 12
    }
  }

  # replace NaN with NA
  met_data[] <- lapply(met_data, function(x) {
    replace(x, is.nan(x), NA)
  })

  return(dplyr::as_tibble(met_data))
}

#' 'Fixed width file' helpers.
#' @noRd
getDatFwf <- function(code, year, hourly, precip, PWC) {
  procAdditFwf <- function(add, dat, precip, PWC) {
    # function to process additional data such as cloud cover

    # consider first 3 layers of cloud GA1, GA2, GA3
    dat <- extractCloudFwf(add, dat, "GA1", "cl_1")
    dat <- extractCloudFwf(add, dat, "GA2", "cl_2")
    dat <- extractCloudFwf(add, dat, "GA3", "cl_3")

    # 6 and 12 hour precipitation
    if (precip) {
      dat <- extractPrecipFwf(add, dat, "AA112", "precip_12")
      dat <- extractPrecipFwf(add, dat, "AA106", "precip_6")
    }

    if (PWC) {
      dat <- extractCurrentWeatherFwf(add, dat, "AW1")
    }

    return(dat)
  }

  extractPrecipFwf <- function(add, dat, field = "AA112", out = "precip_12") {
    # fields that contain search string
    id <- grep(field, add)

    # variables for precip amount
    dat[[out]] <- NA

    if (length(id) > 1) {
      # location of begining of AA1 etc

      loc <- sapply(id, function(x) regexpr(field, add[x]))

      # extract amount of rain

      amnt <- sapply(seq_along(id), function(x) {
        substr(add[id[x]], start = loc[x] + 5, stop = loc[x] + 8)
      })

      miss <- which(amnt == "9999") # missing
      if (length(miss) > 0) {
        amnt[miss] <- NA
      }

      amnt <- as.numeric(amnt) / 10

      dat[[out]][id] <- amnt
    }

    return(dat)
  }

  extractCloudFwf <- function(add, dat, field = "GA1", out = "cl_1") {
    # 3 fields are used: GA1, GA2 and GA3

    height <- paste0(out, "_height") # cloud height field

    # fields that contain search string
    id <- grep(field, add)

    # variables for cloud amount (oktas) and cloud height
    dat[[out]] <- NA
    dat[[height]] <- NA

    if (length(id) > 1) {
      # location of begining of GA1 etc

      loc <- sapply(id, function(x) regexpr(field, add[x]))

      # extract the variable
      cl <- sapply(seq_along(id), function(x) {
        substr(add[id[x]], start = loc[x] + 3, stop = loc[x] + 4)
      })
      cl <- as.numeric(cl)

      miss <- which(cl == 99) # missing

      if (length(miss) > 0) {
        cl[miss] <- NA
      }

      # and height of cloud
      h <- sapply(seq_along(id), function(x) {
        substr(add[id[x]], start = loc[x] + 6, stop = loc[x] + 11)
      })
      h <- as.numeric(h)

      miss <- which(h == 99999)
      if (length(miss) > 0) {
        h[miss] <- NA
      }

      dat[[out]][id] <- cl
      dat[[height]][id] <- h
    }

    return(dat)
  }

  extractCurrentWeatherFwf <- function(add, dat, field = "AW1") {
    # fields that contain search string
    id <- grep(field, add)

    if (length(id) > 1) {
      # name of output variable
      dat[["pwc"]] <- NA

      # location of begining of AW1
      loc <- sapply(id, function(x) regexpr(field, add[x]))

      # extract the variable
      pwc <- sapply(seq_along(id), function(x) {
        substr(add[id[x]], start = loc[x] + 3, stop = loc[x] + 4)
      })
      pwc <- as.character(pwc)

      # look up code in weatherCodes.RData

      desc <- sapply(pwc, function(x) {
        weatherCodes$description[which(weatherCodes$pwc == x)]
      })

      dat[["pwc"]][id] <- desc
    } else {
      return(dat)
    }

    return(dat)
  }

  weatherCodes <- worldmet::weatherCodes

  # location of data
  file.name <- paste0(
    "https://www1.ncdc.noaa.gov/pub/data/noaa/",
    year,
    "/",
    code,
    "-",
    year,
    ".gz"
  )

  # Download file to temp directory
  tmp <- paste0(tempdir(), basename(file.name))

  # deal with any missing data, issue warning
  bin <- try(utils::download.file(file.name, tmp, quiet = TRUE, mode = "wb"))

  if (inherits(bin, "try-error")) {
    return(NULL)
  }

  column_widths <- c(
    4,
    6,
    5,
    4,
    2,
    2,
    2,
    2,
    1,
    6,
    7,
    5,
    5,
    5,
    4,
    3,
    1,
    1,
    4,
    1,
    5,
    1,
    1,
    1,
    6,
    1,
    1,
    1,
    5,
    1,
    5,
    1,
    5,
    1
  )

  # mandatory fields, fast read
  dat <- readr::read_fwf(
    tmp,
    readr::fwf_widths(column_widths),
    col_types = "ccciiiiicccccccicciccccccccccccccc"
  )

  # additional fields, variable length, need to read eveything
  add <- readLines(tmp)

  # Remove select columns from data frame
  dat <- dat[, c(2:8, 10:11, 13, 16, 19, 21, 25, 29, 31, 33)]

  # Apply new names to the data frame columns
  names(dat) <- c(
    "usaf",
    "wban",
    "year",
    "month",
    "day",
    "hour",
    "minute",
    "latitude",
    "longitude",
    "elev",
    "wd",
    "ws",
    "ceil_hgt",
    "visibility",
    "air_temp",
    "dew_point",
    "atmos_pres"
  )

  # Correct the latitude values
  dat$latitude <- as.numeric(dat$latitude) / 1000

  # Correct the longitude values
  dat$longitude <- as.numeric(dat$longitude) / 1000

  # Correct the elevation values
  dat$elev <- as.numeric(dat$elev)

  # Correct the wind direction values
  dat$wd <-
    ifelse(dat$wd == 999, NA, dat$wd)

  # Correct the wind speed values
  dat$ws <-
    ifelse(dat$ws == 9999, NA, dat$ws / 10)

  # Correct the temperature values
  dat$air_temp <- as.numeric(dat$air_temp)
  dat$air_temp <- ifelse(dat$air_temp == 9999, NA, dat$air_temp / 10)

  # Correct the visibility values
  dat$visibility <- as.numeric(dat$visibility)
  dat$visibility <- ifelse(
    dat$visibility %in% c(9999, 999999),
    NA,
    dat$visibility
  )

  # Correct the dew point values
  dat$dew_point <- as.numeric(dat$dew_point)
  dat$dew_point <- ifelse(dat$dew_point == 9999, NA, dat$dew_point / 10)

  # Correct the atmospheric pressure values
  dat$atmos_pres <- as.numeric(dat$atmos_pres)
  dat$atmos_pres <- ifelse(dat$atmos_pres == 99999, NA, dat$atmos_pres / 10)

  # Correct the ceiling height values
  dat$ceil_hgt <- as.numeric(dat$ceil_hgt)
  dat$ceil_hgt <- ifelse(dat$ceil_hgt == 99999, NA, dat$ceil_hgt)

  # relative humidity - general formula based on T and dew point
  dat$RH <- 100 *
    ((112 - 0.1 * dat$air_temp + dat$dew_point) /
      (112 + 0.9 * dat$air_temp))^8

  dat$date <- ISOdatetime(
    dat$year,
    dat$month,
    dat$day,
    dat$hour,
    dat$minute,
    0,
    tz = "GMT"
  )

  # drop date components that are not needed
  dat <- dplyr::select(
    dat,
    -dplyr::all_of(c("year", "month", "day", "hour", "minute"))
  )

  # process the additional data separately
  dat <- procAdditFwf(add, dat, precip, PWC)

  # for cloud cover, make new 'cl' max of 3 cloud layers
  dat$cl <- pmax(dat$cl_1, dat$cl_2, dat$cl_3, na.rm = TRUE)

  # additional condition, when ceil_height = 22000 and cl_1 is NA, assume no cloud
  dat <- dat |>
    dplyr::mutate(
      cl = ifelse(
        (is.na(.data$cl_1) & .data$ceil_hgt == 22000),
        0,
        .data$cl
      ),
      cl_1 = ifelse(
        (is.na(.data$cl_1) & .data$ceil_hgt == 22000),
        0,
        .data$cl_1
      )
    )

  # select the variables we want
  dat <- dat[
    names(dat) %in%
      c(
        "date",
        "usaf",
        "wban",
        "station",
        "ws",
        "wd",
        "air_temp",
        "atmos_pres",
        "visibility",
        "dew_point",
        "RH",
        "ceil_hgt",
        "latitude",
        "longitude",
        "elev",
        "cl_1",
        "cl_2",
        "cl_3",
        "cl",
        "cl_1_height",
        "cl_2_height",
        "cl_3_height",
        "pwc",
        "precip_12",
        "precip_6"
      )
  ]

  # present weather is character and cannot be averaged, take first
  if ("pwc" %in% names(dat) && hourly) {
    pwc <- dat[c("date", "pwc")]
    pwc$date2 <- format(pwc$date, "%Y-%m-%d %H") # nearest hour
    tmp <- pwc[which(!duplicated(pwc$date2)), ]
    dates <- as.POSIXct(paste0(unique(pwc$date2), ":00:00"), tz = "GMT")

    pwc <- data.frame(date = dates, pwc = tmp$pwc)
    PWC <- TRUE
  }

  # average to hourly
  if (hourly) {
    dat <- worldmet_time_average(
      dat,
      avg.time = "hour",
      type = c("usaf", "wban")
    )
  }

  # add precipitation
  if (precip) {
    # spread out precipitation across each hour
    # met data gives 12 hour total and every other 6 hour total

    # only do this if precipitation exists
    if (all(c("precip_6", "precip_12") %in% names(dat))) {
      # make new precip variable
      dat$precip <- NA

      # id where there is 6 hour data
      id <- which(!is.na(dat$precip_6))
      id <- id[id < (nrow(dat) - 6)] # make sure we don't run off end

      # calculate new 6 hour based on 12 hr total - 6 hr total
      dat$precip_6[id + 6] <- dat$precip_12[id + 6] - dat$precip_6[id]

      # ids for new 6 hr totals
      id <- which(!is.na(dat$precip_6))
      id <- id[id > 6]

      # Divide 6 hour total over each of 6 hours
      for (i in seq_along(id)) {
        dat$precip[(id[i] - 5):id[i]] <- dat$precip_6[id[i]] / 6
      }
    }
  }

  # return other meta data
  meta <- getMeta(returnMap = FALSE, plot = FALSE, end.year = "all")
  info <- meta[meta$code == code, ]

  dat$station <- as.character(info$station)
  dat$latitude <- info$latitude
  dat$longitude <- info$longitude
  dat$elev <- info$`elev(m)`
  dat$code <- code

  # rearrange columns, one to move to front
  move <- c("date", "code", "station")
  dat <- dat[c(move, setdiff(names(dat), move))]

  # replace NaN with NA
  dat <- dplyr::mutate(
    dat,
    dplyr::across(dplyr::everything(), \(x) dplyr::if_else(is.nan(x), NA, x))
  )

  # reorder to match delimited data
  dat <-
    dplyr::relocate(
      dat,
      dplyr::any_of(
        c(
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
          "visibility",
          "dew_point",
          "RH",
          "ceil_hgt",
          "cl_1",
          "cl_2",
          "cl_3",
          "cl",
          "cl_1_height",
          "cl_2_height",
          "cl_3_height",
          "precip_12",
          "precip_6",
          "pwc",
          "precip"
        )
      )
    )

  return(dplyr::tibble(dat))
}
