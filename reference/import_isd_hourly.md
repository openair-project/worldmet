# Import Meteorological data from the NOAA Integrated Surface Database (ISD)

This is the main function to import data from the NOAA Integrated
Surface Database (ISD). The ISD contains detailed surface meteorological
data from around the world for over 30,000 locations. For general
information of the ISD see
<https://www.ncei.noaa.gov/products/land-based-station/integrated-surface-database>
and the map here <https://gis.ncdc.noaa.gov/maps/ncei>.

## Usage

``` r
import_isd_hourly(
  code = "037720-99999",
  year = 2014,
  hourly = TRUE,
  source = c("delim", "fwf"),
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

- hourly:

  Should hourly means be calculated? The default is `TRUE`. If `FALSE`
  then the raw data are returned.

- source:

  The NOAA ISD service stores files in two formats; as delimited CSV
  files (`"delim"`) and as fixed width files (`"fwf"`).
  `import_isd_hourly()` defaults to `"delim"` but, if the delimited data
  store is down, users may wish to try `"fwf"` instead. Both data
  sources should be identical to one another.

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

  Date/time in POSIXct format. **Note the time zone is GMT (UTC) and may
  need to be adjusted to merge with other local data. See details
  below.**

- latitude:

  Latitude in decimal degrees (-90 to 90).

- longitude:

  Longitude in decimal degrees (-180 to 180). Negative numbers are west
  of the Greenwich Meridian.

- elevation:

  Elevation of site in metres.

- wd:

  Wind direction in degrees. 90 is from the east.

- ws:

  Wind speed in m/s.

- ceil_hgt:

  The height above ground level (AGL) of the lowest cloud or obscuring
  phenomena layer aloft with 5/8 or more summation total sky cover,
  which may be predominantly opaque, or the vertical visibility into a
  surface-based obstruction.

- visibility:

  The visibility in metres.

- air_temp:

  Air temperature in degrees Celcius.

- dew_point:

  The dew point temperature in degrees Celcius.

- atmos_pres:

  The sea level pressure in millibars.

- RH:

  The relative humidity (%).

- cl_1, ..., cl_3:

  Cloud cover for different layers in Oktas (1-8).

- cl:

  Maximum of cl_1 to cl_3 cloud cover in Oktas (1-8).

- cl_1_height, ..., cl_3_height:

  Height of the cloud base for each later in metres.

- precip_12:

  12-hour precipitation in mm. The sum of this column should give the
  annual precipitation.

- precip_6:

  6-hour precipitation in mm.

- precip:

  This value of precipitation spreads the 12-hour total across the
  previous 12 hours.

- pwc:

  The description of the present weather description (if available).

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
the time each download takes can quickly add up. Many data import
functions in `{worldmet}` can use parallel processing to speed
downloading up, powered by the capable `{mirai}` package. If users have
any `{mirai}` "daemons" set, these functions will download files in
parallel. The greatest benefits will be seen if you spawn as many
daemons as you have cores on your machine, although one fewer than the
available cores is often a good rule of thumb. Your mileage may vary,
however, and naturally spawning more daemons than station-year
combinations will lead to diminishing returns.

    # set workers - once per session
    mirai::daemons(4)

    # import lots of data - NB: no change in the import function!
    big_met <- import_ghcn_hourly(code = "UKI0000EGLL", year = 2010:2025)

## See also

Other NOAA ISD functions:
[`import_isd_lite()`](https://openair-project.github.io/worldmet/reference/import_isd_lite.md),
[`import_isd_stations()`](https://openair-project.github.io/worldmet/reference/import_isd_stations.md),
[`import_isd_stations_live()`](https://openair-project.github.io/worldmet/reference/import_isd_stations_live.md)

## Author

David Carslaw

## Examples

``` r
if (FALSE) { # \dontrun{
# import some data
beijing_met <- import_isd_hourly(code = "545110-99999", year = 2010:2011)

# importing lots of data? use mirai for parallel processing
mirai::daemons(4)
beijing_met2 <- import_isd_hourly(code = "545110-99999", year = 2010:2025)
} # }
```
