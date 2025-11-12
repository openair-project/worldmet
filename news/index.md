# Changelog

## worldmet (development version)

## worldmet 0.10.2

CRAN release: 2025-11-07

### Dependency Changes

- `worldmet` no longer depends on `openair`.

### New Features

- [`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md)
  now recommends trying the other `source` if it fails to fetch data
  (i.e., if `source = "delim"` fails, the user will be prompted to try
  `source = "fwf"`).

### Bug Fixes

- Fixed `source = "fwf"` failing when importing data from closed
  stations.

- Fixed `source = "fwf"` when `hourly = TRUE` and multiple sites are
  imported.

- Removed present weather condition when `source = "fwf"`.

## worldmet 0.10.1

CRAN release: 2025-08-20

### New Features

- [`importNOAAlite()`](https://openair-project.github.io/worldmet/reference/importNOAAlite.md)
  has gained the `path` argument, in line with
  [`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md).

- [`importNOAAlite()`](https://openair-project.github.io/worldmet/reference/importNOAAlite.md)
  now supports parallel processing using the
  [mirai](https://mirai.r-lib.org) package, in line with
  [`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md).

### Bug Fixes

- [`importNOAAlite()`](https://openair-project.github.io/worldmet/reference/importNOAAlite.md)
  can now import data from years other than 2025.

## worldmet 0.10.0

CRAN release: 2025-07-30

### New Features

- Parallel importing of NOAA data is now powered by
  [mirai](https://mirai.r-lib.org). This reduces the number of
  dependencies of
  [worldmet](https://openair-project.github.io/worldmet/), and also
  allows users to be more flexible with how parallel processing is
  achieved.

  - Due to this change, users are recommended to set
    [`mirai::daemons()`](https://mirai.r-lib.org/reference/daemons.html)
    themselves. `n.core` will stil work for back-compatibility, but will
    give a once-per-session warning.

- [`getMeta()`](https://openair-project.github.io/worldmet/reference/getMeta.md)
  has gained the `crs` argument to search NOAA ISD stations by
  coordinates other than latitude and longitude.

- Added `importNOAALite()` to access the ISDLite filestore.

- Added the `importNOAA(source=)` argument to import ISD data from
  different file stores. This option can be useful if one of the file
  stores is not available for whatever reason.

- All error and warning messages are now powered by
  [cli](https://cli.r-lib.org) and are more informative.

## worldmet 0.9.9

CRAN release: 2025-01-14

### New Features

- The `quiet` argument of
  [`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md)
  now also toggles the progress bar.

### New Features

- [`getMeta()`](https://openair-project.github.io/worldmet/reference/getMeta.md)
  has gained the `crs` argument, which allows `getMeta(lat =, lon =)` to
  be defined using other coordinate systems.

### Bug Fixes

- Fixed join problem due to [dplyr](https://dplyr.tidyverse.org)
  updates.

- Fixed spelling mistakes in `weatherCodes`

- Converted the [worldmet](https://openair-project.github.io/worldmet/)
  vignette to an article. This should ensure it is no longer reliant on
  NOAA’s servers. It can now be accessed at
  <https://openair-project.github.io/worldmet/articles/worldmet.html>.

## worldmet 0.9.6

CRAN release: 2022-10-05

### New Features

- [`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md)
  will now display a progress bar when multiple years of met data are to
  be imported.

- Improved the formatting of the popups in
  [`getMeta()`](https://openair-project.github.io/worldmet/reference/getMeta.md)
  in line with `openairmaps::networkMap()`.

- Added the `provider` argument to
  [`getMeta()`](https://openair-project.github.io/worldmet/reference/getMeta.md),
  allowing for users to define one or more `leaflet` basemaps. Uses the
  same default as `openairmaps::networkMap()`.

- [`exportADMS()`](https://openair-project.github.io/worldmet/reference/exportADMS.md)
  now invisibly returns the input data, in line with, e.g.,
  [`readr::write_csv()`](https://readr.tidyverse.org/reference/write_delim.html).

## worldmet 0.9.5

CRAN release: 2021-04-20

### Bug Fixes

- do not add precip to
  [`exportADMS()`](https://openair-project.github.io/worldmet/reference/exportADMS.md)

- Cloud cover data mostly spans 1 to 8 Oktas and no zero (clear sky);
  use `ceil_hgt = 220000` (unlimited) to indicate clear sky when cloud
  cover is reported as missing.

- Do not use ftp for site information.

## worldmet 0.9.4

CRAN release: 2021-04-09

### Bug Fixes

- Fix precipitation. The `precip_12` gives the sum of the precipitation
  over the past 12 hours and the sum of this column should be the annual
  total in mm. `precip` spreads the 12-hour total evenly across the
  previous 12 hours.
  [worldmet](https://openair-project.github.io/worldmet/) no longer
  tries to combine 12 and 6 hour totals.

## worldmet 0.9.3

CRAN release: 2021-03-29

### Bug Fixes

- Catch missing data error and report missing when importing data using
  [`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md)

## worldmet 0.9.2

CRAN release: 2020-09-17

### New Features

- Exporting `weatherCodes` so that everything works when used by other
  packages through “explicit namespacing”” (*e.g.*
  [`worldmet::importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md))
  without having to
  [`library(worldmet)`](https://openair-project.github.io/worldmet/).

## worldmet 0.9.1

### Bug Fixes

- fix bug when lat and lon provided in
  [`getMeta()`](https://openair-project.github.io/worldmet/reference/getMeta.md)

- fix bug when several years are selected and columns are different
  lengths when `n.core = 1`

## worldmet 0.9.1

### New Features

- Significant changes due to NOAA storage formats and different storage
  locations

- Remove options for precipitation and present weather in
  [`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md);
  just return everything

- Return data as [tibble](https://tibble.tidyverse.org/)

## worldmet 0.8.8

CRAN release: 2020-02-12

### New Features

- export
  [`getMetaLive()`](https://openair-project.github.io/worldmet/reference/getMetaLive.md)
  to allow users direct access to all meta data and easy re-use without
  re-downloading.

- add option `path` to allow users to save met data as an rds file.

- deprecate `fresh` option in
  [`getMeta()`](https://openair-project.github.io/worldmet/reference/getMeta.md).

- Assume `9999` is missing for visibility (was `999999`)

### Bug Fixes

- fix short WBAN codes.

- make sure all meta data are used and not only sites with most recent
  year

## worldmet 0.8.4

CRAN release: 2018-02-27

### New Features

- query live meta data when using
  [`getMeta()`](https://openair-project.github.io/worldmet/reference/getMeta.md).

- parallel processing for sites and years.

- use
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html)
  for meta data ([`read.csv()`](https://rdrr.io/r/utils/read.table.html)
  seems very slow in R 3.4.3).

### Bug Fixes

- fix bug when data not available for a year when using parallel
  processing

## worldmet 0.8.0

CRAN release: 2017-12-18

### New Features

- downloads now from webserver rather than ftp. Should be faster and
  allow more downloads. Thanks to Stuart Grange.

- add parallel processing using
  [foreach](https://github.com/RevolutionAnalytics/foreach).

## worldmet 0.7.4

### Bug Fixes

- don’t use
  [`closeAllConnections()`](https://rdrr.io/r/base/showConnections.html).

## worldmet 0.7.3

### New Features

- default to downloading fresh meta data each time.

- update meta data.

### Bug Fixes

- fix current year problem (base on meta data available in package).

## worldmet 0.7.2

### Bug Fixes

- make sure data are returned with `NA` when missing and not `NaN`.

## worldmet 0.6

### New Features

- Add ability to return precipitation measurements, if available.

- Add precipitation to
  [`exportADMS()`](https://openair-project.github.io/worldmet/reference/exportADMS.md)
