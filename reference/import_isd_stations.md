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
  country = NULL,
  state = NULL,
  lat = NULL,
  lng = NULL,
  crs = 4326,
  n_max = 10,
  end_year = "current",
  provider = c(`Street Map` = "CartoDB.Voyager", Satellite = "Esri.WorldImagery"),
  return = c("table", "sf", "map")
)
```

## Arguments

- site:

  A site name search string e.g. `site = "heathrow"`. The search strings
  and be partial and can be upper or lower case e.g. `site = "HEATHR"`.

- country:

  The country code. This is a two letter code. For a full listing see
  <https://www.ncei.noaa.gov/pub/data/noaa/isd-history.csv>.

- state:

  The state code. This is a two letter code.

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

- end_year:

  To help filter sites based on how recent the available data are.
  `end_year` can be "current", "any" or a numeric year such as 2016, or
  a range of years e.g. 1990:2016 (which would select any site that had
  an end date in that range. **By default only sites that have some data
  for the current year are returned**.

- provider:

  When `return = "map"`, by default a map will be created in which
  readers may toggle between a vector street map and a satellite/aerial
  image. `provider` allows users to override this default; see
  <http://leaflet-extras.github.io/leaflet-providers/preview/> for a
  list of all base maps that can be used. Base maps can be toggled using
  a layer control menu; the labels will be taken from the name of the
  base map unless a named list is defined (see default value).

- return:

  The type of R object to import the data as. One of the following:

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
## search for near a specified lat/lng - near Beijing airport
## returns 'n_max' nearest by default
getMeta(lat = 40, lng = 116.9)
} # }
```
