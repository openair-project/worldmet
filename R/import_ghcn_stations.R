#' Import station metadata for the Global Historical Climatology Network
#'
#' This function accesses a full list of GHCN stations available through either
#' the GHCNh or GHCNd. As well as the station `id`, needed for importing
#' measurement data, useful geographic and network metadata is also returned.
#'
#' @param name,country,state String values to use to filter the metadata for
#'   specific site names, countries and states. `country` and `state` are
#'   matched exactly to codes accessed using [import_ghcn_countries()]. `name`
#'   is searched as a sub-string case insensitively.
#'
#' @param lat,lng,n_max Decimal latitude (`lat`) and longitude (`lng`) (or other
#'   Y/X coordinate if using a different `crs`). If provided, the `n_max`
#'   closest ISD stations to this coordinate will be returned.
#'
#' @param crs The coordinate reference system (CRS) of the data, passed to
#'   [sf::st_crs()]. By default this is [EPSG:4326](https://epsg.io/4326), the
#'   CRS associated with the commonly used latitude and longitude coordinates.
#'   Different coordinate systems can be specified using `crs` (e.g., `crs =
#'   27700` for the [British National Grid](https://epsg.io/27700)). Note that
#'   non-lat/lng coordinate systems will be re-projected to `EPSG:4326` for
#'   making comparisons with the NOAA metadata.
#'
#' @param database One of `"hourly"` or `"daily"`, which defines whether to
#'   import stations available in the GHCNh or GHCNd. Note that there is overlap
#'   between the two, but some stations may only be available in one or the
#'   other.
#'
#' @param provider When `return = "map"`, by default a map will be created in
#'   which readers may toggle between a vector street map and a satellite/aerial
#'   image. `provider` allows users to override this default; see
#'   \url{http://leaflet-extras.github.io/leaflet-providers/preview/} for a list
#'   of all base maps that can be used. Base maps can be toggled using a layer
#'   control menu; the labels will be taken from the name of the base map unless
#'   a named list is defined (see default value).
#'
#' @param return The type of R object to import the data as. One of the
#'   following:
#'
#' - `"table"`, which returns an R `data.frame`.
#'
#' - `"sf"`, which returns a spatial `data.frame` from the `sf` package.
#'
#' - `"map"`, which returns an interactive `leaflet` map.
#'
#' @author Jack Davison
#' @family GHCN functions
#'
#' @return One of:
#'
#' - a [tibble][tibble::tibble-package]
#'
#' - an [sf][sf::st_as_sf()] object
#'
#' - an interactive `leaflet` map
#'
#' @export
import_ghcn_stations <-
  function(
    name = NULL,
    country = NULL,
    state = NULL,
    lat = NULL,
    lng = NULL,
    crs = 4326,
    n_max = 10L,
    provider = c(
      "Street Map" = "CartoDB.Voyager",
      "Satellite" = "Esri.WorldImagery"
    ),
    database = c("hourly", "daily"),
    return = c("table", "sf", "map")
  ) {
    database <- rlang::arg_match(database, c("hourly", "daily"))
    return <- rlang::arg_match(return, c("table", "sf", "map"))

    cache_key <- paste0("stations_", database)

    if (exists(cache_key, envir = .worldmet_cache)) {
      meta <- get(cache_key, envir = .worldmet_cache)
    } else {
      old_timeout <- options(timeout = 300)
      on.exit(options(old_timeout), add = TRUE)

      meta_url <-
        switch(
          database,
          "hourly" = "https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/doc/ghcnh-station-list.txt",
          "daily" = "https://www.ncei.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt"
        )

      tmp <- tempfile(fileext = ".txt")
      on.exit(unlink(tmp), add = TRUE)
      err <- download_retry(meta_url, tmp)
      if (!is.null(err)) {
        stop(err)
      }

      meta <-
        readr::read_fwf(
          tmp,
          col_positions = readr::fwf_positions(
            start = c(1, 13, 22, 32, 39, 42, 73, 77, 81),
            end = c(11, 20, 30, 37, 40, 71, 75, 79, NA),
            col_names = c(
              "id",
              "lat",
              "lng",
              "elevation",
              "state",
              "name",
              "gsn_flag",
              "hcn_crn_flag",
              "wmo_id"
            )
          ),
          col_types = list(
            readr::col_character(),
            readr::col_number(),
            readr::col_number(),
            readr::col_number(),
            readr::col_character(),
            readr::col_character(),
            readr::col_character(),
            readr::col_character(),
            readr::col_character()
          ),
          na = c("-999.9", "-999", "-999.0", ""),
          progress = FALSE
        )

      assign(cache_key, meta, envir = .worldmet_cache)
    }

    meta <-
      dplyr::mutate(
        meta,
        country = trimws(substr(.data$id, 1L, 2L)),
        network = trimws(substr(.data$id, 3L, 3L)),
        .after = "id"
      ) |>
      dplyr::relocate(dplyr::all_of(c(
        "id",
        "name",
        "country",
        "state",
        "network"
      )))

    if (!is.null(name)) {
      meta <- dplyr::filter(meta, grepl(!!name, .data$name, ignore.case = TRUE))
    }

    if (!is.null(country)) {
      meta <- dplyr::filter(meta, .data$country %in% !!country)
    }

    if (!is.null(state)) {
      meta <- dplyr::filter(meta, .data$state %in% !!state)
    }

    if (!is.null(lat) && !is.null(lng)) {
      meta_sf <- sf::st_as_sf(
        meta,
        coords = c("lng", "lat"),
        crs = 4326,
        remove = FALSE
      )

      target_sf <-
        sf::st_as_sf(
          tibble::tibble(lat = lat, lng = lng),
          coords = c("lng", "lat"),
          crs = crs
        ) |>
        sf::st_transform(crs = 4326)

      meta_sf$distance <- as.numeric(sf::st_distance(meta_sf, target_sf)) /
        1000L

      meta <-
        meta_sf |>
        dplyr::arrange(.data$distance) |>
        dplyr::slice_head(n = n_max) |>
        tibble::tibble() |>
        dplyr::select(-"geometry")
    }

    if (return %in% c("sf", "map")) {
      meta <- sf::st_as_sf(
        meta,
        coords = c("lng", "lat"),
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

        popup <- paste0(
          "<div style='font-family: Arial, sans-serif; min-width: 220px; max-width: 280px;'>",

          # Header
          "<div style='background: #2c7bb6; color: white; padding: 8px 12px; margin: -10px -10px 10px; border-radius: 4px 4px 0 0;'>",
          "<div style='font-size: 14px; font-weight: bold; margin-bottom: 4px;'>",
          meta$name,
          "</div>",
          "<div style='font-family: monospace; font-size: 12px; background: rgba(0,0,0,0.2); display: inline-block; padding: 2px 6px; border-radius: 3px; letter-spacing: 0.5px;'>",
          meta$id,
          "</div>",
          "</div>",

          # Geography section
          "<div style='margin-bottom: 8px;'>",
          "<div style='font-size: 11px; font-weight: bold; text-transform: uppercase; color: #888; margin-bottom: 4px; border-bottom: 1px solid #eee; padding-bottom: 2px;'>Geography</div>",
          "<div style='display: flex; justify-content: space-between; font-size: 12px; padding: 2px 0;'><span style='color: #555; font-weight: bold;'>Country</span><span>",
          fmt_val(meta$country),
          "</span></div>",
          "<div style='display: flex; justify-content: space-between; font-size: 12px; padding: 2px 0;'><span style='color: #555; font-weight: bold;'>State</span><span>",
          fmt_val(meta$state),
          "</span></div>",
          "<div style='display: flex; justify-content: space-between; font-size: 12px; padding: 2px 0;'><span style='color: #555; font-weight: bold;'>Network</span><span>",
          fmt_val(meta$network),
          "</span></div>",
          "<div style='display: flex; justify-content: space-between; font-size: 12px; padding: 2px 0;'><span style='color: #555; font-weight: bold;'>Elevation</span><span>",
          fmt_val(meta$elevation),
          " m</span></div>",
          "</div>",

          # Flags section
          "<div>",
          "<div style='font-size: 11px; font-weight: bold; text-transform: uppercase; color: #888; margin-bottom: 4px; border-bottom: 1px solid #eee; padding-bottom: 2px;'>Station Flags</div>",
          "<div style='display: flex; justify-content: space-between; font-size: 12px; padding: 2px 0;'><span style='color: #555; font-weight: bold;'>GSN Flag</span><span>",
          fmt_val(meta$gsn_flag),
          "</span></div>",
          "<div style='display: flex; justify-content: space-between; font-size: 12px; padding: 2px 0;'><span style='color: #555; font-weight: bold;'>HCN/CRN Flag</span><span>",
          fmt_val(meta$hcn_crn_flag),
          "</span></div>",
          "<div style='display: flex; justify-content: space-between; font-size: 12px; padding: 2px 0;'><span style='color: #555; font-weight: bold;'>WMO ID</span><span>",
          fmt_val(meta$wmo_id),
          "</span></div>",
          "</div>",

          "</div>"
        )
        overlays <- c("Stations")
        if ("distance" %in% names(meta)) {
          popup <- paste0(
            popup,
            "<div style='margin-top: 8px;'>",
            "<div style='font-size: 11px; font-weight: bold; text-transform: uppercase; color: #888; margin-bottom: 4px; border-bottom: 1px solid #eee; padding-bottom: 2px;'>Distance from search</div>",
            "<div style='font-family: monospace; font-size: 12px; background: #f4f4f4; border-left: 3px solid #c0392b; padding: 3px 8px; border-radius: 0 3px 3px 0;'>",
            round(meta$distance, 1),
            " km",
            "</div>",
            "</div>",
            "</div>" # closes the outer wrapper div
          )
          overlays <- c(overlays, "Target")
        }

        n_sites <- nrow(meta)
        meta <- leaflet::leaflet(meta)

        if (!rlang::is_named(provider)) {
          provider <- stats::setNames(provider, provider)
        }
        for (i in seq_along(provider)) {
          meta <- leaflet::addProviderTiles(
            meta,
            provider = provider[[i]],
            group = names(provider)[[i]]
          )
        }

        meta <- meta |>
          leaflet::addMarkers(
            popup = popup,
            clusterOptions = if (n_sites < 20) {
              NULL
            } else {
              leaflet::markerClusterOptions()
            },
            group = "Stations"
          ) |>
          leaflet::addLayersControl(
            baseGroups = names(provider),
            overlayGroups = overlays,
            options = leaflet::layersControlOptions(
              collapsed = FALSE,
              autoZIndex = TRUE
            )
          )

        if ("Target" %in% overlays) {
          meta <-
            leaflet::addAwesomeMarkers(
              map = meta,
              data = target_sf,
              popup = paste0(
                "<div style='font-family: Arial, sans-serif; min-width: 200px; max-width: 260px;'>",

                # Header
                "<div style='background: #c0392b; color: white; padding: 8px 12px; margin: -10px -10px 10px; border-radius: 4px 4px 0 0;'>",
                "<div style='font-size: 14px; font-weight: bold;'>Search Location</div>",
                "</div>",

                # Coordinates section
                "<div style='margin-bottom: 8px;'>",
                "<div style='font-size: 11px; font-weight: bold; text-transform: uppercase; color: #888; margin-bottom: 4px; border-bottom: 1px solid #eee; padding-bottom: 2px;'>Coordinates</div>",
                "<div style='display: flex; justify-content: space-between; font-size: 12px; padding: 2px 0;'><span style='color: #555; font-weight: bold;'>Latitude</span><span style='font-family: monospace;'>",
                lat,
                "</span></div>",
                "<div style='display: flex; justify-content: space-between; font-size: 12px; padding: 2px 0;'><span style='color: #555; font-weight: bold;'>Longitude</span><span style='font-family: monospace;'>",
                lng,
                "</span></div>",
                "<div style='display: flex; justify-content: space-between; font-size: 12px; padding: 2px 0;'><span style='color: #555; font-weight: bold;'>CRS</span><span style='font-family: monospace;'>EPSG:",
                crs,
                "</span></div>",
                "</div>",

                "</div>"
              ),
              group = "Target",
              icon = leaflet::makeAwesomeIcon(
                icon = "circle",
                library = "fa",
                markerColor = "red",
                iconColor = "#FFFFFF"
              )
            )
        }
      }
    }

    return(meta)
  }

