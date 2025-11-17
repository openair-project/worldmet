#' Deprecated ISD access functions
#'
#' @description
#' `r lifecycle::badge('deprecated')`
#'
#' This function is part of an old `worldmet` API. Please use the following
#' alternatives:
#' - [getMeta()] -> [import_isd_stations()]
#' - [getMetaLive()] -> [import_isd_stations_live()]
#' - [importNOAA()] -> [import_isd_hourly()]
#' - [importNOAAlite()] -> [import_isd_lite()]
#' - the `path` argument -> [write_met()]
#'
#' @inheritParams import_isd_stations
#' @inheritParams import_isd_stations_live
#' @inheritParams import_isd_hourly
#'
#' @param end.year To help filter sites based on how recent the available data
#'   are. `end.year` can be "current", "any" or a numeric year such as 2016, or
#'   a range of years e.g. 1990:2016 (which would select any site that had an
#'   end date in that range. **By default only sites that have some data for the
#'   current year are returned**.
#' @param n The number of nearest sites to search based on `latitude` and
#'   `longitude`.
#' @param plot If `TRUE` will plot sites on an interactive leaflet map.
#' @param returnMap Should the leaflet map be returned instead of the meta data?
#'   Default is `FALSE`.
#'
#' @return A data frame is returned with all available meta data, mostly
#'   importantly including a `code` that can be supplied to [importNOAA()]. If
#'   latitude and longitude searches are made an approximate distance, `dist` in
#'   km is also returned.
#'
#' @rdname deprecated-isd
#' @export
getMeta <- function(
  site = NULL,
  lat = NULL,
  lon = NULL,
  crs = 4326,
  country = NULL,
  state = NULL,
  n = 10,
  end.year = "current",
  provider = c("OpenStreetMap", "Esri.WorldImagery"),
  plot = TRUE,
  returnMap = FALSE
) {
  if (plot || returnMap) {
    m <- import_isd_stations(
      site = site,
      lat = lat,
      lon = lon,
      crs = crs,
      country = country,
      state = state,
      n_max = n,
      end_year = end.year,
      provider = provider,
      return = "map"
    )
  }

  if (plot) {
    print(m)
  }

  if (returnMap) {
    return(m)
  } else {
    dat <-
      import_isd_stations(
        site = site,
        lat = lat,
        lon = lon,
        crs = crs,
        country = country,
        state = state,
        n_max = n,
        end_year = end.year,
        provider = provider,
        return = "table"
      )
    return(dat)
  }
}

#' @rdname deprecated-isd
#' @export
getMetaLive <- function(...) {
  import_isd_stations_live(...)
}

#' @param path If a file path is provided, the data are saved as an rds file at
#'   the chosen location e.g.  `path = "C:/Users/David"`. Files are saved by
#'   year and site.
#' @param n.cores No longer recommended; please set [mirai::daemons()] in your R
#'   session. This argument is provided for back compatibility, and is passed to
#'   the `n` argument of [mirai::daemons()] on behalf of the user. Any set
#'   daemons will be reset once the function completes. Default is `NULL`, which
#'   means no parallelism. `n.cores = 1L` is equivalent to `n.cores = NULL`.
#' @rdname deprecated-isd
#' @export
importNOAA <- function(
  code = "037720-99999",
  year = 2014,
  hourly = TRUE,
  source = c("delim", "fwf"),
  quiet = FALSE,
  path = NA,
  n.cores = NULL
) {
  if (!is.null(n.cores)) {
    if (!rlang::is_integerish(n.cores)) {
      cli::cli_abort(
        "{.field n.cores} should be an integer. You have provided {.type {n.cores}}."
      )
    }
    if (n.cores > 1L) {
      if (mirai::daemons_set()) {
        cli::cli_warn(
          "{.fun mirai::daemons} have already been set. Ignoring {.field n.cores}."
        )
      } else {
        on.exit(mirai::daemons(0))
        cli::cli_warn(
          c(
            "!" = "Using {.fun mirai::daemons} to set multiple workers. These will be reset at the end of the function call.",
            "i" = "It is now preferred that users use {.fun mirai::daemons} directly over the use of {.field n.cores}.",
            "i" = "See {.url https://openair-project.github.io/worldmet/articles/worldmet.html} for an example."
          ),
          .frequency = "regularly",
          .frequency_id = "worldmet_mirai"
        )
        mirai::daemons(n.cores)
      }
    }
  }

  dat <-
    import_isd_hourly(
      code = code,
      year = year,
      hourly = hourly,
      source = source,
      progress = !quiet,
      quiet = quiet
    )

  if (is.null(dat)) {
    return(NULL)
  }

  if (!is.na(path)) {
    write_met(
      x = dat,
      path = path,
      ext = "rds",
      suffix = "",
      progress = FALSE
    )
  }

  return(dat)
}

#' @rdname deprecated-isd
#' @export
importNOAAlite <- function(
  code = "037720-99999",
  year = 2025,
  quiet = FALSE,
  path = NA
) {
  dat <-
    import_isd_lite(
      code = code,
      year = year,
      progress = !quiet,
      quiet = quiet
    )

  if (is.null(dat)) {
    return(NULL)
  }

  if (!is.na(path)) {
    write_met(
      x = dat,
      path = path,
      ext = "rds",
      suffix = "_lite",
      progress = FALSE
    )
  }

  return(dat)
}

#' Deprecated data functions
#'
#' @description
#' `r lifecycle::badge('deprecated')`
#'
#' This function is part of an old `worldmet` API. Please use the following
#' alternatives:
#' - [exportADMS()] -> [write_adms()]
#' - the `path` argument -> [write_met()]
#'
#' @param dat A data frame imported by [importNOAA()].
#' @param out A file name for the ADMS file. The file is written to the working
#'   directory by default.
#' @param interp Should interpolation of missing values be undertaken? If `TRUE`
#'   linear interpolation is carried out for gaps of up to and including
#'   `maxgap`.
#' @param maxgap The maximum gap in hours that should be interpolated where
#'   there are missing data when `interp = TRUE.` Data with gaps more than
#'   `maxgap` are left as missing.
#'
#' @rdname deprecated-data
#' @export
exportADMS <- function(
  dat,
  out = "./ADMS_met.MET",
  interp = FALSE,
  maxgap = 2
) {
  write_adms(
    x = dat,
    file = out,
    interp = interp,
    max_gap = maxgap
  )
}

#' Function to alert that the ISD is going away
#' @noRd
warn_isd <- function(fn = cli::cli_warn) {
  fn(
    c(
      "!" = "The integrated surface database has been deprecated by NOAA, and data is now only available until 2025.",
      "i" = "Please consider using {.fun worldmet::import_ghcn_stations} and {.fun worldmet::import_ghcn_hourly} to access data from the new Global Historical Climatology Network."
    ),
    .frequency = "regularly",
    .frequency_id = "isd-deprecated"
  )
}
