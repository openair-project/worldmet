# Temperature -------------------------------------------------------------

#' Convert between common temperature units
#'
#' This function converts between Celsius, Fahrenheit, and Kelvin temperature
#' units.
#'
#' @param x A numeric vector of temperatures to convert.
#'
#' @param from,to The units to convert from and to. Must be one of `"c"`
#'   (Celsius), `"f"` (Fahrenheit), or `"k"` (Kelvin). These options are
#'   case-insensitive.
#'
#' @family meteorological unit conversion functions
#' @export
#'
#' @return A numeric vector of the same length as `x` containing the
#'   converted values. `NA` values are preserved.
#'
#' @examples
#' # Convert 100 degrees Celsius to Fahrenheit
#' convert_temp(100, "c", "f")
convert_temp <- function(x, from, to) {
  .check_x_numeric(x)
  opts <- c("c", "f", "k")
  inputs <- .validate_unit_inputs(from, to, opts)
  if (inputs$from == inputs$to) {
    return(x)
  }

  key <- paste(inputs$from, inputs$to, sep = "_to_")
  .temp_conversions[[key]](x)
}

.temp_conversions <- list(
  c_to_f = function(x) x * 9 / 5 + 32,
  c_to_k = function(x) x + 273.15,
  f_to_c = function(x) (x - 32) * 5 / 9,
  f_to_k = function(x) (x - 32) * 5 / 9 + 273.15,
  k_to_c = function(x) x - 273.15,
  k_to_f = function(x) (x - 273.15) * 9 / 5 + 32
)

# Pressure ----------------------------------------------------------------

#' Convert between common pressure units
#'
#' This function converts between common pressure units: hectopascals (hPa),
#' millibars (mb), inches of mercury (inHg), or millimeters of mercury (mmHg).
#' Note that hectopascals and millibars are equivalent units, so no conversion
#' is needed between them.
#'
#' @param x A numeric vector of pressures to convert.
#'
#' @param from,to The units to convert from and to. Must be one of `"hpa"`,
#'   `"mb"`, `"inhg"`, or `"mmhg"`. These options are case-insensitive.
#'
#' @family meteorological unit conversion functions
#' @export
#'
#' @return A numeric vector of the same length as `x` containing the
#'   converted values. `NA` values are preserved.
#'
#' @examples
#' # Convert 1013.25 hPa to inches of mercury
#' convert_pres(1013.25, "hpa", "inhg")
convert_pres <- function(x, from, to) {
  .check_x_numeric(x)
  opts <- c("hpa", "mb", "inhg", "mmhg")
  inputs <- .validate_unit_inputs(from, to, opts)

  # units are equivalent
  inputs$from[inputs$from == "mb"] <- "hpa"
  inputs$to[inputs$to == "mb"] <- "hpa"

  if (inputs$from == inputs$to) {
    return(x)
  }

  key <- paste(inputs$from, inputs$to, sep = "_to_")
  .pres_conversions[[key]](x)
}

.pres_conversions <- list(
  `hpa_to_inhg` = function(x) x / 33.8639,
  `hpa_to_mmhg` = function(x) x / 1.33322,
  `inhg_to_hpa` = function(x) x * 33.8639,
  `inhg_to_mmhg` = function(x) x * 25.4,
  `mmhg_to_hpa` = function(x) x * 1.33322,
  `mmhg_to_inhg` = function(x) x / 25.4
)


# Precipitation -----------------------------------------------------------

#' Convert between common precipitation units
#'
#' This function converts between common precipitation units: millimeters (mm),
#' centimeters (cm), or inches (in).
#'
#' @param x A numeric vector of precipitation amounts to convert.
#'
#' @param from,to The units to convert from and to. Must be one of `"mm"`,
#'   `"cm"`, or `"in"`. These options are case-insensitive.
#'
#' @family meteorological unit conversion functions
#' @export
#'
#' @return A numeric vector of the same length as `x` containing the
#'   converted values. `NA` values are preserved.
#'
#' @examples
#' # Convert 25.4 millimeters to inches
#' convert_prcp(25.4, "mm", "in")
convert_prcp <- function(x, from, to) {
  .check_x_numeric(x)
  opts <- c("mm", "cm", "in")
  inputs <- .validate_unit_inputs(from, to, opts)
  if (inputs$from == inputs$to) {
    return(x)
  }

  key <- paste(inputs$from, inputs$to, sep = "_to_")
  .prcp_conversions[[key]](x)
}

