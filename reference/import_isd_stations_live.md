# Obtain site meta data from NOAA server

Download all NOAA meta data, allowing for re-use and direct querying.

## Usage

``` r
import_isd_stations_live(...)
```

## Arguments

- ...:

  Currently unused.

## Value

a [tibble](https://tibble.tidyverse.org/reference/tibble-package.html)

## See also

Other NOAA ISD functions:
[`import_isd_hourly()`](https://openair-project.github.io/worldmet/reference/import_isd_hourly.md),
[`import_isd_lite()`](https://openair-project.github.io/worldmet/reference/import_isd_lite.md),
[`import_isd_stations()`](https://openair-project.github.io/worldmet/reference/import_isd_stations.md)

## Examples

``` r
if (FALSE) { # \dontrun{
meta <- import_isd_stations_live()
head(meta)
} # }
```
