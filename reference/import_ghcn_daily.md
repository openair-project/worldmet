# Import data from the Global Historical Climatology daily (GHCNd) database

This function flexibly accesses meteorological data from the GHCNd
database. Users can provide any of stations, and control whether
attribute codes are returned with the data.

## Usage

``` r
import_ghcn_daily(
  station,
  year = NULL,
  source = c("csv"),
  extra = FALSE,
  append_codes = FALSE,
  codes = c("measurement_flag", "quality_flag", "source_flag"),
  progress = rlang::is_interactive()
)
```

## Arguments

- station:

  One or more site codes for the station(s) of interest, obtained using
  [`import_ghcn_stations()`](https://openair-project.github.io/worldmet/reference/import_ghcn_stations.md).

- year:

  One or more years of interest. If `NULL`, the default, all years of
  data available for the chosen `station`s will be imported. Note that,
  in the GHCNd and GHCNm, files are split by station but not year, so
  setting a `year` will not speed up the download. Specifying fewer
  years will improve the speed of a GHCNh download, however.

- source:

  The data format for the GHCNd. Currently only `"csv"` is supported.
  This argument is included for future use.

- extra:

  Should additional columns be returned? The default, `FALSE`, returns
  an opinionated selection of elements that'll be of most interest to
  most users. `TRUE` will return everything available.

- append_codes:

  Logical. Should various codes and flags be appended to the output
  dataframe?

- codes:

  When `append_codes` is `TRUE`, which codes should be appended to the
  dataframe? Any combination of `"measurement_flag"`, `"quality_flag"`,
  and/or `"source_flag"`.

- progress:

  Show a progress bar when importing many stations/years? Defaults to
  `TRUE` in interactive R sessions. Passed to `.progress` in
  [`purrr::map()`](https://purrr.tidyverse.org/reference/map.html)
  and/or
  [`purrr::pmap()`](https://purrr.tidyverse.org/reference/pmap.html).

## Value

a [tibble](https://tibble.tidyverse.org/reference/tibble-package.html)

## Data Definition

The core elements in the GHCNd are:

- **PRCP**: Precipitation (mm)

- **SNOW**: Snowfall (mm)

- **SNWD**: Snow depth (mm)

- **TMAX**: Maximum temperature (degrees C)

- **TMIN**: Minimum temperature (degrees C)

Other elements which may appear are:

- **ACMC**: Average cloudiness midnight to midnight from 30-second
  ceilometer data (percent)

- **ACMH**: Average cloudiness midnight to midnight from manual
  observations (percent)

- **ACSC**: Average cloudiness sunrise to sunset from 30-second
  ceilometer data (percent)

- **ACSH**: Average cloudiness sunrise to sunset from manual
  observations (percent)

- **ADPT**: Average Dew Point Temperature for the day (degrees C)

- **ASLP**: Average Sea Level Pressure for the day (hPa)

- **ASTP**: Average Station Level Pressure for the day (hPa)

- **AWBT**: Average Wet Bulb Temperature for the day (degrees C)

- **AWDR**: Average daily wind direction (degrees)

- **AWND**: Average daily wind speed (meters per second)

- **DAEV**: Number of days included in the multiday evaporation total
  (MDEV)

- **DAPR**: Number of days included in the multiday precipitation total
  (MDPR)

- **DASF**: Number of days included in the multiday snowfall total
  (MDSF)

- **DATN**: Number of days included in the multiday minimum temperature
  (MDTN)

- **DATX**: Number of days included in the multiday maximum temperature
  (MDTX)

- **DAWM**: Number of days included in the multiday wind movement (MDWM)

- **DWPR**: Number of days with non-zero precipitation included in
  multiday precipitation total (MDPR)

- **EVAP**: Evaporation of water from evaporation pan (mm)

- **FMTM**: Time of fastest mile or fastest 1-minute wind (hours and
  minutes, i.e., HHMM)

- **FRGB**: Base of frozen ground layer (cm)

- **FRGT**: Top of frozen ground layer (cm)

- **FRTH**: Thickness of frozen ground layer (cm)

- **GAHT**: Difference between river and gauge height (cm)

- **MDEV**: Multiday evaporation total (mm; use with **DAEV**)

- **MDPR**: Multiday precipitation total (mm; use with **DAPR** and
  **DWPR**, if available)

- **MDSF**: Multiday snowfall total

- **MDTN**: Multiday minimum temperature (degrees C; use with **DATN**)

- **MDTX**: Multiday maximum temperature (degrees C; use with **DATX**)

- **MDWM**: Multiday wind movement (km)

- **MNPN**: Daily minimum temperature of water in an evaporation pan
  (degrees C)

- **MXPN**: Daily maximum temperature of water in an evaporation pan
  (degrees C)

- **PGTM**: Peak gust time (hours and minutes, i.e., HHMM)

- **PSUN**: Daily percent of possible sunshine (percent)

- **RHAV**: Average relative humidity for the day (percent)

- **RHMN**: Minimum relative humidity for the day (percent)

- **RHMX**: Maximum relative humidity for the day (percent)

- **SN\$#**: Minimum soil temperature (degrees C) where \$ corresponds
  to a code for ground cover and \# corresponds to a code for soil
  depth. Ground cover codes: 0=unknown, 1=grass, 2=fallow, 3=bare
  ground, 4=brome grass, 5=sod, 6=straw mulch, 7=grass muck, 8=bare
  muck. Depth codes: 1=5cm, 2=10cm, 3=20cm, 4=50cm, 5=100cm, 6=150cm,
  7=180cm

- **SX\$#**: Maximum soil temperature (degrees C) where \$ corresponds
  to a code for ground cover and \# corresponds to a code for soil
  depth. See **SN\$#** for ground cover and depth codes

- **TAXN**: Average daily temperature computed as `(TMAX+TMIN)/2.0`
  (degrees C)

- **TAVG**: Average daily temperature (degrees C). Note that TAVG from
  source 'S' corresponds to an average of hourly readings for the period
  ending at 2400 UTC rather than local midnight or other Local Standard
  Time according to a specific Met Service's protocol. For sources other
  than 'S' TAVG is computed in a variety of ways including traditional
  fixed hours of the day whereas TAXN is solely computed as
  (TMAX+TMIN)/2.0

- **THIC**: Thickness of ice on water (mm)

- **TOBS**: Temperature at the time of observation (degrees C)

- **TSUN**: Daily total sunshine (minutes)

- **WDF1**: Direction of fastest 1-minute wind (degrees)

- **WDF2**: Direction of fastest 2-minute wind (degrees)

- **WDF5**: Direction of fastest 5-second wind (degrees)

- **WDFG**: Direction of peak wind gust (degrees)

- **WDFI**: Direction of highest instantaneous wind (degrees)

- **WDFM**: Fastest mile wind direction (degrees)

- **WDMV**: 24-hour wind movement (km)

- **WESD**: Water equivalent of snow on the ground (mm)

- **WESF**: Water equivalent of snowfall (mm)

- **WSF1**: Fastest 1-minute wind speed (meters per second)

- **WSF2**: Fastest 2-minute wind speed (meters per second)

- **WSF5**: Fastest 5-second wind speed (meters per second)

- **WSFG**: Peak gust wind speed (meters per second)

- **WSFI**: Highest instantaneous wind speed (meters per second)

- **WSFM**: Fastest mile wind speed (meters per second)

There can be any number of weather types (**WT\$\$**)

- **WT01**: Fog, ice fog, or freezing fog (may include heavy fog)

- **WT02**: Heavy fog or heaving freezing fog (not always distinguished
  from fog)

- **WT03**: Thunder

- **WT04**: Ice pellets, sleet, snow pellets, or small hail

- **WT05**: Hail (may include small hail)

- **WT06**: Glaze or rime

- **WT07**: Dust, volcanic ash, blowing dust, blowing sand, or blowing
  obstruction

- **WT08**: Smoke or haze

- **WT09**: Blowing or drifting snow

- **WT10**: Tornado, waterspout, or funnel cloud

- **WT11**: High or damaging winds

- **WT12**: Blowing spray

- **WT13**: Mist

- **WT14**: Drizzle

- **WT15**: Freezing drizzle

- **WT16**: Rain (may include freezing rain, drizzle, and freezing
  drizzle)

- **WT17**: Freezing rain

- **WT18**: Snow, snow pellets, snow grains, or ice crystals

- **WT19**: Unknown source of precipitation

- **WT21**: Ground fog

- **WT22**: Ice fog or freezing fog

There can also be any number of 'weather in the vicinity' columns
(**WV\$\$**)

- **WV01**: Fog, ice fog, or freezing fog (may include heavy fog)

- **WV03**: Thunder

- **WV07**: Ash, dust, sand, or other blowing obstruction

- **WV18**: Snow or ice crystals

- **WV20**: Rain or snow shower

## See also

Other GHCN functions:
[`import_ghcn_countries()`](https://openair-project.github.io/worldmet/reference/import_ghcn_countries.md),
[`import_ghcn_hourly()`](https://openair-project.github.io/worldmet/reference/import_ghcn_hourly.md),
[`import_ghcn_inventory()`](https://openair-project.github.io/worldmet/reference/import_ghcn_inventory.md),
[`import_ghcn_monthly_temp()`](https://openair-project.github.io/worldmet/reference/import_ghcn_monthly.md),
[`import_ghcn_stations()`](https://openair-project.github.io/worldmet/reference/import_ghcn_stations.md)

## Author

Jack Davison