.prcp_conversions <- list(
  `mm_to_cm` = function(x) x / 10,
  `mm_to_in` = function(x) x / 25.4,
  `cm_to_in` = function(x) x / 2.54,
  `cm_to_mm` = function(x) x * 10,
  `in_to_mm` = function(x) x * 25.4,
  `in_to_cm` = function(x) x * 2.54
)

# Wind Speed --------------------------------------------------------------

#' Convert between common wind speed units
#'
#' This function converts between common wind speed units: meters per second
#' (m/s), kilometers per hour (km/h), miles per hour (mph), knots, feet per
#' second (ft/s), or beaufort. Note that conversions to and from the Beaufort
#' scale are 'destructive' in that they involve binning wind speed, which
#' reduces precision.
#'
#' @param x A numeric vector of wind speeds to convert.
#'
#' @param from,to The units to convert from and to. Must be one of `"m/s"`,
#'   `"km/h"`, `"mph"`, `"knots"`, `"ft/s"`, or `"beaufort"`. These options are
#'   case-insensitive.
#'
#' @family meteorological unit conversion functions
#' @export
#'
#' @return A numeric vector of the same length as `x` containing the
#'   converted values. `NA` values are preserved.
#'
#' @examples
#' # Convert 10 meters per second to kilometers per hour
#' convert_ws(10, "m/s", "km/h")
convert_ws <- function(x, from, to) {
  .check_x_numeric(x)
  opts <- c("m/s", "km/h", "mph", "knots", "ft/s", "beaufort")
  inputs <- .validate_unit_inputs(from, to, opts)
  if (inputs$from == inputs$to) {
    return(x)
  }

  # if coming from beaufort, convert to m/s first
  if (inputs$from == "beaufort") {
    # convert to m/s first using the standard conversion table
    x <- ifelse(x >= length(.beaufort_table), NA, .beaufort_table[x + 1])
    inputs$from <- "m/s"
  }

  # if going to Beaufort, convert to m/s first then turn into Beaufort using
  # lookup
  if (inputs$to == "beaufort") {
    # convert to m/s first
    if (inputs$from != "m/s") {
      key <- paste(inputs$from, "m/s", sep = "_to_")
      x <- .ws_conversions[[key]](x)
    }
    x <- findInterval(x, .beaufort_table, rightmost.closed = FALSE) - 1
    return(x)
  }

  # if units are the same after handling Beaufort, return x
  if (inputs$from == inputs$to) {
    return(x)
  }

  # otherwise we can use the faster conversion functions
  key <- paste(inputs$from, inputs$to, sep = "_to_")
  return(.ws_conversions[[key]](x))
}

.ws_conversions <- list(
  `m/s_to_km/h` = function(x) x * 3.6,
  `m/s_to_mph` = function(x) x / 0.44704,
  `m/s_to_knots` = function(x) x / 0.514444,
  `m/s_to_ft/s` = function(x) x / 0.3048,
  `km/h_to_m/s` = function(x) x / 3.6,
  `km/h_to_knots` = function(x) x / 1.852,
  `km/h_to_mph` = function(x) x / 1.609344,
  `km/h_to_ft/s` = function(x) x / 1.09728,
  `mph_to_m/s` = function(x) x * 0.44704,
  `mph_to_km/h` = function(x) x * 1.609344,
  `mph_to_knots` = function(x) x / 1.150779,
  `mph_to_ft/s` = function(x) x * 1.466667,
  `knots_to_m/s` = function(x) x * 0.514444,
  `knots_to_km/h` = function(x) x * 1.852,
  `knots_to_mph` = function(x) x * 1.150779,
  `knots_to_ft/s` = function(x) x * 0.592484,
  `ft/s_to_m/s` = function(x) x * 0.3048,
  `ft/s_to_km/h` = function(x) x * 1.09728,
  `ft/s_to_mph` = function(x) x / 1.466667,
  `ft/s_to_knots` = function(x) x / 0.592484
)

.beaufort_table <- c(
  0,
  0.3,
  1.5,
  3.3,
  5.5,
  8,
  10.8,
  13.9,
  17.2,
  20.8,
  24.5,
  28.5,
  32.7
)


# Wind Direction ----------------------------------------------------------