#' Import station inventory for the Global Historical Climatology Network
#'
#' This function accesses a data inventory of GHCN stations available through
#' either the GHCNh or GHCNd. The returned `data.frame` contains data which
#' reveals the earliest and latest years of data available for each station from
#' the NOAA database.
#'
#' @param database One of `"hourly"` or `"daily"`, which defines whether to
#'   import the GHCNh or GHCNd inventory. The way in which these files is
#'   formatted is different.
#'
#' @param pivot One of `"wide"` or `"long"`. The GHCNh inventory can be returned
#'   in a `"wide"` format (with `id`, `year` and twelve month columns) or a
#'   `"long"` format (with `id`, `year`, `month`, and `count` columns). Does not
#'   apply to the GHCNd inventory.
#'
#' @param progress The inventory file is large and can be slow to download. Show
#'   a progress indicator when accessing the inventory? Defaults to `TRUE` in
#'   interactive R sessions. Passed to `progress` in [readr::read_fwf()] and/or
#'   [purrr::pmap()].
#'
#' @author Jack Davison
#' @family GHCN functions
#'
#' @return a [tibble][tibble::tibble-package]
#' @export
import_ghcn_inventory <-
  function(
    database = c("hourly", "daily"),
    pivot = c("wide", "long"),
    progress = rlang::is_interactive()
  ) {
    database <- rlang::arg_match(database)
    pivot <- rlang::arg_match(pivot)

    if (database == "daily") {
      inventory <-
        readr::read_fwf(
          file = "https://www.ncei.noaa.gov/pub/data/ghcn/daily/ghcnd-inventory.txt",
          col_positions = readr::fwf_widths(
            c(11L, 9L, 10L, 5L, 5L, 5L),
            col_names = c(
              "id",
              "lat",
              "lng",
              "element",
              "start_year",
              "end_year"
            )
          ),
          show_col_types = FALSE,
          progress = progress
        ) |>
        dplyr::mutate(
          start_year = as.integer(.data$start_year),
          end_year = as.integer(.data$end_year)
        ) |>
        dplyr::mutate(
          country = trimws(substr(.data$id, 1L, 2L)),
          network = trimws(substr(.data$id, 3L, 3L)),
          .after = "id"
        )
    }

    if (database == "hourly") {
      temp_inv <- tempfile(fileext = "txt")
      utils::download.file(
        "https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/doc/ghcnh-inventory.txt",
        destfile = temp_inv,
        quiet = !progress,
        mode = "wb"
      )

      inventory <- readr::read_fwf(
        temp_inv,
        show_col_types = FALSE,
        progress = progress
      )
      inventory <- dplyr::slice_tail(
        stats::setNames(inventory, as.vector(t(inventory[1, ]))),
        n = -1
      )
      inventory <-
        dplyr::mutate(
          inventory,
          dplyr::across("YEAR":"DEC", as.integer)
        )

      if (pivot == "wide") {
        inventory <-
          inventory |>
          dplyr::mutate(dplyr::across(-"GHCNh_ID", as.integer)) |>
          dplyr::rename_with(tolower) |>
          dplyr::rename("id" = "ghcnh_id")
      }

      if (pivot == "long") {
        inventory <-
          inventory |>
          tidyr::pivot_longer(
            "JAN":"DEC",
            names_to = "month",
            values_to = "count"
          ) |>
          dplyr::rename_with(tolower) |>
          dplyr::mutate(
            month = factor(
              .data$month,
              levels = c(
                "JAN",
                "FEB",
                "MAR",
                "APR",
                "MAY",
                "JUN",
                "JUL",
                "AUG",
                "SEP",
                "OCT",
                "NOV",
                "DEC"
              )
            ),
            dplyr::across(c("year", "count"), as.integer)
          ) |>
          dplyr::rename("id" = "ghcnh_id")
      }

      inventory <-
        dplyr::mutate(
          inventory,
          country = trimws(substr(.data$id, 1L, 2L)),
          network = trimws(substr(.data$id, 3L, 3L)),
          .after = "id"
        )
    }

    return(inventory)
  }

