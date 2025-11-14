# Import data from the Global Historical Climatology monthly (GHCNm) database

This function is a convenient way to access the monthly summaries of the
GHCN. Monthly average temperature is available via
`import_ghcn_monthly_temp()` and monthly precipitation via
`import_ghcn_monthly_prcp()`. Note that these functions can take a few
minutes to run, and parallelism is only enabled for precipitation data.

## Usage

``` r
import_ghcn_monthly_temp(
  table = c("inventory", "data"),
  dataset = c("qcu", "qcf", "qfe")
)

import_ghcn_monthly_prcp(
  station = NULL,
  year = NULL,
  table = c("inventory", "data"),
  progress = rlang::is_interactive()
)
```

## Arguments

- table:

  Either `"inventory"`, `"data"`, or both. The tables to read and return
  in the output list.

- dataset:

  For `import_ghcn_monthly_temp()`. One of the below options. More
  information is available at
  <https://www.ncei.noaa.gov/pub/data/ghcn/v4/readme.txt>.

  - `"qcu"`: Quality Control, Unadjusted

  - `"qcf"`: Quality Control, Adjusted, using the Pairwise Homogeneity
    Algorithm.

  - `"qfe"`: Quality Control, Adjusted, Estimated using the Pairwise
    Homogeneity Algorithm. Only the years 1961-2010 are provided. This
    is to help maximize station coverage when calculating normals.

- station:

  For `import_ghcn_monthly_prcp()`. The specific stations to import
  monthly precipitation data for.

- year:

  One or more years of interest. If `NULL`, the default, all years of
  data available for the chosen `station`s will be imported. Note that,
  in the GHCNd and GHCNm, files are split by station but not year, so
  setting a `year` will not speed up the download. Specifying fewer
  years will improve the speed of a GHCNh download, however.

- progress:

  For `import_ghcn_monthly_prcp()`. Show a progress bar when importing
  many stations? Defaults to `TRUE` in interactive R sessions. Passed to
  `.progress` in
  [`purrr::map()`](https://purrr.tidyverse.org/reference/map.html).

## Value

a list of
[tibbles](https://tibble.tidyverse.org/reference/tibble-package.html)

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
[`import_ghcn_hourly()`](https://openair-project.github.io/worldmet/reference/import_ghcn_hourly.md),
[`import_ghcn_inventory()`](https://openair-project.github.io/worldmet/reference/import_ghcn_inventory.md),
[`import_ghcn_stations()`](https://openair-project.github.io/worldmet/reference/import_ghcn_stations.md)

## Author

Jack Davison
