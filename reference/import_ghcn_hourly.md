# Import data from the Global Historical Climatology hourly (GHCNh) database

This function flexibly accesses meteorological data from the GHCNh
database. Users can provide any number of years and stations, and fully
control the sorts of data flag codes that are returned with the data. By
default, column names are shortened for easier use in R, but longer,
more descriptive names can be requested.

## Usage

``` r
import_ghcn_hourly(
  station = "UKI0000EGLL",
  year = NULL,
  source = c("psv", "parquet"),
  hourly = TRUE,
  extra = FALSE,
  abbr_names = TRUE,
  append_codes = FALSE,
  codes = c("measurement_code", "quality_code", "report_type", "source_code",
    "source_id"),
  progress = rlang::is_interactive()
)
```

## Arguments

- station:

  One or more site codes for the station(s) of interest, obtained using
  [`import_ghcn_stations()`](https://openair-project.github.io/worldmet/reference/import_ghcn_stations.md).

- year:

  One or more years of interest. If `NULL`, the default, all years of
  data available for the chosen `station`s will be imported. Note that,
  in the GHCNd and GHCNm, files are split by station but not year, so
  setting a `year` will not speed up the download. Specifying fewer
  years will improve the speed of a GHCNh download, however.

- source:

  There are two identical data formats to read from - `"psv"` (flat,
  pipe-delimited files) and `"parquet"` (a newer, faster, columnar
  format). The latter is typically faster, but requires the `arrow`
  package as an additional dependency. Note that this only applies when
  `year` is not `NULL`; all `by-site` files are `psv` files.

- hourly:

  Should hourly means be calculated? The default is `TRUE`. If `FALSE`
  then the raw data are returned, which can be sub-hourly.

- extra:

  Should additional columns be returned? The default, `FALSE`, returns
  an opinionated selection of elements that'll be of most interest to
  most users. `TRUE` will return everything available.

- abbr_names:

  Should column names be abbreviated? When `TRUE`, the default, columns
  like `"wind_direction"` are shortened to `"wd"`. When `FALSE`, names
  will match the raw data, albeit in lower case.

- append_codes:

  Logical. Should various codes and flags be appended to the output
  dataframe?

- codes:

  When `append_codes` is `TRUE`, which codes should be appended to the
  dataframe? Any combination of `"measurement_code"`, `"quality_code"`,
  `"report_type"`, `"source_code"`, and/or `"source_id"`.

- progress:

  Show a progress bar when importing many stations/years? Defaults to
  `TRUE` in interactive R sessions. Passed to `.progress` in
  [`purrr::map()`](https://purrr.tidyverse.org/reference/map.html)
  and/or
  [`purrr::pmap()`](https://purrr.tidyverse.org/reference/pmap.html).

## Value

a [tibble](https://tibble.tidyverse.org/reference/tibble-package.html)

## Data Definition

The following core elements are in the GHCNh:

- **wind_direction:** (`wd`) Wind direction from true north (degrees).
  360 = north, 180 = south, 270 = west; 000 indicates calm winds.

- **wind_speed:** (`ws`) Average wind speed (m/s).

- **temperature:** (`air_temp`) Air (dry bulb) temperature at
  approximately 2 meters above ground level, in degrees Celsius (to
  tenths).

- **station_level_pressure:** (`atmos_pres`) Pressure observed at
  station elevation; true barometric pressure at the location (hPa).

- **visibility:** (`visibility`) Horizontal visibility distance (km).

- **dew_point_temperature:** (`dew_point`) Dew point temperature in
  degrees Celsius (to tenths).

- **relative_humidity:** (`rh`) Relative humidity in whole percent,
  measured or calculated from temperature and dew point.

- **sky_cover:** (`cl`) Maximum of all **sky_cover_X** elements (oktas).

- **sky_cover_baseht:** (`cl_baseht`) The height above ground level
  (AGL) of the lowest cloud or obscuring phenomena layer aloft with 5/8
  or more summation total sky cover, which may be predominantly opaque,
  or the vertical visibility into a surface-based obstruction.

- **sky_cover_X:** (`cl_X`) Fraction of sky covered by clouds (oktas).
  Up to 3 layers reported.

- **sky_cover_baseht_X:** (`cl_baseht_X`) Cloud base height for lowest
  layer (m). Up to 3 layers reported.

- **precipitation:** (`precip`) Total liquid precipitation (rain or
  melted snow) for the hour (mm). "T" indicates trace amounts.

- **precipitation_XX_hour:** (`precip_XX`) 3-hour total liquid
  precipitation (mm). "T" indicates trace amounts.

When `extra = TRUE`, the following additional columns are included:

- **sea_level_pressure:** (`sea_pres`) Estimated pressure at sea level
  directly below the station using actual temperature profile (hPa).

- **wind_gust:** (`wg`) Peak short-duration wind speed (m/s) exceeding
  the average wind speed.

- **wet_bulb_temperature:** (`wet_bulb`) Wet bulb temperature in degrees
  Celsius (to tenths), measured or calculated from temperature, dew
  point, and station pressure.

- **snow_depth:** (`snow_depth`) Depth of snowpack on the ground (mm).

- **altimeter:** (`altimeter`) Pressure reduced to mean sea level using
  standard atmosphere profile (hPa).

- **pressure_3hr_change:** (`pres_03`) Change in atmospheric pressure
  over a 3-hour period (hPa), with tendency code.

If `hourly = FALSE`, the following character columns may also be
present.

- **pres_wx_MWX:** (`wx_mwX`) Present weather observation from manual
  reports (code). Up to 3 observations per report.

- **pres_wx_AUX:** (`wx_auX`) Present weather observation from automated
  ASOS/AWOS sensors (code). Up to 3 observations per report.

- **pres_wx_AWX:** (`wx_aqX`) Present weather observation from automated
  sensors (code). Up to 3 observations per report.

- **remarks:** (`remarks`) Raw observation remarks encoded in
  ICAO-standard METAR/SYNOP format.

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

Other GHCN functions:
[`import_ghcn_countries()`](https://openair-project.github.io/worldmet/reference/import_ghcn_countries.md),
[`import_ghcn_daily()`](https://openair-project.github.io/worldmet/reference/import_ghcn_daily.md),
[`import_ghcn_inventory()`](https://openair-project.github.io/worldmet/reference/import_ghcn_inventory.md),
[`import_ghcn_monthly_temp()`](https://openair-project.github.io/worldmet/reference/import_ghcn_monthly.md),
[`import_ghcn_stations()`](https://openair-project.github.io/worldmet/reference/import_ghcn_stations.md)

## Author

Jack Davison
