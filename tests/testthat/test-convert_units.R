# ---- Temperature Tests ----

test_that("convert_temp handles basic conversions correctly", {
  # Celsius to Fahrenheit
  expect_equal(convert_temp(0, "c", "f"), 32)
  expect_equal(convert_temp(100, "c", "f"), 212)
  expect_equal(convert_temp(-40, "c", "f"), -40)

  # Fahrenheit to Celsius
  expect_equal(convert_temp(32, "f", "c"), 0)
  expect_equal(convert_temp(212, "f", "c"), 100)
  expect_equal(convert_temp(-40, "f", "c"), -40)

  # Celsius to Kelvin
  expect_equal(convert_temp(0, "c", "k"), 273.15)
  expect_equal(convert_temp(-273.15, "c", "k"), 0)
  expect_equal(convert_temp(100, "c", "k"), 373.15)

  # Kelvin to Celsius
  expect_equal(convert_temp(273.15, "k", "c"), 0)
  expect_equal(convert_temp(0, "k", "c"), -273.15)
  expect_equal(convert_temp(373.15, "k", "c"), 100)

  # Fahrenheit to Kelvin
  expect_equal(convert_temp(32, "f", "k"), 273.15)
  expect_equal(convert_temp(-459.67, "f", "k"), 0, tolerance = 1e-10)

  # Kelvin to Fahrenheit
  expect_equal(convert_temp(273.15, "k", "f"), 32)
  expect_equal(convert_temp(0, "k", "f"), -459.67, tolerance = 1e-10)
})

test_that("convert_temp handles same unit conversions", {
  expect_equal(convert_temp(25, "c", "c"), 25)
  expect_equal(convert_temp(77, "f", "f"), 77)
  expect_equal(convert_temp(300, "k", "k"), 300)
})

test_that("convert_temp is vectorized", {
  temps_c <- c(-40, 0, 20, 37, 100)
  temps_f <- c(-40, 32, 68, 98.6, 212)

  expect_equal(convert_temp(temps_c, "c", "f"), temps_f)
  expect_equal(convert_temp(temps_f, "f", "c"), temps_c)
})

test_that("convert_temp handles NA values", {
  expect_equal(convert_temp(NA, "c", "f"), NA_real_)
  expect_equal(convert_temp(c(0, NA, 100), "c", "f"), c(32, NA, 212))
  expect_equal(
    convert_temp(c(NA, NA, NA), "c", "f"),
    c(NA_real_, NA_real_, NA_real_)
  )
})

test_that("convert_temp is case-insensitive", {
  expect_equal(convert_temp(0, "C", "F"), 32)
  expect_equal(convert_temp(0, "c", "F"), 32)
  expect_equal(convert_temp(0, "C", "f"), 32)
  expect_equal(convert_temp(273.15, "K", "C"), 0)
})

test_that("convert_temp handles edge cases", {
  # Infinite values
  expect_equal(convert_temp(Inf, "c", "f"), Inf)
  expect_equal(convert_temp(-Inf, "c", "f"), -Inf)

  # Very large/small numbers
  expect_equal(convert_temp(1e6, "c", "f"), 1e6 * 9 / 5 + 32)
  expect_equal(convert_temp(-1e6, "k", "c"), -1e6 - 273.15)
})

test_that("convert_temp round-trip conversions are accurate", {
  original <- c(-40, 0, 25, 100)

  # C -> F -> C
  expect_equal(
    convert_temp(convert_temp(original, "c", "f"), "f", "c"),
    original
  )

  # C -> K -> C
  expect_equal(
    convert_temp(convert_temp(original, "c", "k"), "k", "c"),
    original
  )

  # F -> K -> F
  expect_equal(
    convert_temp(convert_temp(original, "f", "k"), "k", "f"),
    original,
    tolerance = 1e-10
  )
})

test_that("convert_temp errors on invalid units", {
  expect_error(convert_temp(0, "x", "f"))
  expect_error(convert_temp(0, "c", "y"))
  expect_error(convert_temp(0, "celsius", "fahrenheit"))
})


# ---- Wind Speed Tests ----

