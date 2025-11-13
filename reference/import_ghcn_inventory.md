# Import station inventory for the Global Historical Climatology Network

This function accesses a data inventory of GHCN stations available
through either the GHCNh or GHCNd. The returned `data.frame` contains
data which reveals the earliest and latest years of data available for
each station from the NOAA database.

## Usage

``` r
import_ghcn_inventory(
  database = c("hourly", "daily"),
  pivot = c("wide", "long"),
  progress = rlang::is_interactive()
)
```

## Arguments

- database:

  One of `"hourly"` or `"daily"`, which defines whether to import the
  GHCNh or GHCNd inventory. The way in which these files is formatted is
  different.

- pivot:

  One of `"wide"` or `"long"`. The GHCNh inventory can be returned in a
  `"wide"` format (with `id`, `year` and twelve month columns) or a
  `"long"` format (with `id`, `year`, `month`, and `count` columns).
  Does not apply to the GHCNd inventory.

- progress:

  The inventory file is large and can be slow to download. Show a
  progress indicator when accessing the inventory? Defaults to `TRUE` in
  interactive R sessions. Passed to `progress` in
  [`readr::read_fwf()`](https://readr.tidyverse.org/reference/read_fwf.html)
  and/or
  [`purrr::pmap()`](https://purrr.tidyverse.org/reference/pmap.html).

## Value

a [tibble](https://tibble.tidyverse.org/reference/tibble-package.html)

## See also

Other GHCN functions:
[`import_ghcn_countries()`](https://openair-project.github.io/worldmet/reference/import_ghcn_countries.md),
[`import_ghcn_daily()`](https://openair-project.github.io/worldmet/reference/import_ghcn_daily.md),
[`import_ghcn_hourly()`](https://openair-project.github.io/worldmet/reference/import_ghcn_hourly.md),
[`import_ghcn_monthly_temp()`](https://openair-project.github.io/worldmet/reference/import_ghcn_monthly.md),
[`import_ghcn_stations()`](https://openair-project.github.io/worldmet/reference/import_ghcn_stations.md)

## Author

Jack Davison
