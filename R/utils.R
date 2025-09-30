#' Copy of [openair::timeAverage()] for hourly averaging, simplified for
#' specific use in worldmet
#' @noRd
worldmet_time_average <- function(
  mydata,
  avg.time = "day",
  type = "default"
) {
  # extract variables of interest
  vars <- unique(c("date", names(mydata)))
  mydata <- check_prep(
    mydata,
    vars,
    type = "default",
    remove.calm = FALSE
  )

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

  # function to calculate means
  #
  # need to check whether avg.time is > or < actual time gap of data
  # then data will be expanded or aggregated accordingly
  calc.mean <- function(mydata) {
    # obtain time parameters; seconds in the avg.time interval and seconds in
    # the data interval
    time_params <- get_time_parameters(mydata = mydata, avg.time = avg.time)
    seconds_data_interval <- time_params$seconds_data_interval
    seconds_avgtime_interval <- time_params$seconds_avgtime_interval

    # check to see if we need to expand data rather than aggregate it
    # i.e., chosen time interval less than that of data
    if (seconds_avgtime_interval < seconds_data_interval) {
      # Get time interval from data
      interval <- find_time_interval(mydata$date)

      # get time interval as days; used for refinement
      days <- as.numeric(strsplit(interval, split = " ")[[1]][1]) / 24 / 3600

      # refine interval for common situations
      interval <- if (inherits(mydata$date, "Date")) {
        paste(days, "day")
      } else if (days %in% c(30, 31)) {
        "month"
      } else if (days %in% c(365, 366)) {
        "year"
      } else {
        interval
      }

      # calculate full series of dates by the data interval
      date_range <- range(mydata$date)
      allDates <- seq(date_range[1], date_range[2], by = interval)
      allDates <- c(allDates, max(allDates) + seconds_data_interval)

      # recalculate full series of dates by the avg.time interval
      allData <- data.frame(date = seq(min(allDates), max(allDates), avg.time))

      # merge with original data, which leaves gaps to fill
      mydata <-
        mydata |>
        dplyr::full_join(allData, by = dplyr::join_by("date")) |>
        dplyr::arrange(date)

      # make sure missing types are inserted
      mydata <- tidyr::fill(
        mydata,
        dplyr::all_of(type),
        .direction = c("downup")
      )

      return(mydata)
    }

    # calculate Uu & Vv if "wd" (& "ws") are in mydata
    mydata <- calculate_wind_components(mydata = mydata)

    ## Aggregate data

    ## variables to split by
    vars <- c(type, "date")
    mydata$date <-
      cut(mydata$date, avg.time) |>
      as.character() |>
      (function(x) {
        id <- !grepl("00:00", x)
        x[id] <- paste(x[id], "00:00:00")
        x
      })() |>
      as.POSIXct(tz = TZ)

    avmet <-
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

    avmet
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

  # drop default column if it exists
  if ("default" %in% names(mydata)) {
    mydata$default <- NULL
  }

  # return
  return(mydata)
}


#' Pad the data
#' @noRd
pad_dates_timeavg <- function(mydata, type = NULL, interval = "month") {
  # assume by the time we get here the data have been split into types
  # This means we just need to pad out the missing types based on first
  # line.

  start.date <- min(mydata$date, na.rm = TRUE)
  end.date <- max(mydata$date, na.rm = TRUE)

  # interval is in seconds, so convert to days if Date class and not POSIXct
  if (class(mydata$date)[1] == "Date") {
    interval <- paste(
      as.numeric(strsplit(interval, " ")[[1]][1]) / 3600 / 24,
      "days"
    )
  }

  all.dates <- data.frame(date = seq(start.date, end.date, by = interval))
  mydata <- dplyr::full_join(mydata, all.dates, by = "date")

  # add in missing types if gaps are made
  if (!is.null(type)) {
    mydata[type] <- mydata[1, type]
  }

  # make sure order is correct
  mydata <- dplyr::arrange(mydata, date)

  return(mydata)
}

#' Get the intervals in the original data and in the avg.time period
#' @noRd
get_time_parameters <- function(mydata, avg.time) {
  # Time diff in seconds of original data
  seconds_data_interval <- as.numeric(strsplit(
    find_time_interval(mydata$date),
    " "
  )[[1]][1])

  # Parse time diff of new interval
  by2 <- strsplit(avg.time, " ", fixed = TRUE)[[1]]

  seconds_avgtime_interval <- 1
  if (length(by2) > 1) {
    seconds_avgtime_interval <- as.numeric(by2[1])
  }
  units <- by2[length(by2)]

  # Convert units to seconds
  int <- switch(
    units,
    "sec" = 1,
    "min" = 60,
    "hour" = 3600,
    "day" = 3600 * 24,
    "week" = 3600 * 24 * 7,
    "month" = 3600 * 24 * 31,
    "quarter" = 3600 * 24 * 31 * 3,
    "season" = 3600 * 24 * 31 * 3,
    "year" = 3600 * 8784
  )

  if (length(int) == 0L) {
    opts <-
      c(
        "sec",
        "min",
        "hour",
        "day",
        "week",
        "month",
        "quarter",
        "season",
        "year"
      )
    cli::cli_abort(c(
      "x" = "Date unit '{units}' not recognised.",
      "i" = "Possible options: {.code {opts}}."
    ))
  }

  seconds_avgtime_interval <- seconds_avgtime_interval * int # interval in seconds
  if (is.na(seconds_data_interval)) {
    seconds_data_interval <- seconds_avgtime_interval # when only one row
  }

  return(
    list(
      seconds_data_interval = seconds_data_interval,
      seconds_avgtime_interval = seconds_avgtime_interval
    )
  )
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

#' Copy of `check_prep()` from `openair`
#' @noRd
check_prep <- function(
  mydata,
  Names,
  type,
  remove.calm = TRUE,
  remove.neg = TRUE,
  wd = "wd"
) {
  # deal with conditioning variable if present, if user-defined, must exist in
  # data pre-defined types existing conditioning variables that only depend on
  # date (which is checked)
  conds <- c(
    "default",
    "year",
    "hour",
    "month",
    "season",
    "weekday",
    "week",
    "weekend",
    "monthyear",
    "gmtbst",
    "bstgmt",
    "dst",
    "daylight",
    "yearseason",
    "seasonyear"
  )
  all.vars <- unique(c(names(mydata), conds))

  # names we want to be there
  varNames <- c(Names, type)
  matching <- varNames %in% all.vars

  if (any(!matching)) {
    # not all variables are present
    stop(cat("Can't find the variable(s)", varNames[!matching], "\n"))
  }

  # add type to names if not in pre-defined list
  if (any(type %in% conds == FALSE)) {
    ids <- which(type %in% conds == FALSE)
    Names <- c(Names, type[ids])
  }

  # if type already present in data frame
  if (any(type %in% names(mydata))) {
    ids <- which(type %in% names(mydata))
    Names <- unique(c(Names, type[ids]))
  }

  # just select data needed
  mydata <- mydata[, Names]

  # if site is in the data set, check none are missing
  # seems to be a problem for some KCL data...
  if ("site" %in% names(mydata)) {
    # split by site

    # remove any NA sites
    if (anyNA(mydata$site)) {
      id <- which(is.na(mydata$site))
      mydata <- mydata[-id, ]
    }
  }

  # sometimes ratios are considered which can results in infinite values
  # make sure all infinite values are set to NA
  mydata[] <- lapply(mydata, function(x) {
    replace(x, x == Inf | x == -Inf, NA)
  })

  if ("ws" %in% Names) {
    if ("ws" %in% Names && is.numeric(mydata$ws)) {
      # check for negative wind speeds
      if (any(sign(mydata$ws[!is.na(mydata$ws)]) == -1)) {
        if (remove.neg) {
          # remove negative ws only if TRUE
          warning("Wind speed <0; removing negative data")
          mydata$ws[mydata$ws < 0] <- NA
        }
      }
    }
  }

  # round wd to make processing obvious
  # data already rounded to nearest 10 degress will not be affected
  # data not rounded will be rounded to nearest 10 degrees
  # assumes 10 is average of 5-15 etc
  if (wd %in% Names) {
    if (wd %in% Names && is.numeric(mydata[, wd])) {
      # check for wd <0 or > 360
      if (
        any(
          sign(mydata[[wd]][!is.na(mydata[[wd]])]) == -1 |
            mydata[[wd]][!is.na(mydata[[wd]])] > 360
        )
      ) {
        warning("Wind direction < 0 or > 360; removing these data")
        mydata[[wd]][mydata[[wd]] < 0] <- NA
        mydata[[wd]][mydata[[wd]] > 360] <- NA
      }

      if (remove.calm) {
        if ("ws" %in% names(mydata)) {
          mydata[[wd]][mydata$ws == 0] <- NA # set wd to NA where there are calms
          mydata$ws[mydata$ws == 0] <- NA # remove calm ws
        }
        mydata[[wd]][mydata[[wd]] == 0] <- 360 # set any legitimate wd to 360

        # round wd for use in functions - except windRose/pollutionRose
        mydata[[wd]] <- 10 * ceiling(mydata[[wd]] / 10 - 0.5)
        mydata[[wd]][mydata[[wd]] == 0] <- 360 # angles <5 should be in 360 bin
      }
      mydata[[wd]][mydata[[wd]] == 0] <- 360 # set any legitimate wd to 360
    }
  }

  # make sure date is ordered in time if present
  if ("date" %in% Names) {
    if ("POSIXlt" %in% class(mydata$date)) {
      stop("date should be in POSIXct format not POSIXlt")
    }

    # try and work with a factor date - but probably a problem in original data
    if (is.factor(mydata$date)) {
      warning("date field is a factor, check date format")
      mydata$date <- as.POSIXct(mydata$date, "GMT")
    }

    mydata <- dplyr::arrange(mydata, date)

    # make sure date is the first field
    if (names(mydata)[1] != "date") {
      mydata <- mydata[c("date", setdiff(names(mydata), "date"))]
    }

    # check to see if there are any missing dates, stop if there are
    ids <- which(is.na(mydata$date))
    if (length(ids) > 0) {
      mydata <- mydata[-ids, ]
      warning(
        paste("Missing dates detected, removing", length(ids), "lines"),
        call. = FALSE
      )
    }
  }

  # return data frame
  return(mydata)
}

#' From openair
#' @noRd
find_time_interval <- function(dates) {
  # could have several sites, dates may be unordered
  # find the most common time gap in all the data
  dates <- unique(dates) # make sure they are unique

  # work out the most common time gap of unique, ordered dates
  id <- which.max(table(diff(as.numeric(unique(dates[order(dates)])))))
  seconds <- as.numeric(names(id))

  if ("POSIXt" %in% class(dates)) {
    seconds <- paste(seconds, "sec")
  }

  if (class(dates)[1] == "Date") {
    seconds <- seconds * 3600 * 24
    seconds <- paste(seconds, "sec")
  }

  seconds
}
