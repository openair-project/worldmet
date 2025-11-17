#' Copy of [openair::timeAverage()] for hourly averaging, simplified for
#' specific use in worldmet
#' @noRd
worldmet_time_average <- function(
  mydata,
  avg.time = "hour",
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

  if ("Uu" %in% names(mydata) && "Vv" %in% names(mydata)) {
    mydata <-
      mydata |>
      dplyr::mutate(
        wd = as.vector(atan2(.data$Uu, .data$Vv) * 360 / 2 / pi),
        wd = ifelse(.data$wd < 0, .data$wd + 360, .data$wd)
      ) |>
      dplyr::select(-dplyr::any_of(c("Uu", "Vv")))
  }

  # drop default column if it exists
  if ("default" %in% names(mydata)) {
    mydata$default <- NULL
  }

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
