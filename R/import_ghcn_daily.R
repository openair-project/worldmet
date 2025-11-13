#' Import data from the Global Historical Climatology daily (GHCNd) database
#'
#' This function flexibly accesses meteorological data from the GHCNd database.
#' Users can provide any of stations, and control whether attribute codes are
#' returned with the data.
#'
#' @inheritSection import_ghcn_hourly Parallel Processing
#' @inheritParams import_ghcn_hourly
#'
#' @param append_codes Logical. Should attribute codes be appended to the output
#'   dataframe?
#'
#' @author Jack Davison
#' @family GHCN functions
#'
#' @return a [tibble][tibble::tibble-package]
#' @export
import_ghcn_daily <- function(
  station,
  append_codes = FALSE,
  progress = rlang::is_interactive()
) {
  # import data
  data <-
    purrr::map(
      .x = station,
      .f = purrr::in_parallel(\(x) {
        data <- try(
          suppressWarnings(
            readr::read_csv(
              paste0(
                "https://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/",
                x,
                ".csv"
              ),
              name_repair = tolower,
              show_col_types = FALSE,
              progress = FALSE
            )
          ),
          silent = TRUE
        )

        if (class(data)[1] == "try-error") {
          return(NULL)
        }

        return(data)
      }),
      .progress = progress
    ) |>
    dplyr::bind_rows()

  # if null, leave early
  if (is.null(data) || nrow(data) == 0L) {
    cli::cli_warn("No data has been returned.")
    return(NULL)
  }

  # sort out names
  data <-
    data |>
    dplyr::rename(
      station_id = "station",
      station_name = "name",
      lat = "latitude",
      lng = "longitude",
      elev = "elevation"
    ) |>
    dplyr::relocate(
      "station_name",
      .after = "station_id"
    )

  if (!append_codes) {
    data <- dplyr::select(data, -dplyr::ends_with("attributes"))
  } else {
    data <- tidyr::separate_wider_delim(
      data,
      dplyr::ends_with("_attributes"),
      delim = ",",
      names_sep = "_",
      names = c("mf", "qf", "sf")
    ) |>
      dplyr::rename_with(\(x) gsub("_attributes_", "_", x))
  }

  # deal with "tenths of" from documentation
  # https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt
  for (i in c(
    "prcp",
    "tmax",
    "tmin",
    "adpt",
    "awbt",
    "awnd",
    "evap",
    "mdev",
    "mdpr",
    "mdtn",
    "mdtx",
    "mnpn",
    "mxpn",
    "taxn",
    "tavg",
    "thic",
    "tobs",
    "wesd",
    "wesf",
    "wsf1",
    "wsf2",
    "wsf5",
    "wsfg",
    "wsfi",
    "wsfm"
  )) {
    if (i %in% names(data)) {
      data[i] <- data[[i]] / 10
    }
  }

  # soil could be lots of things
  soil_names <- names(data)[
    startsWith(names(data), "sn") &
      nchar(names(data)) == 4 &
      !names(data) %in% c("snwd", "snow")
  ]
  if (length(soil_names) > 1) {
    for (i in soil_names) {
      data[i] <- data[[i]] / 10
    }
  }

  return(data)
}
