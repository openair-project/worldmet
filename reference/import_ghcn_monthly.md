# Import data from the Global Historical Climatology monthly (GHCNm) database

This function is a convenient way to access the monthly summaries of the
GHCN. Monthly average temperature is available via
`import_ghcn_monthly_temp()` and monthly precipitation via
`import_ghcn_monthly_prcp()`. Note that these functions can take a few
minutes to run.

## Usage

``` r
import_ghcn_monthly_temp(
  table = c("inventory", "data"),
  dataset = c("qcu", "qcf", "qfe")
)

import_ghcn_monthly_prcp(
  station = NULL,
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

- progress:

  For `import_ghcn_monthly_prcp()`. Show a progress bar when importing
  many stations? Defaults to `TRUE` in interactive R sessions. Passed to
  `.progress` in
  [`purrr::map()`](https://purrr.tidyverse.org/reference/map.html).

## Value

a list of
[tibbles](https://tibble.tidyverse.org/reference/tibble-package.html)

## See also

Other GHCN functions:
[`import_ghcn_countries()`](https://openair-project.github.io/worldmet/reference/import_ghcn_countries.md),
[`import_ghcn_daily()`](https://openair-project.github.io/worldmet/reference/import_ghcn_daily.md),
[`import_ghcn_hourly()`](https://openair-project.github.io/worldmet/reference/import_ghcn_hourly.md),
[`import_ghcn_inventory()`](https://openair-project.github.io/worldmet/reference/import_ghcn_inventory.md),
[`import_ghcn_stations()`](https://openair-project.github.io/worldmet/reference/import_ghcn_stations.md)

## Author

Jack Davison
