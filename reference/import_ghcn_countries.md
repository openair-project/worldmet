# Import FIPS country codes and State/Province/Territory codes used by the Global Historical Climatology Network

This function returns a two-column dataframe either of "Federal
Information Processing Standards" (FIPS) codes and the countries to
which they are associated, or state codes and their associated states.
These may be a useful reference when examining GHCN site metadata.

## Usage

``` r
import_ghcn_countries(
  table = c("countries", "states"),
  database = c("hourly", "daily", "monthly")
)
```

## Arguments

- table:

  One of `"countries"` or `"states"`.

- database:

  One of `"hourly"`, `"daily"` or `"monthly"`, which defines which of
  the NOAA databases to import the FIPS codes from. There is little
  difference between the data in the different sources, but this option
  may be useful if one of the services is not accessible.

## Value

a [tibble](https://tibble.tidyverse.org/reference/tibble-package.html)

## See also

Other GHCN functions:
[`import_ghcn_daily()`](https://openair-project.github.io/worldmet/reference/import_ghcn_daily.md),
[`import_ghcn_hourly()`](https://openair-project.github.io/worldmet/reference/import_ghcn_hourly.md),
[`import_ghcn_inventory()`](https://openair-project.github.io/worldmet/reference/import_ghcn_inventory.md),
[`import_ghcn_monthly_temp()`](https://openair-project.github.io/worldmet/reference/import_ghcn_monthly.md),
[`import_ghcn_stations()`](https://openair-project.github.io/worldmet/reference/import_ghcn_stations.md)

## Author

Jack Davison
