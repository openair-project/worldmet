# Deprecated ISD access functions

**\[deprecated\]**

This function is part of an old `worldmet` API. Please use the following
alternatives:

- `getMeta()` -\>
  [`import_isd_stations()`](https://openair-project.github.io/worldmet/reference/import_isd_stations.md)

- `getMetaLive()` -\>
  [`import_isd_stations_live()`](https://openair-project.github.io/worldmet/reference/import_isd_stations_live.md)

- `importNOAA()` -\>
  [`import_isd_hourly()`](https://openair-project.github.io/worldmet/reference/import_isd_hourly.md)

- `importNOAAlite()` -\>
  [`import_isd_lite()`](https://openair-project.github.io/worldmet/reference/import_isd_lite.md)

- the `path` argument -\>
  [`write_met()`](https://openair-project.github.io/worldmet/reference/write_met.md)

## Usage

``` r
getMeta(
  site = NULL,
  lat = NULL,
  lon = NULL,
  crs = 4326,
  country = NULL,
  state = NULL,
  n = 10,
  end.year = "current",
  provider = c("OpenStreetMap", "Esri.WorldImagery"),
  plot = TRUE,
  returnMap = FALSE
)

getMetaLive(...)

importNOAA(
  code = "037720-99999",
  year = 2014,
  hourly = TRUE,
  source = c("delim", "fwf"),
  quiet = FALSE,
  path = NA,
  n.cores = NULL
)

importNOAAlite(code = "037720-99999", year = 2025, quiet = FALSE, path = NA)
```

## Arguments

- site:

  A site name search string e.g. `site = "heathrow"`. The search strings
  and be partial and can be upper or lower case e.g. `site = "HEATHR"`.

- lat, lon:

  Decimal latitude and longitude (or other Y/X coordinate if using a
  different `crs`). If provided, the `n_max` closest ISD stations to
  this coordinate will be returned.

- crs:

  The coordinate reference system (CRS) of the data, passed to
  [`sf::st_crs()`](https://r-spatial.github.io/sf/reference/st_crs.html).
  By default this is [EPSG:4326](https://epsg.io/4326), the CRS
  associated with the commonly used latitude and longitude coordinates.
  Different coordinate systems can be specified using `crs` (e.g.,
  `crs = 27700` for the [British National Grid](https://epsg.io/27700)).
  Note that non-lat/lng coordinate systems will be re-projected to
  EPSG:4326 for making comparisons with the NOAA metadata plotting on
  the map.

- country:

  The country code. This is a two letter code. For a full listing see
  <https://www1.ncdc.noaa.gov/pub/data/noaa/isd-history.csv>.

- state:

  The state code. This is a two letter code.

- n:

  The number of nearest sites to search based on `latitude` and
  `longitude`.

- end.year:

  To help filter sites based on how recent the available data are.
  `end.year` can be "current", "any" or a numeric year such as 2016, or
  a range of years e.g. 1990:2016 (which would select any site that had
  an end date in that range. **By default only sites that have some data
  for the current year are returned**.

- provider:

  By default a map will be created in which readers may toggle between a
  vector base map and a satellite/aerial image. `provider` allows users
  to override this default; see
  <http://leaflet-extras.github.io/leaflet-providers/preview/> for a
  list of all base maps that can be used. If multiple base maps are
  provided, they can be toggled between using a "layer control"
  interface.

- plot:

  If `TRUE` will plot sites on an interactive leaflet map.

- returnMap:

  Should the leaflet map be returned instead of the meta data? Default
  is `FALSE`.

- ...:

  Currently unused.

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
  [`import_isd_hourly()`](https://openair-project.github.io/worldmet/reference/import_isd_hourly.md)
  defaults to `"delim"` but, if the delimited data store is down, users
  may wish to try `"fwf"` instead. Both data sources should be identical
  to one another.

- quiet:

  Print missing sites/years to the screen? Defaults to `FALSE`.

- path:

  If a file path is provided, the data are saved as an rds file at the
  chosen location e.g. `path = "C:/Users/David"`. Files are saved by
  year and site.

- n.cores:

  No longer recommended; please set
  [`mirai::daemons()`](https://mirai.r-lib.org/reference/daemons.html)
  in your R session. This argument is provided for back compatibility,
  and is passed to the `n` argument of
  [`mirai::daemons()`](https://mirai.r-lib.org/reference/daemons.html)
  on behalf of the user. Any set daemons will be reset once the function
  completes. Default is `NULL`, which means no parallelism.
  `n.cores = 1L` is equivalent to `n.cores = NULL`.

## Value

A data frame is returned with all available meta data, mostly
importantly including a `code` that can be supplied to `importNOAA()`.
If latitude and longitude searches are made an approximate distance,
`dist` in km is also returned.