test_that("convert_ws handles basic conversions correctly", {
  # m/s to km/h
  expect_equal(convert_ws(10, "m/s", "km/h"), 36)

  # m/s to mph
  expect_equal(convert_ws(10, "m/s", "mph"), 10 / 0.44704, tolerance = 1e-10)

  # m/s to knots
  expect_equal(convert_ws(10, "m/s", "knots"), 10 / 0.514444, tolerance = 1e-10)

  # m/s to ft/s
  expect_equal(convert_ws(10, "m/s", "ft/s"), 10 / 0.3048, tolerance = 1e-10)

  # km/h to m/s
  expect_equal(convert_ws(36, "km/h", "m/s"), 10)

  # mph to m/s
  expect_equal(
    convert_ws(22.369, "mph", "m/s"),
    22.369 * 0.44704,
    tolerance = 1e-10
  )

  # knots to m/s
  expect_equal(
    convert_ws(19.438, "knots", "m/s"),
    19.438 * 0.514444,
    tolerance = 1e-10
  )

  # ft/s to m/s
  expect_equal(
    convert_ws(32.808, "ft/s", "m/s"),
    32.808 * 0.3048,
    tolerance = 1e-10
  )
})

test_that("convert_ws handles same unit conversions", {
  expect_equal(convert_ws(10, "m/s", "m/s"), 10)
  expect_equal(convert_ws(50, "km/h", "km/h"), 50)
  expect_equal(convert_ws(20, "mph", "mph"), 20)
  expect_equal(convert_ws(15, "knots", "knots"), 15)
})

test_that("convert_ws handles Beaufort scale conversions", {
  # Beaufort to m/s
  expect_equal(convert_ws(0, "beaufort", "m/s"), 0)
  expect_equal(convert_ws(1, "beaufort", "m/s"), 0.3)
  expect_equal(convert_ws(5, "beaufort", "m/s"), 8)
  expect_equal(convert_ws(12, "beaufort", "m/s"), 32.7)

  # Out of range Beaufort
  expect_equal(convert_ws(13, "beaufort", "m/s"), NA)
  expect_equal(convert_ws(100, "beaufort", "m/s"), NA)

  # m/s to Beaufort
  expect_equal(convert_ws(0, "m/s", "beaufort"), 0)
  expect_equal(convert_ws(1, "m/s", "beaufort"), 1)
  expect_equal(convert_ws(5, "m/s", "beaufort"), 3)
  expect_equal(convert_ws(10, "m/s", "beaufort"), 5)
  expect_equal(convert_ws(20, "m/s", "beaufort"), 8)
  expect_equal(convert_ws(35, "m/s", "beaufort"), 12)
})

test_that("convert_ws is vectorized", {
  ws_ms <- c(0, 5, 10, 15, 20)
  ws_kmh <- c(0, 18, 36, 54, 72)

  expect_equal(convert_ws(ws_ms, "m/s", "km/h"), ws_kmh)
  expect_equal(convert_ws(ws_kmh, "km/h", "m/s"), ws_ms)
})

test_that("convert_ws handles NA values", {
  expect_equal(convert_ws(NA, "m/s", "km/h"), NA_real_)
  expect_equal(convert_ws(c(10, NA, 20), "m/s", "km/h"), c(36, NA, 72))

  # NA in Beaufort conversions
  expect_equal(convert_ws(NA, "beaufort", "m/s"), NA)
  expect_equal(convert_ws(NA, "m/s", "beaufort"), NA_real_)
})

test_that("convert_ws is case-insensitive", {
  expect_equal(convert_ws(10, "M/S", "KM/H"), 36)
  expect_equal(convert_ws(10, "m/s", "KM/H"), 36)
  expect_equal(convert_ws(10, "M/S", "km/h"), 36)
})

test_that("convert_ws round-trip conversions are accurate", {
  original <- c(0, 5, 10, 15, 20)

  # m/s -> km/h -> m/s
  expect_equal(
    convert_ws(convert_ws(original, "m/s", "km/h"), "km/h", "m/s"),
    original
  )

  # m/s -> mph -> m/s
  expect_equal(
    convert_ws(convert_ws(original, "m/s", "mph"), "mph", "m/s"),
    original,
    tolerance = 1e-10
  )

  # m/s -> knots -> m/s
  expect_equal(
    convert_ws(convert_ws(original, "m/s", "knots"), "knots", "m/s"),
    original,
    tolerance = 1e-10
  )
})

