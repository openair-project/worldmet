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
#' @param hourly Should hourly means be calculated? The default is `TRUE`. If
#'   `FALSE` then the raw data are returned, which can be sub-hourly.
#'
#' @param extra Should additional columns be returned? The default, `FALSE`,
#'   returns an opinionated selection of elements that'll be of most interest to
#'   most users. `TRUE` will return everything available from the GHCNh.
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
#' @section Parallel Processing:
#'
#'   If you are importing a lot of meteorological data, this can take a long
#'   while. This is because each combination of year and station requires
#'   downloading a separate data file from NOAA's online data directory, and the
#'   time each download takes can quickly add up. Many data import functions in
#'   `{worldmet}` can use parallel processing to speed downloading up, powered
#'   by the capable `{mirai}` package. If users have any `{mirai}` "daemons"
#'   set, these functions will download files in parallel. The greatest benefits
#'   will be seen if you spawn as many daemons as you have cores on your
#'   machine, although one fewer than the available cores is often a good rule
#'   of thumb. Your mileage may vary, however, and naturally spawning more
#'   daemons than station-year combinations will lead to diminishing returns.
#'
#'   ```
#'   # set workers - once per session
#'   mirai::daemons(4)
#'
#'   # import lots of data - NB: no change in the import function!
#'   big_met <- import_isd_(code = "037720-99999", year = 2010:2020)
#'   ```
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
    hourly = TRUE,
    extra = FALSE,
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
    codes <- rlang::arg_match(codes, potential_codes, multiple = TRUE)

    # (temporary?) issue with parquet files not having ids/lats/longs - need to
    # have meta to sort that out
    meta <- import_ghcn_stations(database = "hourly")

    # iterate - need two strategies: one for year=NULL, one for station&year
    if (is.null(year)) {
      data <- purrr::map(
        .x = station,
        .f = purrr::in_parallel(
          .f = \(x) {
            import_single_ghcn_site(
              station = x,
              year = year,
              source = source,
              append_codes = append_codes,
              codes = codes,
              potential_codes = potential_codes,
              meta = meta
            )
          },
          import_single_ghcn_site = import_single_ghcn_site,
          year = year,
          source = source,
          append_codes = append_codes,
          codes = codes,
          potential_codes = potential_codes,
          meta = meta
        ),
        .progress = progress
      )
    } else {
      combos <- tidyr::crossing(station = station, year = year)
      data <- purrr::map2(
        .x = combos$station,
        .y = combos$year,
        .f = purrr::in_parallel(
          .f = \(x, y) {
            import_single_ghcn_site(
              station = x,
              year = y,
              source = source,
              append_codes = append_codes,
              codes = codes,
              potential_codes = potential_codes,
              meta = meta
            )
          },
          import_single_ghcn_site = import_single_ghcn_site,
          source = source,
          append_codes = append_codes,
          codes = codes,
          potential_codes = potential_codes,
          meta = meta
        ),
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

    # scrub columns if not `extra`
    if (!extra) {
      data <-
        dplyr::select(
          data,
          "station_id",
          "station_name",
          "date",
          "latitude",
          "longitude",
          "elevation",
          dplyr::starts_with("wind_direction"),
          dplyr::starts_with("wind_speed"),
          dplyr::starts_with("temperature"),
          dplyr::starts_with("station_level_pressure"),
          dplyr::starts_with("visibility"),
          dplyr::starts_with("dew_point_temperature"),
          dplyr::starts_with("relative_humidity"),
          dplyr::starts_with("sky_cover"),
          dplyr::starts_with("precip")
        )
    }

    # function to rename columns
    rn_data <- function(data, from, to) {
      names(data) <- gsub(from, to, names(data))
      data
    }

    # if abbreviated names requested, do that
    if (abbr_names) {
      data <-
        data |>
        rn_data("latitude", "lat") |>
        rn_data("longitude", "lng") |>
        rn_data("elevation", "elev") |>
        rn_data("\\btemperature", "air_temp") |>
        rn_data("dew_point_temperature", "dew_point") |>
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
        dplyr::rename_with(\(x) gsub("sky_cover", "cl", x)) |>
        rn_data("precip_3", "precip_03") |>
        rn_data("precip_6", "precip_06") |>
        rn_data("precip_9", "precip_09") |>
        dplyr::rename_with(\(x) gsub("_measurement_code", "_mc", x)) |>
        dplyr::rename_with(\(x) gsub("_quality_code", "_qc", x)) |>
        dplyr::rename_with(\(x) gsub("_report_type", "_rt", x)) |>
        dplyr::rename_with(\(x) gsub("_source_code", "_sc", x)) |>
        dplyr::rename_with(\(x) gsub("_source_id", "_si", x)) |>
        dplyr::rename_with(\(x) gsub("_source_station_id", "_si", x))

      names(data)
    }

    # time average to hourly concentrations
    if (hourly) {
      # if names not abbreviated, switch to ws/wd (needed for timeAverage)
      if (!abbr_names) {
        data <-
          data |>
          rn_data("wind_direction", "wd") |>
          rn_data("wind_speed", "ws")
      }

      # time average to hourly
      data <- worldmet_time_average(
        data,
        avg.time = "hour",
        type = c("station_id", "station_name")
      )

      # if names not abbreviated, switch back to defaults
      if (!abbr_names) {
        data <-
          data |>
          rn_data("wd", "wind_direction") |>
          rn_data("ws", "wind_speed")
      }
    }

    return(data)
  }

#' Helper to import a single site
#' @noRd
import_single_ghcn_site <- function(
  station,
  year,
  source,
  append_codes,
  codes,
  potential_codes,
  meta
) {
  if (is.null(year)) {
    per_station_url <-
      "https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/access/by-station/GHCNh_INPUTCODE_por.psv"

    url <- sub("INPUTCODE", station, per_station_url)

    data <- try(
      suppressWarnings(
        readr::read_delim(url, delim = "|", progress = TRUE)
      ),
      silent = TRUE
    )

    if (class(data)[1] == "try-error") {
      return(NULL)
    }

    data <- data |>
      dplyr::slice_head(n = -1L) |>
      dplyr::rename_with(tolower) |>
      dplyr::mutate(
        date = ISOdate(
          year = .data$year,
          month = .data$month,
          day = .data$day,
          hour = .data$hour,
          min = .data$minute,
          sec = 0,
          tz = "UTC"
        ),
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
      data <- try(
        suppressWarnings(
          readr::read_delim(
            url,
            delim = "|",
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

      data <- dplyr::rename(data, station_id = "station")
    } else if (source == "parquet") {
      rlang::check_installed("arrow")

      data <- try(
        suppressWarnings(
          arrow::read_parquet(url)
        ),
        silent = TRUE
      )

      if (class(data)[1] == "try-error") {
        return(NULL)
      }

      data <- data |>
        dplyr::rename_with(tolower) |>
        dplyr::mutate(
          date = as.POSIXct(
            .data$date,
            format = "%Y-%m-%dT%H:%M:%S",
            tz = "UTC"
          )
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

    # missing wind directions
    if ("wind_direction" %in% names(data)) {
      data$wind_direction <- ifelse(
        data$wind_direction == 999,
        NA,
        data$wind_direction
      )
    }

    # coalesce sky covers
    if ("sky_cover_1" %in% names(data)) {
      data <- data |>
        # split the code name away from the okta
        tidyr::separate_wider_delim(
          cols = dplyr::matches("sky_cover_[123456789]\\b"),
          delim = ":",
          names_sep = "",
          names = c("code", ""),
          too_few = "align_start"
        ) |>
        # drop the code
        dplyr::select(
          -dplyr::matches("sky_cover_[123456789]code")
        ) |>
        # coerce okta to numeric
        dplyr::mutate(
          dplyr::across(
            dplyr::matches("sky_cover_[123456789]\\b"),
            as.numeric
          )
        )

      # get pmax of sky cover columns - for ADMS
      data$sky_cover <- pmax(
        data$sky_cover_1,
        data$sky_cover_2,
        data$sky_cover_3,
        na.rm = TRUE
      )

      # get ceiling height
      data <-
        dplyr::mutate(
          data,
          sky_cover_baseht = dplyr::case_when(
            .data$sky_cover_1 >= 5 ~ .data$sky_cover_baseht_1,
            .data$sky_cover_2 >= 5 ~ .data$sky_cover_baseht_2,
            .data$sky_cover_3 >= 5 ~ .data$sky_cover_baseht_3,
            .default = NA
          )
        )

      # move columns
      data <-
        dplyr::relocate(
          data,
          "sky_cover",
          "sky_cover_baseht",
          .before = "sky_cover_1"
        )
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
