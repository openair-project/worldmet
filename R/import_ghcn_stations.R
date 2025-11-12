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
#' @param return The type of R object to import the GHCN stations as. One of the
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
    database = c("hourly", "daily"),
    return = c("table", "sf", "map")
  ) {
    database <- rlang::arg_match(database, c("hourly", "daily"))
    return <- rlang::arg_match(return, c("table", "sf", "map"))
    meta_url <-
      switch(
        database,
        "hourly" = "https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/doc/ghcnh-station-list.txt",
        "daily" = "https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt"
      )

    meta <-
      readr::read_fwf(
        meta_url,
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

    meta <-
      dplyr::mutate(
        meta,
        country = trimws(substr(id, 1L, 2L)),
        network = trimws(substr(id, 3L, 3L)),
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

    if (!is.null(lat) & !is.null(lng)) {
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
        dplyr::arrange(distance) |>
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

        popup <- paste(
          paste0("<b>", meta$name, "</b>"),
          paste("<hr><b>ID:</b>", meta$id),
          paste("<br><b><u>Geography</u></b>"),
          paste("<b>Country:</b>", meta$country),
          paste("<b>State:</b>", meta$state),
          paste("<b>Network:</b>", meta$network),
          paste("<b>Elevation:</b>", meta$elevation, "m"),
          paste("<br><b><u>Station Flags</u></b>"),
          paste("<b>GSN FLAG:</b>", meta$gsn_flag),
          paste("<b>HCN/CRN FLAG:</b>", meta$hcn_crn_flag),
          paste("<b>WMO ID:</b>", meta$gsn_flag),
          sep = "<br/>"
        )

        overlays <- c("Stations")
        if ("distance" %in% names(meta)) {
          popup <- paste(
            popup,
            paste(
              "<br><b>Distance from marker:</b>",
              round(meta$distance, 1),
              "km"
            ),
            sep = "<br/>"
          )
          overlays <- c(overlays, "Target")
        }

        meta <- leaflet::leaflet(meta) |>
          leaflet::addProviderTiles(
            provider = leaflet::providers$OpenStreetMap,
            group = "OSM"
          ) |>
          leaflet::addProviderTiles(
            provider = leaflet::providers$Esri.WorldImagery,
            group = "Satellite"
          ) |>
          leaflet::addMarkers(
            popup = popup,
            clusterOptions = if (nrow(meta) < 20) {
              NULL
            } else {
              leaflet::markerClusterOptions()
            },
            group = "Stations"
          ) |>
          leaflet::addLayersControl(
            baseGroups = c("OSM", "Satellite"),
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
              popup = paste(
                "<b>TARGET</b><hr>",
                paste0("<b>Latitude/Y</b>: ", lat, "<br>"),
                paste0("<b>Longitude/X</b>: ", lng, "<br>"),
                paste0("<b>CRS:</b> ", crs)
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
    database <- match.arg(database)
    pivot <- match.arg(pivot)

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
          start_year = as.integer(start_year),
          end_year = as.integer(end_year)
        ) |>
        dplyr::mutate(
          country = trimws(substr(id, 1L, 2L)),
          network = trimws(substr(id, 3L, 3L)),
          .after = "id"
        )
    }

    if (database == "hourly") {
      inventory <-
        readr::read_fwf(
          "https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/doc/ghcnh-inventory.txt",
          col_positions = readr::fwf_widths(c(
            11L,
            5L,
            7L,
            7L,
            7L,
            7L,
            7L,
            7L,
            7L,
            7L,
            7L,
            7L,
            7L,
            8L
          )),
          show_col_types = FALSE,
          progress = progress
        )

      inventory <-
        inventory |>
        setNames(as.vector(t(inventory[1, ]))) |>
        dplyr::slice_tail(n = -1)

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
            JAN:DEC,
            names_to = "month",
            values_to = "count"
          ) |>
          dplyr::rename_with(tolower) |>
          dplyr::mutate(
            month = factor(
              month,
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
          country = trimws(substr(id, 1L, 2L)),
          network = trimws(substr(id, 3L, 3L)),
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
      database <- match.arg(database)
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