test_that("convert_ws Beaufort conversions are lossy", {
  # Beaufort is a binned scale, so round-trips are not exact
  original_beaufort <- c(0, 3, 6, 9, 12)
  ms <- convert_ws(original_beaufort, "beaufort", "m/s")
  back_to_beaufort <- convert_ws(ms, "m/s", "beaufort")

  # Should get back the same Beaufort numbers
  expect_equal(back_to_beaufort, original_beaufort)

  # But going from m/s to Beaufort and back loses precision
  original_ms <- c(5.5, 10.5, 15.5)
  beaufort <- convert_ws(original_ms, "m/s", "beaufort")
  back_to_ms <- convert_ws(beaufort, "beaufort", "m/s")

  # Won't be equal
  expect_false(all(original_ms == back_to_ms))
})

test_that("convert_ws errors on invalid units", {
  expect_error(convert_ws(10, "x", "m/s"))
  expect_error(convert_ws(10, "m/s", "y"))
})


# ---- Wind Direction Tests ----

test_that("convert_wd handles degrees to compass conversions", {
  # 8-point compass (default)
  expect_equal(as.character(convert_wd(0, "degrees", "compass")), "N")
  expect_equal(as.character(convert_wd(45, "degrees", "compass")), "NE")
  expect_equal(as.character(convert_wd(90, "degrees", "compass")), "E")
  expect_equal(as.character(convert_wd(135, "degrees", "compass")), "SE")
  expect_equal(as.character(convert_wd(180, "degrees", "compass")), "S")
  expect_equal(as.character(convert_wd(225, "degrees", "compass")), "SW")
  expect_equal(as.character(convert_wd(270, "degrees", "compass")), "W")
  expect_equal(as.character(convert_wd(315, "degrees", "compass")), "NW")
  expect_equal(as.character(convert_wd(360, "degrees", "compass")), "N")

  # 4-point compass
  expect_equal(
    as.character(convert_wd(0, "degrees", "compass", resolution = 4)),
    "N"
  )
  expect_equal(
    as.character(convert_wd(90, "degrees", "compass", resolution = 4)),
    "E"
  )
  expect_equal(
    as.character(convert_wd(180, "degrees", "compass", resolution = 4)),
    "S"
  )
  expect_equal(
    as.character(convert_wd(270, "degrees", "compass", resolution = 4)),
    "W"
  )

  # 16-point compass
  expect_equal(
    as.character(convert_wd(0, "degrees", "compass", resolution = 16)),
    "N"
  )
  expect_equal(
    as.character(convert_wd(22.5, "degrees", "compass", resolution = 16)),
    "NNE"
  )
  expect_equal(
    as.character(convert_wd(45, "degrees", "compass", resolution = 16)),
    "NE"
  )
  expect_equal(
    as.character(convert_wd(67.5, "degrees", "compass", resolution = 16)),
    "ENE"
  )
})

test_that("convert_wd compass output is a factor", {
  result <- convert_wd(90, "degrees", "compass")
  expect_true(is.factor(result))
  expect_equal(levels(result), c("N", "NE", "E", "SE", "S", "SW", "W", "NW"))

  # 4-point compass has correct levels
  result_4 <- convert_wd(90, "degrees", "compass", resolution = 4)
  expect_true(is.factor(result_4))
  expect_equal(levels(result_4), c("N", "E", "S", "W"))
})

test_that("convert_wd handles compass to degrees conversions", {
  # 8-point compass
  expect_equal(convert_wd("N", "compass", "degrees"), 0)
  expect_equal(convert_wd("NE", "compass", "degrees"), 45)
  expect_equal(convert_wd("E", "compass", "degrees"), 90)
  expect_equal(convert_wd("SE", "compass", "degrees"), 135)
  expect_equal(convert_wd("S", "compass", "degrees"), 180)
  expect_equal(convert_wd("SW", "compass", "degrees"), 225)
  expect_equal(convert_wd("W", "compass", "degrees"), 270)
  expect_equal(convert_wd("NW", "compass", "degrees"), 315)

  # 4-point compass
  expect_equal(convert_wd("N", "compass", "degrees", resolution = 4), 0)
  expect_equal(convert_wd("E", "compass", "degrees", resolution = 4), 90)
  expect_equal(convert_wd("S", "compass", "degrees", resolution = 4), 180)
  expect_equal(convert_wd("W", "compass", "degrees", resolution = 4), 270)

  # 16-point compass
  expect_equal(convert_wd("NNE", "compass", "degrees", resolution = 16), 22.5)
  expect_equal(convert_wd("ENE", "compass", "degrees", resolution = 16), 67.5)
})