#' Convert between common wind direction units
#'
#' This function converts between common wind direction units: degrees and
#' compass directions. The `resolution` argument specifies the number of compass
#' points to use when converting to or from compass directions (e.g., `4` for
#' N/E/S/W, `8` for N/NE/E/SE/S/SW/W/NW, etc.). Note that conversions to and
#' from compass directions are 'destructive' in that they involve binning wind
#' direction, which reduces precision.
#'
#' @param x A numeric vector of wind directions to convert. If `from` is
#'   "compass", this should be a character vector of compass directions (e.g.,
#'   "N", "NE", etc.).
#'
#' @param from,to The units to convert from and to. Must be one of `"degrees"`,
#'   `"radians"`, or `"compass"`. These options are case-insensitive.
#'
#' @param resolution The number of compass points to use when converting to or
#'   from compass directions. Must be one of `4`, `8`, `16`, or `32`. The
#'   default is `8`, which corresponds to the standard 8-point compass
#'   (N/NE/E/SE/S/SW/W/NW).
#'
#' @family meteorological unit conversion functions
#' @export
#'
#' @return A numeric vector of the same length as `x` containing the converted
#'   values, or a factor vector if `to = "compass"`. `NA` values are preserved.
#'
#' @examples
#' # Convert 90 degrees to compass direction with 8-point resolution
#' convert_wd(90, "degrees", "compass")
convert_wd <- function(x, from, to, resolution = 8) {
  opts <- c("degrees", "radians", "compass")
  inputs <- .validate_unit_inputs(from, to, opts)

  if (inputs$from == inputs$to) {
    return(x)
  }

  # Input validation based on 'from' unit
  if (inputs$from == "compass") {
    .check_x_character(x)
    # Convert factor to character for consistent processing
    if (is.factor(x)) {
      x <- as.character(x)
    }
  } else {
    .check_x_numeric(x)
  }

  # Validate resolution (only needed for compass conversions)
  if (inputs$from == "compass" || inputs$to == "compass") {
    resolution <- as.character(resolution)
    resolution <- rlang::arg_match(resolution, as.character(c(4, 8, 16, 32)))
    directions <- .compass_table[[resolution]]
    resolution <- as.numeric(resolution)
  }

  # Convert everything to degrees first (as intermediate step)
  if (inputs$from == "radians") {
    x <- x * 180 / pi
    inputs$from <- "degrees"
  } else if (inputs$from == "compass") {
    # Validate compass directions
    check_x <- x[!is.na(x) & !is.infinite(x)]
    if (!all(check_x %in% directions)) {
      flag <- unique(check_x[!check_x %in% directions])
      cli::cli_abort(
        c(
          "!" = "{.arg x} must be one of {directions}",
          "i" = "Bad values: {flag}",
          "i" = "Do you need to adjust {.arg resolution}?"
        )
      )
    }
    x <- match(x, directions)
    x <- (x - 1) * (360 / resolution)
    inputs$from <- "degrees"
  }

  # Now x is in degrees; convert to target unit
  if (inputs$to == "radians") {
    x <- x * pi / 180
  } else if (inputs$to == "compass") {
    resolution <- 360 / resolution
    x <- (x + resolution / 2) %% 360
    x <- floor(x / resolution) + 1
    x <- directions[x]
    x <- factor(x, levels = directions)
  }

  x
}

.compass_table <- list(
  `4` = c("N", "E", "S", "W"),
  `8` = c("N", "NE", "E", "SE", "S", "SW", "W", "NW"),
  `16` = c(
    "N",
    "NNE",
    "NE",
    "ENE",
    "E",
    "ESE",
    "SE",
    "SSE",
    "S",
    "SSW",
    "SW",
    "WSW",
    "W",
    "WNW",
    "NW",
    "NNW"
  ),
  `32` = c(
    "N",
    "NbE",
    "NNE",
    "NEbN",
    "NE",
    "NEbE",
    "ENE",
    "EbN",
    "E",
    "EbS",
    "ESE",
    "SEbE",
    "SE",
    "SEbS",
    "SSE",
    "SbE",
    "S",
    "SbW",
    "SSW",
    "SWbS",
    "SW",
    "SWbW",
    "WSW",
    "WbS",
    "W",
    "WbN",
    "WNW",
    "NWbW",
    "NW",
    "NWbN",
    "NNW",
    "NbW"
  )
)


# Utils -------------------------------------------------------------------

# check inputs for all conversion functions
.validate_unit_inputs <- function(from, to, opts) {
  from <- tolower(from)
  from <- rlang::arg_match(from, opts)

  to <- tolower(to)
  to <- rlang::arg_match(to, opts)

  return(list(to = to, from = from))
}

# check is numeric
.check_x_numeric <- function(x) {
  if (!all(is.na(x))) {
    if (!is.numeric(x)) {
      cli::cli_abort("{.arg x} must be numeric.")
    }
  }
}

# check is character or factor
.check_x_character <- function(x) {
  if (!all(is.na(x))) {
    if (!(is.character(x) || is.factor(x))) {
      cli::cli_abort(
        '{.arg x} must be a character or factor if {.arg from = "compass"}.'
      )
    }
  }
}
