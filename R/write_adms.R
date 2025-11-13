#' Export a meteorological data frame in ADMS format
#'
#' Writes a text file in the ADMS format to a location of the user's choosing,
#' with optional interpolation of missing values. This function works with data
#' from both [import_ghcn_hourly()] and [import_isd_hourly()].
#'
#' @param x A data frame imported by [import_ghcn_hourly()] or
#'   [import_isd_hourly()].
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
#' @family ADMS functions
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
  input <- x

  # ensure all data is lowercase - difference between ISD & GHCN
  dat <- dplyr::rename_with(x, .fn = tolower)

  # make sure the data do not have gaps
  all_dates <- dplyr::tibble(
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

  # complete dataset
  dat <- dplyr::left_join(all_dates, dat, by = dplyr::join_by("date"))

  # interpolate if requested
  if (interp) {
    var_interp <- c("ws", "u", "v", "air_temp", "rh", "cl")

    # transform wd
    dat <- dplyr::mutate(
      dat,
      u = sin(pi * .data$wd / 180),
      v = cos(pi * .data$wd / 180)
    )

    for (variable in var_interp) {
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

  # check if present
  if (!"cl" %in% names(dat)) {
    dat$cl <- NA
  }
  if (!"precip" %in% names(dat)) {
    dat$precip <- NA
  }

  # reformat for ADMS output
  adms <-
    dat |>
    # select needed variables
    dplyr::transmute(
      station = "0000",
      year = as.numeric(format(.data$date, "%Y")),
      day = as.numeric(format(.data$date, "%j")),
      hour = as.numeric(format(.data$date, "%H")),
      air_temp = round(.data$air_temp, 1),
      ws = round(.data$ws, 1),
      wd = round(.data$wd, 1),
      rh = round(.data$rh, 1),
      cl = round(.data$cl, 0),
      precip = round(.data$precip, 1)
    ) |>
    # replace NA with -999
    dplyr::mutate(
      dplyr::across(
        dplyr::where(is.numeric),
        \(x) tidyr::replace_na(x, -999)
      )
    )

  # message key data capture rates
  calc_dc <- function(x) {
    round(100 * mean(x != -999), 1)
  }
  cli::cli_inform(
    c(
      "i" = "Data capture for {.strong wind speed}: {calc_dc(adms$ws)}%",
      "i" = "Data capture for {.strong wind direction}: {calc_dc(adms$wd)}%",
      "i" = "Data capture for {.strong temperature}: {calc_dc(adms$air_temp)}%",
      "i" = "Data capture for {.strong cloud cover}: {calc_dc(adms$cl)}%"
    )
  )

  # write the data file
  utils::write.table(
    adms,
    file = file,
    col.names = FALSE,
    row.names = FALSE,
    sep = ",",
    quote = FALSE
  )

  # add the header lines
  fConn <- file(file, "r+")
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

#' Read a file in ADMS format
#'
#' This function reads a file in ADMS format (e.g., a file written by
#' [write_adms()]) as an R `data.frame`. This could be useful to check or
#' analyse ADMS files before they are used.
#'
#' @param file One or more file paths to ADMS `.MET` files. If multiple files
#'   are specified, they will be bound together into a single `data.frame`.
#'
#' @param progress Show a progress bar when reading many files? Defaults to
#'   `TRUE` in interactive R sessions. Passed to `.progress` in [purrr::map()].
#'
#' @author Jack Davison
#' @family ADMS functions
#'
#' @export
read_adms <- function(file, progress = rlang::is_interactive()) {
  read_adms_helper <- function(x) {
    lines <- readr::read_lines(x)

    var_line <- which(lines == "VARIABLES:")
    dat_line <- which(lines == "DATA:")

    headers <- lines[(var_line + 2):(dat_line - 1)]
    headers <- gsub(" ", "_", tolower(headers))

    readr::read_csv(
      I(lines[(dat_line + 1):length(lines)]),
      col_names = headers,
      na = "-999",
      show_col_types = FALSE
    )
  }

  purrr::map(
    .x = file,
    .f = read_adms_helper,
    .progress = progress
  ) |>
    dplyr::bind_rows()
}