test_that("convert_wd handles degree wrapping correctly", {
  # Test that degrees near boundaries map correctly
  expect_equal(as.character(convert_wd(359, "degrees", "compass")), "N")
  expect_equal(as.character(convert_wd(1, "degrees", "compass")), "N")
  expect_equal(as.character(convert_wd(22, "degrees", "compass")), "N")
  expect_equal(as.character(convert_wd(23, "degrees", "compass")), "NE")
  expect_equal(as.character(convert_wd(67, "degrees", "compass")), "NE")
  expect_equal(as.character(convert_wd(68, "degrees", "compass")), "E")
})

test_that("convert_wd handles same unit conversions", {
  expect_equal(convert_wd(90, "degrees", "degrees"), 90)
  # Compass to compass returns character, not factor
  expect_equal(convert_wd("NE", "compass", "compass"), "NE")
})

test_that("convert_wd is vectorized", {
  degrees <- c(0, 45, 90, 135, 180)
  compass <- c("N", "NE", "E", "SE", "S")

  result <- convert_wd(degrees, "degrees", "compass")
  expect_equal(as.character(result), compass)
  expect_true(is.factor(result))

  expect_equal(convert_wd(compass, "compass", "degrees"), degrees)
})

test_that("convert_wd handles NA values", {
  # NA in compass output should still be NA
  result <- convert_wd(NA, "degrees", "compass")
  expect_true(is.na(result))
  expect_true(is.factor(result))

  result_vec <- convert_wd(c(0, NA, 90), "degrees", "compass")
  expect_equal(as.character(result_vec), c("N", NA, "E"))
  expect_true(is.factor(result_vec))
})

test_that("convert_wd is case-insensitive", {
  expect_equal(as.character(convert_wd(90, "DEGREES", "COMPASS")), "E")
  expect_equal(as.character(convert_wd(90, "degrees", "COMPASS")), "E")
  expect_equal(convert_wd("N", "COMPASS", "degrees"), 0)
})

test_that("convert_wd round-trip conversions work for exact compass points", {
  # For exact compass points, round trips should work
  compass_8 <- c("N", "NE", "E", "SE", "S", "SW", "W", "NW")
  degrees <- convert_wd(compass_8, "compass", "degrees")
  back_to_compass <- convert_wd(degrees, "degrees", "compass")
  expect_equal(as.character(back_to_compass), compass_8)
  expect_true(is.factor(back_to_compass))
})

test_that("convert_wd compass conversions are lossy", {
  # Arbitrary degrees lose precision when converted to compass
  original_degrees <- c(10, 50, 100, 200)
  compass <- convert_wd(original_degrees, "degrees", "compass")
  back_to_degrees <- convert_wd(as.character(compass), "compass", "degrees")

  # Won't be equal due to binning
  expect_false(all(original_degrees == back_to_degrees))
})

test_that("convert_wd errors on invalid units", {
  expect_error(convert_wd(90, "x", "compass"))
  expect_error(convert_wd(90, "degrees", "y"))
})

test_that("convert_wd errors on invalid resolution", {
  expect_error(convert_wd(90, "degrees", "compass", resolution = 3))
  expect_error(convert_wd(90, "degrees", "compass", resolution = 10))
})

test_that("convert_wd handles degrees to radians conversions", {
  # Basic conversions
  expect_equal(convert_wd(0, "degrees", "radians"), 0)
  expect_equal(convert_wd(90, "degrees", "radians"), pi / 2)
  expect_equal(convert_wd(180, "degrees", "radians"), pi)
  expect_equal(convert_wd(270, "degrees", "radians"), 3 * pi / 2)
  expect_equal(convert_wd(360, "degrees", "radians"), 2 * pi)

  # Negative angles
  expect_equal(convert_wd(-90, "degrees", "radians"), -pi / 2)
})

test_that("convert_wd handles radians to degrees conversions", {
  # Basic conversions
  expect_equal(convert_wd(0, "radians", "degrees"), 0)
  expect_equal(convert_wd(pi / 2, "radians", "degrees"), 90)
  expect_equal(convert_wd(pi, "radians", "degrees"), 180)
  expect_equal(convert_wd(3 * pi / 2, "radians", "degrees"), 270)
  expect_equal(convert_wd(2 * pi, "radians", "degrees"), 360)

  # Negative angles
  expect_equal(convert_wd(-pi / 2, "radians", "degrees"), -90)
})

