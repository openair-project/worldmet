# Import station metadata for the Global Historical Climatology Network

This function accesses a full list of GHCN stations available through
either the GHCNh or GHCNd. As well as the station `id`, needed for
importing measurement data, useful geographic and network metadata is
also returned.

## Usage

``` r
import_ghcn_stations(
  name = NULL,
  country = NULL,
  state = NULL,
  lat = NULL,
  lng = NULL,
  crs = 4326,
  n_max = 10L,
  database = c("hourly", "daily"),
  return = c("table", "sf", "map")
)
```

## Arguments

- name, country, state:

  String values to use to filter the metadata for specific site names,
  countries and states. `country` and `state` are matched exactly to
  codes accessed using
  [`import_ghcn_countries()`](https://openair-project.github.io/worldmet/reference/import_ghcn_countries.md).
  `name` is searched as a sub-string case insensitively.

- lat, lng, n_max:

  Decimal latitude (`lat`) and longitude (`lng`) (or other Y/X
  coordinate if using a different `crs`). If provided, the `n_max`
  closest ISD stations to this coordinate will be returned.

- crs:

  The coordinate reference system (CRS) of the data, passed to
  [`sf::st_crs()`](https://r-spatial.github.io/sf/reference/st_crs.html).
  By default this is [EPSG:4326](https://epsg.io/4326), the CRS
  associated with the commonly used latitude and longitude coordinates.
  Different coordinate systems can be specified using `crs` (e.g.,
  `crs = 27700` for the [British National Grid](https://epsg.io/27700)).
  Note that non-lat/lng coordinate systems will be re-projected to
  `EPSG:4326` for making comparisons with the NOAA metadata.

- database:

  One of `"hourly"` or `"daily"`, which defines whether to import
  stations available in the GHCNh or GHCNd. Note that there is overlap
  between the two, but some stations may only be available in one or the
  other.

- return:

  The type of R object to import the GHCN stations as. One of the
  following:

  - `"table"`, which returns an R `data.frame`.

  - `"sf"`, which returns a spatial `data.frame` from the `sf` package.

  - `"map"`, which returns an interactive `leaflet` map.

## Value

One of:

- a [tibble](https://tibble.tidyverse.org/reference/tibble-package.html)

- an [sf](https://r-spatial.github.io/sf/reference/st_as_sf.html) object

- an interactive `leaflet` map

## See also

Other GHCN functions:
[`import_ghcn_countries()`](https://openair-project.github.io/worldmet/reference/import_ghcn_countries.md),
[`import_ghcn_daily()`](https://openair-project.github.io/worldmet/reference/import_ghcn_daily.md),
[`import_ghcn_hourly()`](https://openair-project.github.io/worldmet/reference/import_ghcn_hourly.md),
[`import_ghcn_inventory()`](https://openair-project.github.io/worldmet/reference/import_ghcn_inventory.md),
[`import_ghcn_monthly_temp()`](https://openair-project.github.io/worldmet/reference/import_ghcn_monthly.md)

## Author

Jack Davison
