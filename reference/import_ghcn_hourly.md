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
  data available for the chosen `station`s will be imported.

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
  most users. `TRUE` will return everything available from the GHCNh.

- abbr_names:

  Should column names be abbreviated? When `TRUE`, the default, columns
  like `"wind_direction"` are shortened to `"wd"`. When `FALSE`, names
  will match the raw data, albeit in lower case.

- append_codes:

  Logical. Should various codes (e.g., measurement coeds, qualiy codes,
  etc.) be appended to the output dataframe?

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

## See also

Other GHCN functions:
[`import_ghcn_countries()`](https://openair-project.github.io/worldmet/reference/import_ghcn_countries.md),
[`import_ghcn_daily()`](https://openair-project.github.io/worldmet/reference/import_ghcn_daily.md),
[`import_ghcn_inventory()`](https://openair-project.github.io/worldmet/reference/import_ghcn_inventory.md),
[`import_ghcn_monthly_temp()`](https://openair-project.github.io/worldmet/reference/import_ghcn_monthly.md),
[`import_ghcn_stations()`](https://openair-project.github.io/worldmet/reference/import_ghcn_stations.md)

## Author

Jack Davison