test_that("convert_wd handles radians to compass conversions", {
  # 8-point compass
  expect_equal(as.character(convert_wd(0, "radians", "compass")), "N")
  expect_equal(as.character(convert_wd(pi / 2, "radians", "compass")), "E")
  expect_equal(as.character(convert_wd(pi, "radians", "compass")), "S")
  expect_equal(as.character(convert_wd(3 * pi / 2, "radians", "compass")), "W")
  expect_equal(as.character(convert_wd(pi / 4, "radians", "compass")), "NE")

  # 4-point compass
  expect_equal(
    as.character(convert_wd(0, "radians", "compass", resolution = 4)),
    "N"
  )
  expect_equal(
    as.character(convert_wd(pi / 2, "radians", "compass", resolution = 4)),
    "E"
  )
})

test_that("convert_wd handles compass to radians conversions", {
  # 8-point compass
  expect_equal(convert_wd("N", "compass", "radians"), 0)
  expect_equal(convert_wd("E", "compass", "radians"), pi / 2)
  expect_equal(convert_wd("S", "compass", "radians"), pi)
  expect_equal(convert_wd("W", "compass", "radians"), 3 * pi / 2)
  expect_equal(convert_wd("NE", "compass", "radians"), pi / 4)
  expect_equal(convert_wd("SE", "compass", "radians"), 3 * pi / 4)
})

test_that("convert_wd round-trip conversions with radians are accurate", {
  # degrees -> radians -> degrees
  original_degrees <- c(0, 45, 90, 135, 180, 225, 270, 315)
  radians <- convert_wd(original_degrees, "degrees", "radians")
  back_to_degrees <- convert_wd(radians, "radians", "degrees")
  expect_equal(back_to_degrees, original_degrees)

  # radians -> degrees -> radians
  original_radians <- c(
    0,
    pi / 4,
    pi / 2,
    3 * pi / 4,
    pi,
    5 * pi / 4,
    3 * pi / 2,
    7 * pi / 4
  )
  degrees <- convert_wd(original_radians, "radians", "degrees")
  back_to_radians <- convert_wd(degrees, "degrees", "radians")
  expect_equal(back_to_radians, original_radians)

  # compass -> radians -> compass (for exact compass points)
  compass_8 <- c("N", "NE", "E", "SE", "S", "SW", "W", "NW")
  radians <- convert_wd(compass_8, "compass", "radians")
  back_to_compass <- convert_wd(radians, "radians", "compass")
  expect_equal(as.character(back_to_compass), compass_8)
  expect_true(is.factor(back_to_compass))
})

test_that("convert_wd handles same unit conversions with radians", {
  expect_equal(convert_wd(pi, "radians", "radians"), pi)
  expect_equal(
    convert_wd(c(0, pi / 2, pi), "radians", "radians"),
    c(0, pi / 2, pi)
  )
})

test_that("convert_wd is vectorized with radians", {
  degrees <- c(0, 45, 90, 135, 180)
  radians <- c(0, pi / 4, pi / 2, 3 * pi / 4, pi)

  expect_equal(convert_wd(degrees, "degrees", "radians"), radians)
  expect_equal(convert_wd(radians, "radians", "degrees"), degrees)
})

test_that("convert_wd handles NA values with radians", {
  expect_equal(convert_wd(NA, "degrees", "radians"), NA_real_)
  expect_equal(convert_wd(NA, "radians", "degrees"), NA_real_)
  expect_equal(convert_wd(c(0, NA, pi), "radians", "degrees"), c(0, NA, 180))
  expect_equal(convert_wd(c(0, NA, 180), "degrees", "radians"), c(0, NA, pi))
})

test_that("convert_wd handles edge cases with radians", {
  # Very small angles
  expect_equal(
    convert_wd(0.0001, "degrees", "radians"),
    0.0001 * pi / 180,
    tolerance = 1e-10
  )
  expect_equal(
    convert_wd(0.0001, "radians", "degrees"),
    0.0001 * 180 / pi,
    tolerance = 1e-10
  )

  # Large angles (beyond 360° / 2π)
  expect_equal(convert_wd(720, "degrees", "radians"), 4 * pi)
  expect_equal(convert_wd(4 * pi, "radians", "degrees"), 720)

  # Negative angles
  expect_equal(convert_wd(-45, "degrees", "radians"), -pi / 4)
  expect_equal(convert_wd(-pi / 4, "radians", "degrees"), -45)

  # Infinite values
  expect_equal(convert_wd(Inf, "degrees", "radians"), Inf)
  expect_equal(convert_wd(-Inf, "radians", "degrees"), -Inf)
})