#' Import FIPS country codes and State/Province/Territory codes used by the
#' Global Historical Climatology Network
#'
#' This function returns a two-column dataframe either of "Federal Information
#' Processing Standards" (FIPS) codes and the countries to which they are
#' associated, or state codes and their associated states. These may be a useful
#' reference when examining GHCN site metadata.
#'
#' @param table One of `"countries"` or `"states"`.
#'
#' @param database One of `"hourly"`, `"daily"` or `"monthly"`, which defines
#'   which of the NOAA databases to import the FIPS codes from. There is little
#'   difference between the data in the different sources, but this option may
#'   be useful if one of the services is not accessible.
#'
#' @author Jack Davison
#' @family GHCN functions
#'
#' @return a [tibble][tibble::tibble-package]
#' @export
import_ghcn_countries <-
  function(
    table = c("countries", "states"),
    database = c("hourly", "daily", "monthly")
  ) {
    table <- rlang::arg_match(table)
    if (table == "countries") {
      database <- rlang::arg_match(database)
      url <- switch(
        database,
        "hourly" = "https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/doc/ghcn-countries.txt",
        "daily" = "https://www.ncei.noaa.gov/pub/data/ghcn/daily/ghcnd-countries.txt",
        "monthly" = "https://www.ncei.noaa.gov/pub/data/ghcn/v4/ghcnm-countries.txt"
      )
    }

    if (table == "states") {
      url <-
        "https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/doc/ghcn-states.txt"
    }

    x <- readr::read_lines(url, progress = FALSE)

    data <-
      tibble::tibble(
        code = trimws(substr(x, 1, 2)),
        x = trimws(substr(x, 3, 1000))
      ) |>
      dplyr::arrange(.data$code)

    newname <- ifelse(table == "countries", "country", "state")
    names(data)[names(data) == "x"] <- newname

    return(data)
  }
