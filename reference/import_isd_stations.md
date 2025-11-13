# Import station metadata for the Integrated Surface Databse

This function is primarily used to find a site code that can be used to
access data using
[`import_isd_hourly()`](https://openair-project.github.io/worldmet/reference/import_isd_hourly.md).
Sites searches of approximately 30,000 sites can be carried out based on
the site name and based on the nearest locations based on user-supplied
latitude and longitude.

## Usage

``` r
import_isd_stations(
  site = NULL,
  lat = NULL,
  lon = NULL,
  crs = 4326,
  country = NULL,
  state = NULL,
  n_max = 10,
  end_year = "current",
  provider = c("OpenStreetMap", "Esri.WorldImagery"),
  return = c("table", "sf", "map")
)
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

- n_max:

  The number of nearest sites to search based on `latitude` and
  `longitude`.

- end_year:

  To help filter sites based on how recent the available data are.
  `end_year` can be "current", "any" or a numeric year such as 2016, or
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

- return:

  The type of R object to import the ISD stations as. One of the
  following:

  - `"table"`, which returns an R `data.frame`.

  - `"sf"`, which returns a spatial `data.frame` from the `sf` package.

  - `"map"`, which returns an interactive `leaflet` map.

## Value

A data frame is returned with all available meta data, mostly
importantly including a `code` that can be supplied to
[`importNOAA()`](https://openair-project.github.io/worldmet/reference/deprecated-isd.md).
If latitude and longitude searches are made an approximate distance,
`dist` in km is also returned.

## See also

Other NOAA ISD functions:
[`import_isd_hourly()`](https://openair-project.github.io/worldmet/reference/import_isd_hourly.md),
[`import_isd_lite()`](https://openair-project.github.io/worldmet/reference/import_isd_lite.md),
[`import_isd_stations_live()`](https://openair-project.github.io/worldmet/reference/import_isd_stations_live.md)

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
## returns 'n_max' nearest by default
getMeta(lat = 40, lon = 116.9)
} # }
```