test_that("convert_wd is case-insensitive with radians", {
  expect_equal(convert_wd(90, "DEGREES", "RADIANS"), pi / 2)
  expect_equal(convert_wd(pi, "RADIANS", "DEGREES"), 180)
  expect_equal(convert_wd(90, "degrees", "RADIANS"), pi / 2)
})

test_that("convert_wd errors appropriately with radians", {
  # Wrong input type
  expect_error(convert_wd("hello", "radians", "degrees"))
  expect_error(convert_wd("hello", "degrees", "radians"))

  # Invalid unit names
  expect_error(convert_wd(1, "radian", "degrees")) # missing 's'
  expect_error(convert_wd(1, "rad", "degrees")) # abbreviation not supported
})

test_that("convert_wd preserves precision with radians", {
  # Test that conversion doesn't lose precision
  test_values <- c(
    pi / 6,
    pi / 3,
    2 * pi / 3,
    5 * pi / 6,
    7 * pi / 6,
    4 * pi / 3,
    5 * pi / 3,
    11 * pi / 6
  )

  # Convert to degrees and back
  degrees <- convert_wd(test_values, "radians", "degrees")
  back <- convert_wd(degrees, "degrees", "radians")

  expect_equal(back, test_values, tolerance = 1e-10)
})

test_that("convert_wd handles special radian values", {
  # Common radian values
  expect_equal(convert_wd(pi / 6, "radians", "degrees"), 30)
  expect_equal(convert_wd(pi / 3, "radians", "degrees"), 60)
  expect_equal(convert_wd(pi / 4, "radians", "degrees"), 45)
  expect_equal(convert_wd(2 * pi / 3, "radians", "degrees"), 120)
  expect_equal(convert_wd(5 * pi / 6, "radians", "degrees"), 150)

  # Back to radians
  expect_equal(convert_wd(30, "degrees", "radians"), pi / 6)
  expect_equal(convert_wd(60, "degrees", "radians"), pi / 3)
  expect_equal(convert_wd(45, "degrees", "radians"), pi / 4)
})

test_that("convert_wd factor input works with radians", {
  # When converting from compass, factors should be handled
  compass_factor <- factor(
    c("N", "E", "S", "W"),
    levels = c("N", "E", "S", "W")
  )
  result <- convert_wd(compass_factor, "compass", "radians", resolution = 4)
  expected <- c(0, pi / 2, pi, 3 * pi / 2)
  expect_equal(result, expected)
})

test_that("convert_wd compass output is factor with radians input", {
  # When converting to compass, output should be factor
  result <- convert_wd(c(0, pi / 2, pi), "radians", "compass")
  expect_true(is.factor(result))
  expect_equal(levels(result), c("N", "NE", "E", "SE", "S", "SW", "W", "NW"))
  expect_equal(as.character(result), c("N", "E", "S"))
})

test_that("convert_wd resolution doesn't affect non-compass conversions", {
  # Resolution parameter should be ignored for degrees <-> radians
  expect_equal(
    convert_wd(90, "degrees", "radians", resolution = 4),
    convert_wd(90, "degrees", "radians", resolution = 32)
  )

  expect_equal(
    convert_wd(pi, "radians", "degrees", resolution = 4),
    convert_wd(pi, "radians", "degrees", resolution = 32)
  )
})

test_that("convert_wd errors on invalid compass directions", {
  # Should error when compass direction doesn't match resolution
  expect_error(
    convert_wd("NNE", "compass", "degrees", resolution = 8),
    "must be one of"
  )

  expect_error(
    convert_wd(c("N", "NNE", "E"), "compass", "degrees", resolution = 8),
    "Bad values"
  )
})

