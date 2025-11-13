#' Import data from the Global Historical Climatology monthly (GHCNm) database
#'
#' This function is a convenient way to access the monthly summaries of the
#' GHCN. Monthly average temperature is available via
#' [import_ghcn_monthly_temp()] and monthly precipitation via
#' [import_ghcn_monthly_prcp()]. Note that these functions can take a few
#' minutes to run.
#'
#' @inheritParams import_ghcn_daily
#'
#' @param table Either `"inventory"`, `"data"`, or both. The tables to read and
#'   return in the output list.
#'
#' @param dataset For [import_ghcn_monthly_temp()]. One of the below options.
#'   More information is available at
#'   <https://www.ncei.noaa.gov/pub/data/ghcn/v4/readme.txt>.
#'
#' - `"qcu"`: Quality Control, Unadjusted
#'
#' - `"qcf"`: Quality Control, Adjusted, using the Pairwise Homogeneity
#'   Algorithm.
#'
#' - `"qfe"`: Quality Control, Adjusted, Estimated using the Pairwise
#'   Homogeneity Algorithm. Only the years 1961-2010 are provided. This is to
#'   help maximize station coverage when calculating normals.
#'
#' @param station For [import_ghcn_monthly_prcp()]. The specific stations to
#'   import monthly precipitation data for.
#'
#' @param progress For [import_ghcn_monthly_prcp()]. Show a progress bar when
#'   importing many stations? Defaults to `TRUE` in interactive R sessions.
#'   Passed to `.progress` in [purrr::map()].
#'
#' @author Jack Davison
#' @family GHCN functions
#'
#' @rdname import_ghcn_monthly
#' @return a list of [tibbles][tibble::tibble-package]
#' @export
import_ghcn_monthly_temp <- function(
  table = c("inventory", "data"),
  dataset = c("qcu", "qcf", "qfe")
) {
  # id temporary directory to download into
  tdir <- tempdir()
  folder <- paste0(
    "ghcnm_",
    gsub("\\.", "_", as.character(as.numeric(Sys.time())))
  )
  dir.create(file.path(tdir, folder))

  # ensure dataset is correct
  dataset <- rlang::arg_match(dataset, c("qcu", "qcf", "qfe"))
  table <- rlang::arg_match(table, c("inventory", "data"), multiple = TRUE)

  # download file into temporary dir
  utils::download.file(
    paste0(
      "https://www.ncei.noaa.gov/pub/data/ghcn/v4/ghcnm.tavg.latest.",
      dataset,
      ".tar.gz"
    ),
    destfile = file.path(
      tdir,
      folder,
      "out.tar.gz"
    )
  )

  # untar it
  utils::untar(
    file.path(tdir, folder, "out.tar.gz"),
    exdir = file.path(tdir, folder)
  )

  # get the file that's been extracted
  files <- dir(file.path(tdir, folder), full.names = TRUE)
  files <- files[!grepl("out.tar.gz", files)]
  files <- dir(files, full.names = TRUE)

  out <- list()

  if ("data" %in% table) {
    # get month names for columns
    monthnames <- c()
    for (i in month.abb) {
      monthnames <- c(
        monthnames,
        paste0(i, c("_value", "_dmf", "_qcf", "_dsf"))
      )
    }
    monthnames <- tolower(monthnames)

    # read data file
    dat <-
      readr::read_fwf(
        files[grepl("dat", files)],
        col_positions = readr::fwf_widths(c(
          11,
          4,
          4,
          rep(c(5, 1, 1, 1), 12)
        )),
        na = "-9999",
        show_col_types = FALSE
      ) |>
      stats::setNames(
        c(
          "station_id",
          "year",
          "element",
          monthnames
        )
      ) |>
      dplyr::mutate(
        dplyr::across(dplyr::ends_with("_value"), \(x) x / 100),
        dplyr::across(dplyr::ends_with("_dmf|_qcf|_dsf"), as.character)
      )

    out <- append(out, list(data = dat))
  }

  if ("inventory" %in% table) {
    # read inventory file
    inv <-
      readr::read_fwf(
        files[grepl("inv", files)],
        col_positions = readr::fwf_cols(
          station_id = c(1, 11),
          lat = c(13, 20),
          lng = c(22, 30),
          elev = c(32, 37),
          station_name = c(39, 68)
        ),
        show_col_types = FALSE
      )

    out <- append(out, list(inventory = inv))
  }

  return(out)
}

#' @rdname import_ghcn_monthly
#' @export
import_ghcn_monthly_prcp <- function(
  station = NULL,
  year = NULL,
  table = c("inventory", "data"),
  progress = rlang::is_interactive()
) {
  table <- rlang::arg_match(table, c("inventory", "data"), multiple = TRUE)

  out <- list()

  if ("data" %in% table) {
    # read data
    data <-
      purrr::map(
        .x = station,
        .f = purrr::possibly(
          \(x) {
            suppressWarnings({
              readr::read_csv(
                paste0(
                  "https://www.ncei.noaa.gov/data/ghcnm/v4/precipitation/access/",
                  station,
                  ".csv"
                ),
                col_names = c(
                  "station_id",
                  "station_name",
                  "lat",
                  "lng",
                  "elev",
                  "yearmon",
                  "precip",
                  "meas_flag",
                  "qc_flag",
                  "src_flag",
                  "src_index"
                ),
                show_col_types = FALSE,
                progress = FALSE
              )
            })
          }
        ),
        .progress = progress
      ) |>
      dplyr::bind_rows()

    if (is.null(data) || nrow(data) == 0L) {
      cli::cli_warn("No data has been returned.")
    } else {
      data <- data |>
        dplyr::mutate(
          year = substr(.data$yearmon, 1, 4),
          month = substr(.data$yearmon, 5, 6),
          date = ISOdate(.data$year, .data$month, 1, hour = 0) |> as.Date(),
          precip = .data$precip * 0.1,
          .keep = "unused"
        ) |>
        dplyr::relocate("date", "year", "month", .before = "precip")
    }

    out <- append(out, list(data = data))
  }

  if ("inventory" %in% table) {
    # get inventory
    inv_lines <- readr::read_lines(
      "https://www.ncei.noaa.gov/data/ghcnm/v4/precipitation/doc/ghcn-m_v4_prcp_inventory.txt",
      progress = FALSE
    )

    inv <-
      readr::read_fwf(
        I(inv_lines),
        col_positions = readr::fwf_cols(
          station_id = c(1, 11),
          lat = c(13, 20),
          lng = c(22, 30),
          elev = c(32, 37),
          state = c(39, 40),
          station_name = c(42, 79),
          wmo_id = c(81, 85),
          start = c(87, 90),
          end = c(92, 95)
        ),
        na = c("-999.9"),
        show_col_types = FALSE
      )

    out <- append(out, list(inventory = inv))
  }

  if (!is.null(year)) {
    data <- dplyr::filter(
      data,
      as.numeric(format(.data$date, "%Y")) %in% year
    )

    if (nrow(data) == 0L) {
      cli::cli_warn("No data has been returned. Check {.arg year}.")
      return(NULL)
    }
  }

  return(out)
}
