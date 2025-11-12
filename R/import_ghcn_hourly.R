#' Import data from the Global Historical Climatology hourly (GHCNh) database
#'
#' This function flexibly accesses meteorological data from the GHCNh database.
#' Users can provide any number of years and stations, and fully control the
#' sorts of data flag codes that are returned with the data. By default, column
#' names are shortened for easier use in R, but longer, more descriptive names
#' can be requested.
#'
#' @param station One or more site codes for the station(s) of interest,
#'   obtained using [import_ghcn_stations()].
#'
#' @param year One or more years of interest. If `NULL`, the default, all years
#'   of data available for the chosen `station`s will be imported.
#'
#' @param source There are two identical data formats to read from - `"psv"`
#'   (flat, pipe-delimited files) and `"parquet"` (a newer, faster, columnar
#'   format). The latter is typically faster, but requires the `arrow` package
#'   as an additional dependency. Note that this only applies when `year` is not
#'   `NULL`; all `by-site` files are `psv` files.
#'
#' @param abbr_names Should column names be abbreviated? When `TRUE`, the
#'   default, columns like `"wind_direction"` are shortened to `"wd"`. When
#'   `FALSE`, names will match the raw data, albeit in lower case.
#'
#' @param append_codes Logical. Should various codes (e.g., measurement coeds,
#'   qualiy codes, etc.) be appended to the output dataframe?
#'
#' @param codes When `append_codes` is `TRUE`, which codes should be appended to
#'   the dataframe? Any combination of `"measurement_code"`, `"quality_code"`,
#'   `"report_type"`, `"source_code"`, and/or `"source_id"`.
#'
#' @param progress Show a progress bar when importing many stations/years?
#'   Defaults to `TRUE` in interactive R sessions. Passed to `.progress` in
#'   [purrr::map()] and/or [purrr::pmap()].
#'
#' @author Jack Davison
#' @family GHCN functions
#'
#' @return a [tibble][tibble::tibble-package]
#' @export
import_ghcn_hourly <-
  function(
    station = "UKI0000EGLL",
    year = NULL,
    source = c("psv", "parquet"),
    abbr_names = TRUE,
    append_codes = FALSE,
    codes = c(
      "measurement_code",
      "quality_code",
      "report_type",
      "source_code",
      "source_id"
    ),
    progress = rlang::is_interactive()
  ) {
    source <- rlang::arg_match(source, c("psv", "parquet"), multiple = FALSE)

    potential_codes <- c(
      "measurement_code",
      "quality_code",
      "report_type",
      "source_code",
      "source_id"
    )
    codes <- rlang::arg_match(codes, potential_codes, several.ok = TRUE)

    # (temporary?) issue with parquet files not having ids/lats/longs - need to
    # have meta to sort that out
    meta <- import_ghcn_stations(database = "hourly")

    import_single_ghcn_site <- function(station, year, append_codes, codes) {
      if (is.null(year)) {
        per_station_url <-
          "https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/access/by-station/GHCNh_INPUTCODE_por.psv"

        url <- sub("INPUTCODE", station, per_station_url)

        suppressWarnings({
          data <- readr::read_delim(url, delim = "|", progress = progress)
        })

        data <- data |>
          dplyr::slice_head(n = -1L) |>
          dplyr::rename_with(tolower) |>
          dplyr::mutate(
            date = paste0(
              .data$year,
              "/",
              .data$month,
              "/",
              .data$day,
              " ",
              .data$hour,
              ":",
              .data$minute,
              ":00"
            ) |>
              as.POSIXct(tz = "UTC"),
            .before = year,
            .keep = "unused"
          )
      } else {
        url <-
          paste0(
            "https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/access/by-year/INPUTYEAR/",
            source,
            "/GHCNh_INPUTCODE_INPUTYEAR.",
            source
          )

        url <- sub("INPUTCODE", station, url)
        url <- gsub("INPUTYEAR", as.character(year), url)

        if (source == "psv") {
          suppressWarnings({
            data <-
              readr::read_delim(
                url,
                delim = "|",
                name_repair = tolower,
                show_col_types = FALSE,
                progress = FALSE
              )
          })

          data <- dplyr::rename(data, station_id = "station")
        } else if (source == "parquet") {
          rlang::check_installed("arrow")
          suppressWarnings({
            data <- arrow::read_parquet(url)
          })

          data <- data |>
            dplyr::rename_with(tolower) |>
            dplyr::mutate(
              date = as.POSIXct(.data$date)
            )

          data <-
            data |>
            dplyr::select(-"station_id", -"longitude", -"latitude") |>
            dplyr::left_join(
              dplyr::filter(meta, .data$name %in% data$station_name) |>
                dplyr::transmute(
                  station_name = .data$name,
                  station_id = .data$id,
                  latitude = .data$lat,
                  longitude = .data$lng
                ),
              by = dplyr::join_by("station_name")
            ) |>
            dplyr::relocate("station_id", .before = 0) |>
            dplyr::relocate("latitude", "longitude", .after = "date")
        }

        # ensure data type consistency
        data <-
          dplyr::mutate(
            data,
            # all the "codes" are characters
            dplyr::across(
              dplyr::ends_with(
                potential_codes
              ),
              as.character
            ),
            # these variables are written observations/codes
            dplyr::across(
              c(
                "pres_wx_mw1",
                "pres_wx_mw2",
                "pres_wx_mw3",
                "pres_wx_au1",
                "pres_wx_au2",
                "pres_wx_au3",
                "pres_wx_aw1",
                "pres_wx_aw2",
                "pres_wx_aw3",
                "sky_cover_1",
                "sky_cover_2",
                "sky_cover_3",
                "remarks"
              ),
              as.character
            ),
            # these variables are all numeric
            dplyr::across(
              c(
                "latitude",
                "longitude",
                "elevation",
                "temperature",
                "dew_point_temperature",
                "station_level_pressure",
                "sea_level_pressure",
                "wind_direction",
                "wind_speed",
                "wind_gust",
                "precipitation",
                "relative_humidity",
                "wet_bulb_temperature",
                "snow_depth",
                "visibility",
                "altimeter",
                "pressure_3hr_change",
                "sky_cover_baseht_1",
                "sky_cover_baseht_2",
                "sky_cover_baseht_3",
                "precipitation_3_hour",
                "precipitation_6_hour",
                "precipitation_9_hour",
                "precipitation_12_hour",
                "precipitation_15_hour",
                "precipitation_18_hour",
                "precipitation_21_hour",
                "precipitation_24_hour"
              ),
              as.numeric
            )
          )

        # if appending codes, find out which ones we are dropping, else drop
        # them all
        if (append_codes) {
          codes_to_drop <- setdiff(potential_codes, codes)
        } else {
          codes_to_drop <- potential_codes
        }

        if (length(codes_to_drop) > 1L) {
          # sometimes its source_id, sometimes its source_station_id
          if ("source_id" %in% codes_to_drop) {
            codes_to_drop <- c(codes_to_drop, "source_station_id")
          }
          # drop each type of code
          for (i in codes_to_drop) {
            data <- dplyr::select(data, -dplyr::ends_with(i))
          }
        }
      }

      return(data)
    }

    # iterate - need two strategies: one for year=NULL, one for station&year
    if (is.null(year)) {
      data <- purrr::map(
        .x = station,
        .f = purrr::possibly(\(x) {
          import_single_ghcn_site(
            station = x,
            year = year,
            append_codes = append_codes,
            codes = codes
          )
        }),
        .progress = progress
      )
    } else {
      data <-
        tidyr::crossing(station = station, year = year) |>
        purrr::pmap(
          .f = purrr::possibly(\(station, year) {
            import_single_ghcn_site(
              station = station,
              year = year,
              append_codes = append_codes,
              codes = codes
            )
          }),
          .progress = progress
        )
    }

    # bind data together
    data <- dplyr::bind_rows(data)

    # if null, leave early
    if (is.null(data) || nrow(data) == 0L) {
      cli::cli_warn("No data has been returned.")
      return(NULL)
    }

    # if abbreviated names requested, do that
    if (abbr_names) {
      rn_data <- function(data, from, to) {
        names(data) <- gsub(from, to, names(data))
        data
      }
      data <-
        data |>
        rn_data("station_id", "id") |>
        rn_data("station_name", "station") |>
        rn_data("latitude", "lat") |>
        rn_data("longitude", "lng") |>
        rn_data("elevation", "elev") |>
        rn_data("\\btemperature", "air_temp") |>
        rn_data("dew_point_temperature", "dew_temp") |>
        rn_data("station_level_pressure", "atmos_pres") |>
        rn_data("sea_level_pressure", "sea_pres") |>
        rn_data("wind_direction", "wd") |>
        rn_data("wind_speed", "ws") |>
        rn_data("wind_gust", "wg") |>
        rn_data("relative_humidity", "rh") |>
        rn_data("wet_bulb_temperature", "wet_bulb") |>
        rn_data("wet_bulb_temperature", "wet_bulb") |>
        rn_data("pressure_3hr_change", "pres_03") |>
        dplyr::rename_with(\(x) gsub("precipitation", "precip", x)) |>
        dplyr::rename_with(\(x) gsub("pres_wx_", "wx_", x)) |>
        dplyr::rename_with(\(x) gsub("_hour", "", x)) |>
        dplyr::rename_with(\(x) gsub("sky_cover_", "sc_", x)) |>
        rn_data("precip_3", "precip_03") |>
        rn_data("precip_6", "precip_06") |>
        rn_data("precip_9", "precip_09") |>
        dplyr::rename_with(\(x) gsub("_measurement_code", "_mc", x)) |>
        dplyr::rename_with(\(x) gsub("_quality_code", "_qc", x)) |>
        dplyr::rename_with(\(x) gsub("_report_type", "_rt", x)) |>
        dplyr::rename_with(\(x) gsub("_source_code", "_sc", x)) |>
        dplyr::rename_with(\(x) gsub("_source_id", "_si", x)) |>
        dplyr::rename_with(\(x) gsub("_source_station_id", "_si", x))
    }

    return(data)
  }