test_that("convert_wd preserves factor levels correctly", {
  # Levels should match the resolution
  result_4 <- convert_wd(
    c(0, 90, 180, 270),
    "degrees",
    "compass",
    resolution = 4
  )
  expect_equal(levels(result_4), c("N", "E", "S", "W"))

  result_8 <- convert_wd(c(0, 45, 90), "degrees", "compass", resolution = 8)
  expect_equal(levels(result_8), c("N", "NE", "E", "SE", "S", "SW", "W", "NW"))

  result_16 <- convert_wd(0, "degrees", "compass", resolution = 16)
  expect_equal(length(levels(result_16)), 16)
})

# ---- Pressure Tests ----

test_that("convert_pres handles basic conversions correctly", {
  # hPa to inHg
  expect_equal(
    convert_pres(1013.25, "hpa", "inhg"),
    1013.25 / 33.8639,
    tolerance = 1e-10
  )

  # inHg to hPa
  expect_equal(
    convert_pres(29.92, "inhg", "hpa"),
    29.92 * 33.8639,
    tolerance = 1e-10
  )

  # hPa to mmHg
  expect_equal(
    convert_pres(1013.25, "hpa", "mmhg"),
    1013.25 / 1.33322,
    tolerance = 1e-10
  )

  # mmHg to hPa
  expect_equal(
    convert_pres(760, "mmhg", "hpa"),
    760 * 1.33322,
    tolerance = 1e-10
  )

  # mb to inHg (mb == hPa)
  expect_equal(
    convert_pres(1013.25, "mb", "inhg"),
    1013.25 / 33.8639,
    tolerance = 1e-10
  )

  # inHg to mmHg (via hPa)
  result <- convert_pres(29.92, "inhg", "mmhg")
  expected <- 29.92 * 25.4
  expect_equal(result, expected, tolerance = 1e-10)
})

test_that("convert_pres handles same unit conversions", {
  expect_equal(convert_pres(1013.25, "hpa", "hpa"), 1013.25)
  expect_equal(convert_pres(1013.25, "mb", "mb"), 1013.25)
  expect_equal(convert_pres(29.92, "inhg", "inhg"), 29.92)
  expect_equal(convert_pres(760, "mmhg", "mmhg"), 760)

  # hPa and mb are equivalent
  expect_equal(convert_pres(1013.25, "hpa", "mb"), 1013.25)
  expect_equal(convert_pres(1013.25, "mb", "hpa"), 1013.25)
})

test_that("convert_pres is vectorized", {
  hpa <- c(1000, 1010, 1020, 1030)
  inhg <- hpa / 33.8639

  expect_equal(convert_pres(hpa, "hpa", "inhg"), inhg, tolerance = 1e-10)
  expect_equal(convert_pres(inhg, "inhg", "hpa"), hpa, tolerance = 1e-10)
})

test_that("convert_pres handles NA values", {
  expect_equal(convert_pres(NA, "hpa", "inhg"), NA_real_)
  expect_equal(
    convert_pres(c(1013, NA, 1020), "hpa", "inhg"),
    c(1013, NA, 1020) / 33.8639,
    tolerance = 1e-10
  )
})

test_that("convert_pres is case-insensitive", {
  expect_equal(
    convert_pres(1013.25, "HPA", "INHG"),
    1013.25 / 33.8639,
    tolerance = 1e-10
  )
  expect_equal(
    convert_pres(1013.25, "hpa", "INHG"),
    1013.25 / 33.8639,
    tolerance = 1e-10
  )
  expect_equal(
    convert_pres(1013.25, "Mb", "mmHg"),
    1013.25 / 1.33322,
    tolerance = 1e-10
  )
})

test_that("convert_pres round-trip conversions are accurate", {
  original <- c(1000, 1013.25, 1020, 1030)

  # hPa -> inHg -> hPa
  expect_equal(
    convert_pres(convert_pres(original, "hpa", "inhg"), "inhg", "hpa"),
    original,
    tolerance = 1e-10
  )

  # hPa -> mmHg -> hPa
  expect_equal(
    convert_pres(convert_pres(original, "hpa", "mmhg"), "mmhg", "hpa"),
    original,
    tolerance = 1e-10
  )

  # inHg -> mmHg -> inHg
  original_inhg <- c(29.5, 29.92, 30.0, 30.5)
  expect_equal(
    convert_pres(convert_pres(original_inhg, "inhg", "mmhg"), "mmhg", "inhg"),
    original_inhg,
    tolerance = 1e-10
  )
})

