# Session-level cache for station metadata (avoids re-downloading on every call)
.worldmet_cache <- new.env(parent = emptyenv())

#' Average data to hourly resolution
#'
#' A trimmed copy of [openair::timeAverage()] for worldmet's needs. Wind
#' direction is vector-averaged via U/V components, character/factor columns
#' are dropped, and each group is padded to complete calendar years of hourly
#' data.
#'
#' @param mydata A data frame with a `date` column.
#' @param type Columns to group by (e.g., station identifiers).
#' @noRd
worldmet_time_average <- function(mydata, type) {
  mydata <- check_prep(mydata)

  # time zone of data (replace missing w/ GMT)
  TZ <- attr(mydata$date, "tzone") %||% "GMT"

  # function for getting mean
  FUN <- function(x) {
    if (all(is.na(x))) {
      NA
    } else {
      mean(x, na.rm = TRUE)
    }
  }

  # function to calculate hourly means
  calc.mean <- function(mydata) {
    # calculate Uu & Vv if "wd" (& "ws") are in mydata
    mydata <- calculate_wind_components(mydata = mydata)

    ## variables to split by
    vars <- c(type, "date")
    mydata$date <-
      cut(mydata$date, "hour") |>
      as.character() |>
      (function(x) {
        id <- !grepl("00:00", x)
        x[id] <- paste(x[id], "00:00:00")
        x
      })() |>
      as.POSIXct(tz = TZ)

    mydata |>
      dplyr::group_by(dplyr::across(dplyr::all_of(vars))) |>
      dplyr::summarise(dplyr::across(
        dplyr::where(function(x) {
          !is.factor(x) && !is.character(x)
        }),
        function(x) {
          FUN(x)
        }
      ))
  }

  # type will always be a factor
  for (i in type) {
    mydata[i] <- factor(mydata[[i]])
  }

  # select date, type, and all non-factor/character columns
  mydata <-
    dplyr::select(
      mydata,
      dplyr::all_of(c("date", type)),
      dplyr::where(function(x) {
        !is.character(x) && !is.factor(x)
      })
    )

  # calculate averages
  mydata <-
    mydata |>
    split(mydata[type], drop = TRUE) |>
    purrr::map(
      calc.mean
    ) |>
    purrr::list_rbind() |>
    dplyr::as_tibble()

  if ("Uu" %in% names(mydata) && "Vv" %in% names(mydata)) {
    mydata <-
      mydata |>
      dplyr::mutate(
        wd = as.vector(atan2(.data$Uu, .data$Vv) * 360 / 2 / pi),
        wd = ifelse(.data$wd < 0, .data$wd + 360, .data$wd)
      ) |>
      dplyr::select(-dplyr::any_of(c("Uu", "Vv")))
  }

  # site metadata columns, carried into padded hours. These are not used to
  # split the data, as stations whose coordinates/elevation change over time
  # would otherwise be padded once per distinct value, duplicating every hour
  meta_cols <- intersect(
    c("lat", "lng", "latitude", "longitude", "elev", "elevation"),
    names(mydata)
  )

  # split by type and complete by date
  mydata <-
    purrr::map(
      .x = split(
        mydata,
        mydata[type],
        drop = TRUE
      ),
      .f = \(df) {
        from <- as.POSIXct(
          paste0(format(min(df$date), "%Y"), "-01-01"),
          tz = attr(df$date, "tzone")
        )
        to <- as.POSIXct(
          paste0(format(max(df$date), "%Y"), "-12-31 23:00:00"),
          tz = attr(df$date, "tzone")
        )

        df |>
          tidyr::complete(
            tidyr::nesting(!!!rlang::syms(type)),
            date = seq(from, to, by = "hour")
          ) |>
          dplyr::arrange(.data$date) |>
          tidyr::fill(dplyr::all_of(meta_cols), .direction = "downup")
      }
    ) |>
    dplyr::bind_rows()

  # return
  return(mydata)
}

#' Calculate Uu and Vv if wd & ws are in the data
#' @noRd
calculate_wind_components <- function(mydata) {
  if ("wd" %in% names(mydata)) {
    if (is.numeric(mydata$wd)) {
      if ("ws" %in% names(mydata)) {
        mydata <- dplyr::mutate(
          mydata,
          Uu = .data$ws * sin(2 * pi * .data$wd / 360),
          Vv = .data$ws * cos(2 * pi * .data$wd / 360)
        )
      } else {
        mydata <- dplyr::mutate(
          mydata,
          Uu = sin(2 * pi * .data$wd / 360),
          Vv = cos(2 * pi * .data$wd / 360)
        )
      }
    }
  }

  return(mydata)
}

#' Prepare data for time averaging
#'
#' A trimmed copy of `check_prep()` from `openair`, keeping only the checks
#' that apply to worldmet's hourly averaging.
#' @noRd
check_prep <- function(mydata) {
  # make sure all infinite values are set to NA
  mydata[] <- lapply(mydata, function(x) {
    replace(x, x == Inf | x == -Inf, NA)
  })

  # check for negative wind speeds
  if ("ws" %in% names(mydata) && is.numeric(mydata$ws)) {
    if (any(sign(mydata$ws[!is.na(mydata$ws)]) == -1)) {
      warning("Wind speed <0; removing negative data")
      mydata$ws[mydata$ws < 0] <- NA
    }
  }

  # make sure date is POSIXct
  if (inherits(mydata$date, "POSIXlt")) {
    stop("date should be in POSIXct format not POSIXlt")
  }

  # try and work with a factor date - but probably a problem in original data
  if (is.factor(mydata$date)) {
    warning("date field is a factor, check date format")
    mydata$date <- as.POSIXct(mydata$date, "GMT")
  }

  # make sure date is ordered in time and is the first field
  mydata <- dplyr::arrange(mydata, date)
  mydata <- mydata[c("date", setdiff(names(mydata), "date"))]

  # remove any missing dates
  ids <- which(is.na(mydata$date))
  if (length(ids) > 0) {
    mydata <- mydata[-ids, ]
    warning(
      paste("Missing dates detected, removing", length(ids), "lines"),
      call. = FALSE
    )
  }

  return(mydata)
}
