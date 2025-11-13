# Import data from the Global Historical Climatology daily (GHCNd) database

This function flexibly accesses meteorological data from the GHCNd
database. Users can provide any of stations, and control whether
attribute codes are returned with the data.

## Usage

``` r
import_ghcn_daily(
  station,
  append_codes = FALSE,
  progress = rlang::is_interactive()
)
```

## Arguments

- station:

  One or more site codes for the station(s) of interest, obtained using
  [`import_ghcn_stations()`](https://openair-project.github.io/worldmet/reference/import_ghcn_stations.md).

- append_codes:

  Logical. Should attribute codes be appended to the output dataframe?

- progress:

  Show a progress bar when importing many stations/years? Defaults to
  `TRUE` in interactive R sessions. Passed to `.progress` in
  [`purrr::map()`](https://purrr.tidyverse.org/reference/map.html)
  and/or
  [`purrr::pmap()`](https://purrr.tidyverse.org/reference/pmap.html).

## Value

a [tibble](https://tibble.tidyverse.org/reference/tibble-package.html)

## See also

Other GHCN functions:
[`import_ghcn_countries()`](https://openair-project.github.io/worldmet/reference/import_ghcn_countries.md),
[`import_ghcn_hourly()`](https://openair-project.github.io/worldmet/reference/import_ghcn_hourly.md),
[`import_ghcn_inventory()`](https://openair-project.github.io/worldmet/reference/import_ghcn_inventory.md),
[`import_ghcn_monthly_temp()`](https://openair-project.github.io/worldmet/reference/import_ghcn_monthly.md),
[`import_ghcn_stations()`](https://openair-project.github.io/worldmet/reference/import_ghcn_stations.md)

## Author

Jack Davison
