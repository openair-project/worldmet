# Find a ISD site code and other meta data

Get information on meteorological sites

## Usage

``` r
getMeta(
  site = "heathrow",
  lat = NA,
  lon = NA,
  crs = 4326,
  country = NA,
  state = NA,
  n = 10,
  end.year = "current",
  provider = c("OpenStreetMap", "Esri.WorldImagery"),
  plot = TRUE,
  returnMap = FALSE
)
```

## Arguments

- site:

  A site name search string e.g. `site = "heathrow"`. The search strings
  and be partial and can be upper or lower case e.g. `site = "HEATHR"`.

- lat, lon:

  Decimal latitude and longitude (or other Y/X coordinate if using a
  different `crs`). If provided, the `n` closest ISD stations to this
  coordinate will be returned.

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

## Value

A data frame is returned with all available meta data, mostly
importantly including a `code` that can be supplied to
[`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md).
If latitude and longitude searches are made an approximate distance,
`dist` in km is also returned.

## Details

This function is primarily used to find a site code that can be used to
access data using
[`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md).
Sites searches of approximately 30,000 sites can be carried out based on
the site name and based on the nearest locations based on user-supplied
latitude and longitude.

## See also

Other NOAA ISD functions:
[`getMetaLive()`](https://openair-project.github.io/worldmet/reference/getMetaLive.md),
[`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md),
[`importNOAAlite()`](https://openair-project.github.io/worldmet/reference/importNOAAlite.md)

## Author

David Carslaw

## Examples

``` r
if (FALSE) { # \dontrun{
## search for sites with name beijing
getMeta(site = "beijing")
} # }

if (FALSE) { # \dontrun{
## search for near a specified lat/lon - near Beijing airport
## returns 'n' nearest by default
getMeta(lat = 40, lon = 116.9)
} # }
```
