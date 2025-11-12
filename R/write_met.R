#' Export a meteorological data frame in files, chunked by site and year
#'
#' Writes a text file in the ADMS format to a location of the user's choosing,
#' with optional interpolation of missing values. At present this function only
#' works with data from [import_isd_hourly()]; it will later be expanded to work
#' with [import_ghcn_hourly()] also.
#'
#' @param x A data frame imported by [import_isd_hourly()],
#'   [import_ghcn_hourly()], or [import_ghcn_daily()].
#'
#' @param path The path to a directory to save each file. By default, this is
#'   the working directory.
#'
#' @param ext The file type to use when saving the data. Can be `"rds"`,
#'   `"delim"` or `"parquet"`. Note that `"parquet"` requires the `arrow`
#'   package.
#'
#' @param delim Delimiter used to separate values when `ext = "delim"`. Must be
#'   a single character. Defaults to being comma-delimited (`","`).
#'
#' @param suffix An additional suffix to append to file names. Useful examples
#'   could be `"_ISD"`, `"_hourly"`, `"_lite"`, and so on.
#'
#' @param progress Show a progress bar when writing many stations/years?
#'   Defaults to `TRUE` in interactive R sessions. Passed to `.progress` in
#'   [purrr::walk()].
#'
#' @return `write_met()` returns `path` invisibly.
#' @family Met writing functions
#' @export
#' @examples
#' \dontrun{
#' # import some data then export it
#' dat <- import_isd_hourly(year = 2012)
#' write_met(dat)
#' }
write_met <- function(
  x,
  path = ".",
  ext = c("rds", "delim", "parquet"),
  delim = ",",
  suffix = "",
  progress = rlang::is_interactive()
) {
  ext <- rlang::arg_match(ext, c("rds", "delim", "parquet"))

  # error if path doesn't exist
  if (!dir.exists(path)) {
    cli::cli_abort("Directory does not exist; file not saved.", call. = FALSE)
  }

  # find the ID column for the data
  if ("id" %in% names(x)) {
    id_col <- "id"
  } else if ("station_id" %in% names(x)) {
    id_col <- "station_id"
  } else if ("code" %in% names(x)) {
    id_col <- "code"
  } else {
    cli::cli_abort(
      c(
        "x" = "Data not recognised.",
        "i" = "Did you access it via {.fun worldmet::import_isd_hourly}, {.fun worldmet::import_ghcn_hourly}, or {.fun worldmet::import_ghcn_daily}?"
      )
    )
  }

  # save as year / site files
  write_met_helper <- function(x) {
    filepath <- paste0(
      path,
      "/",
      unique(x[[id_col]]),
      "_",
      unique(x$year),
      suffix,
      ".",
      ext
    )

    if (ext == "rds") {
      saveRDS(x, filepath)
    }

    if (ext == "csv") {
      readr::write_delim(x, filepath)
    }

    if (ext == "parquet") {
      rlang::check_installed("arrow")
      arrow::write_parquet(x, filepath)
    }
  }

  x |>
    dplyr::mutate(year = format(.data$date, "%Y")) |>
    (\(df) split(df, df[c(id_col, "year")]))() |>
    purrr::walk(.f = write_met_helper, .progress = progress)

  invisible(path)
}
