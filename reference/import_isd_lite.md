# Import "Lite" Meteorological data from the NOAA Integrated Surface Database (ISD)

This function is an alternative to
[`importNOAA()`](https://openair-project.github.io/worldmet/reference/deprecated-isd.md),
and provides access to the "Lite" format of the data. This a subset of
the larger
[`importNOAA()`](https://openair-project.github.io/worldmet/reference/deprecated-isd.md)
dataset featuring eight common climatological variables. As it assigns
the nearest measurement to the "top of the hour" to the data, specific
values are likely similar but different to those returned by
[`importNOAA()`](https://openair-project.github.io/worldmet/reference/deprecated-isd.md).
Read the [technical
document](https://www.ncei.noaa.gov/pub/data/noaa/isd-lite/isd-lite-technical-document.pdf)
for more information.

## Usage

``` r
import_isd_lite(
  code = "037720-99999",
  year = 2025,
  progress = rlang::is_interactive(),
  quiet = FALSE
)
```

## Arguments

- code:

  The identifying code as a character string. The code is a combination
  of the USAF and the WBAN unique identifiers. The codes are separated
  by a “-” e.g. `code = "037720-99999"`.

- year:

  The year to import. This can be a vector of years e.g.
  `year = 2000:2005`.

- progress:

  Show a progress bar when importing many stations/years? Defaults to
  `TRUE` in interactive R sessions. Passed to `.progress` in
  [`purrr::map()`](https://purrr.tidyverse.org/reference/map.html)
  and/or
  [`purrr::pmap()`](https://purrr.tidyverse.org/reference/pmap.html).

- quiet:

  Print missing sites/years to the screen? Defaults to `FALSE`.

## Value

Returns a data frame of surface observations. The data frame is
consistent for use with the `openair` package. Note that the data are
returned in GMT (UTC) time zone format. Users may wish to express the
data in other time zones, e.g., to merge with air pollution data.

## Details

Note the following units for the main variables:

- date:

  Date/time in POSIXct format. \*\*Note the time zone is UTC and may
  need to be adjusted to merge with other local data.

- latitude:

  Latitude in decimal degrees (-90 to 90).

- longitude:

  Longitude in decimal degrees (-180 to 180). Negative numbers are west
  of the Greenwich Meridian.

- elev:

  Elevation of site in metres.

- ws:

  Wind speed in m/s.

- wd:

  Wind direction in degrees. 90 is from the east.

- air_temp:

  Air temperature in degrees Celcius.

- atmos_pres:

  The sea level pressure in millibars.

- dew_point:

  The dew point temperature in degrees Celcius.

- precip_6:

  6-hour precipitation in mm.

- precip_1:

  1-hour precipitation in mm.

- sky:

  Sky Condition Total Coverage Code.

The data are returned in GMT (UTC). It may be necessary to adjust the
time zone when combining with other data. For example, if air quality
data were available for Beijing with time zone set to "Etc/GMT-8" (note
the negative offset even though Beijing is ahead of GMT. See the
`openair` package and manual for more details), then the time zone of
the met data can be changed to be the same. One way of doing this would
be `attr(met$date, "tzone") <- "Etc/GMT-8"` for a meteorological data
frame called `met`. The two data sets could then be merged based on
`date`.

## Parallel Processing

If you are importing a lot of meteorological data, this can take a long
while. This is because each combination of year and station requires
downloading a separate data file from NOAA's online data directory, and
the time each download takes can quickly add up.
[`import_isd_hourly()`](https://openair-project.github.io/worldmet/reference/import_isd_hourly.md)
and `import_isd_lite()` can use parallel processing to speed downloading
up, powered by the capable `{mirai}` package. If users have any
`{mirai}` "daemons" set, these functions will download files in
parallel. The greatest benefits will be seen if you spawn as many
daemons as you have cores on your machine, although one fewer than the
available cores is often a good rule of thumb. Your mileage may vary,
however, and naturally spawning more daemons than station-year
combinations will lead to diminishing returns.

    # set workers - once per session
    mirai::daemons(4)

    # import lots of data - NB: no change in import_isd_hourly()!
    big_met <- import_isd_hourly(code = "037720-99999", year = 2010:2020)

## See also

[`getMeta()`](https://openair-project.github.io/worldmet/reference/deprecated-isd.md)
to obtain the codes based on various site search approaches.

Other NOAA ISD functions:
[`import_isd_hourly()`](https://openair-project.github.io/worldmet/reference/import_isd_hourly.md),
[`import_isd_stations()`](https://openair-project.github.io/worldmet/reference/import_isd_stations.md),
[`import_isd_stations_live()`](https://openair-project.github.io/worldmet/reference/import_isd_stations_live.md)

## Author

Jack Davison

## Examples

``` r
if (FALSE) { # \dontrun{
heathrow_lite <- import_isd_lite(code = "037720-99999", year = 2025)
} # }
```