test_that("convert_pres errors on invalid units", {
  expect_error(convert_pres(1013.25, "x", "hpa"))
  expect_error(convert_pres(1013.25, "hpa", "y"))
  expect_error(convert_pres(1013.25, "pa", "hpa")) # pa not supported
})


# ---- Precipitation Tests ----

test_that("convert_prcp handles basic conversions correctly", {
  # mm to inches
  expect_equal(convert_prcp(25.4, "mm", "in"), 1)
  expect_equal(convert_prcp(100, "mm", "in"), 100 / 25.4, tolerance = 1e-10)

  # inches to mm
  expect_equal(convert_prcp(1, "in", "mm"), 25.4)
  expect_equal(convert_prcp(2.5, "in", "mm"), 2.5 * 25.4)

  # mm to cm
  expect_equal(convert_prcp(100, "mm", "cm"), 10)
  expect_equal(convert_prcp(25.4, "mm", "cm"), 2.54)

  # cm to mm
  expect_equal(convert_prcp(10, "cm", "mm"), 100)
  expect_equal(convert_prcp(2.54, "cm", "mm"), 25.4)

  # inches to cm (via mm)
  expect_equal(convert_prcp(1, "in", "cm"), 2.54)

  # cm to inches (via mm)
  expect_equal(convert_prcp(2.54, "cm", "in"), 1)
})

test_that("convert_prcp handles same unit conversions", {
  expect_equal(convert_prcp(25.4, "mm", "mm"), 25.4)
  expect_equal(convert_prcp(2.54, "cm", "cm"), 2.54)
  expect_equal(convert_prcp(1, "in", "in"), 1)
})

test_that("convert_prcp is vectorized", {
  mm <- c(0, 25.4, 50.8, 100)
  inches <- c(0, 1, 2, 100 / 25.4)

  expect_equal(convert_prcp(mm, "mm", "in"), inches, tolerance = 1e-10)
  expect_equal(convert_prcp(inches, "in", "mm"), mm, tolerance = 1e-10)
})

test_that("convert_prcp handles NA values", {
  expect_equal(convert_prcp(NA, "mm", "in"), NA_real_)
  expect_equal(
    convert_prcp(c(25.4, NA, 50.8), "mm", "in"),
    c(1, NA, 2),
    tolerance = 1e-10
  )
})

test_that("convert_prcp is case-insensitive", {
  expect_equal(convert_prcp(25.4, "MM", "IN"), 1)
  expect_equal(convert_prcp(25.4, "mm", "IN"), 1)
  expect_equal(convert_prcp(10, "CM", "mm"), 100)
})

test_that("convert_prcp handles zero precipitation", {
  expect_equal(convert_prcp(0, "mm", "in"), 0)
  expect_equal(convert_prcp(0, "in", "mm"), 0)
  expect_equal(convert_prcp(0, "cm", "in"), 0)
})

test_that("convert_prcp round-trip conversions are accurate", {
  original <- c(0, 10, 25.4, 50, 100)

  # mm -> in -> mm
  expect_equal(
    convert_prcp(convert_prcp(original, "mm", "in"), "in", "mm"),
    original,
    tolerance = 1e-10
  )

  # mm -> cm -> mm
  expect_equal(
    convert_prcp(convert_prcp(original, "mm", "cm"), "cm", "mm"),
    original,
    tolerance = 1e-10
  )

  # in -> cm -> in
  original_in <- c(0, 1, 2, 5, 10)
  expect_equal(
    convert_prcp(convert_prcp(original_in, "in", "cm"), "cm", "in"),
    original_in,
    tolerance = 1e-10
  )
})

test_that("convert_prcp errors on invalid units", {
  expect_error(convert_prcp(25.4, "x", "in"))
  expect_error(convert_prcp(25.4, "mm", "y"))
  expect_error(convert_prcp(25.4, "meters", "mm")) # meters not supported
})

test_that("convert_prcp handles edge cases", {
  # Very small values
  expect_equal(convert_prcp(0.1, "mm", "in"), 0.1 / 25.4, tolerance = 1e-10)

  # Very large values
  expect_equal(convert_prcp(1000, "mm", "in"), 1000 / 25.4, tolerance = 1e-10)

  # Infinite values
  expect_equal(convert_prcp(Inf, "mm", "in"), Inf)
  expect_equal(convert_prcp(-Inf, "mm", "in"), -Inf)
})
