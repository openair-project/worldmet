#' Export a meteorological data frame in ADMS format
#'
#' Writes a text file in the ADMS format to a location of the user's choosing,
#' with optional interpolation of missing values. At present this function only
#' works with data from [import_isd_hourly()]; it will later be expanded to work
#' with [import_ghcn_hourly()] also.
#'
#' @param x A data frame imported by [import_isd_hourly()].
#'
#' @param file A file name for the ADMS file. The file is written to the working
#'   directory by default.
#'
#' @param interp Should interpolation of missing values be undertaken? If `TRUE`
#'   linear interpolation is carried out for gaps of up to and including
#'   `max_gap`.
#'
#' @param max_gap The maximum gap in hours that should be interpolated where
#'   there are missing data when `interp = TRUE.` Data with gaps more than
#'   `max_gap` are left as missing.
#'
#' @return `write_adms()` returns the input `dat` invisibly.
#' @family Met writing functions
#' @export
#' @examples
#' \dontrun{
#' # import some data then export it
#' dat <- import_isd_hourly(year = 2012)
#' write_adms(dat, file = "~/adms_met.MET")
#' }
write_adms <- function(
  x,
  file = "./ADMS_met.MET",
  interp = FALSE,
  max_gap = 2
) {
  # save input for later
  input <- dat <- x

  # make sure the data do not have gaps
  all.dates <- data.frame(
    date = seq(
      ISOdatetime(
        year = as.numeric(format(dat$date[1], "%Y")),
        month = 1,
        day = 1,
        hour = 0,
        min = 0,
        sec = 0,
        tz = "GMT"
      ),
      ISOdatetime(
        year = as.numeric(format(dat$date[1], "%Y")),
        month = 12,
        day = 31,
        hour = 23,
        min = 0,
        sec = 0,
        tz = "GMT"
      ),
      by = "hour"
    )
  )

  dat <- merge(dat, all.dates, all = TRUE)

  # make sure precipitation is available
  if (!"precip" %in% names(dat)) {
    dat$precip <- NA
  }

  if (interp) {
    varInterp <- c("ws", "u", "v", "air_temp", "RH", "cl")

    # transform wd
    dat <- dplyr::mutate(
      dat,
      u = sin(pi * .data$wd / 180),
      v = cos(pi * .data$wd / 180)
    )

    for (variable in varInterp) {
      # if all missing, then don't interpolate
      if (all(is.na(dat[[variable]]))) {
        return()
      }

      # first fill with linear interpolation
      filled <- stats::approx(
        dat$date,
        dat[[variable]],
        xout = dat$date,
        na.rm = TRUE,
        rule = 2,
        method = "linear"
      )$y

      # find out length of missing data
      is_missing <- rle(is.na(dat[[variable]]))

      is_missing <- rep(
        ifelse(is_missing$values, is_missing$lengths, 0),
        times = is_missing$lengths
      )

      id <- which(is_missing > max_gap)

      # update data frame
      dat[[variable]] <- filled
      dat[[variable]][id] <- NA
    }

    dat <- dplyr::mutate(
      dat,
      wd = as.vector(atan2(.data$u, .data$v) * 360 / 2 / pi)
    )

    # correct for negative wind directions
    ids <- which(dat$wd < 0) ## ids where wd < 0
    dat$wd[ids] <- dat$wd[ids] + 360

    dat <- dplyr::select(dat, -"v", -"u")
  }

  # exports met data to ADMS format file
  year <- as.numeric(format(dat$date, "%Y"))
  day <- as.numeric(format(dat$date, "%j"))
  hour <- as.numeric(format(dat$date, "%H"))
  station <- "0000"

  # check if present
  if (!"cl" %in% names(dat)) {
    dat$cl <- NA
  }
  if (!"precip" %in% names(dat)) {
    dat$precip <- NA
  }

  # data frame of met data needed
  adms <- data.frame(
    station,
    year,
    day,
    hour,
    round(dat$air_temp, 1),
    round(dat$ws, 1),
    round(dat$wd, 1),
    round(dat$RH, 1),
    round(dat$cl),
    round(dat$precip, 1),
    stringsAsFactors = FALSE
  )

  # message key data capture rates
  calc_dc <- function(x) {
    round(100 * mean(!is.na(x)), 1)
  }
  cli::cli_inform(
    c(
      "i" = "Data capture for {.strong wind speed}: {calc_dc(dat$ws)}%",
      "i" = "Data capture for {.strong wind direction}: {calc_dc(dat$wd)}%",
      "i" = "Data capture for {.strong temperature}: {calc_dc(dat$air_temp)}%",
      "i" = "Data capture for {.strong cloud cover}: {calc_dc(dat$cl)}%"
    )
  )

  # replace NA with -999
  adms[] <- lapply(adms, function(x) replace(x, is.na(x), -999))

  # write the data file
  utils::write.table(
    adms,
    file = out,
    col.names = FALSE,
    row.names = FALSE,
    sep = ",",
    quote = FALSE
  )

  # add the header lines
  fConn <- file(out, "r+")
  Lines <- readLines(fConn)
  writeLines(
    c(
      "VARIABLES:\n10\nSTATION DCNN\nYEAR\nTDAY\nTHOUR\nT0C\nU\nPHI\nRHUM\nCL\nP\nDATA:",
      Lines
    ),
    con = fConn
  )
  close(fConn)

  # return input invisibly
  invisible(input)
}
