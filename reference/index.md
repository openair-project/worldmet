# Package index

## Integrated Surface Database (ISD)

These functions access data from the NOAA [Integrated Surface
Database](https://www.ncei.noaa.gov/products/land-based-station/integrated-surface-database)
(ISD), a global database that consists of hourly and synoptic surface
observations compiled from numerous sources into a single common ASCII
format and common data model. The ISD includes numerous parameters such
as wind speed and direction, wind gust, temperature, dew point, cloud
data, sea level pressure, altimeter setting, station pressure, present
weather, visibility, precipitation amounts for various time periods,
snow depth, and various other elements as observed by each station.

### Import Met Data

Directly import NOAA meteorological data.

- [`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md)
  : Import Meteorological data from the NOAA Integrated Surface Database
  (ISD)
- [`importNOAAlite()`](https://openair-project.github.io/worldmet/reference/importNOAAlite.md)
  : Import "Lite" Meteorological data from the NOAA Integrated Surface
  Database (ISD)

### View Metadata

Read and visualise meta data relating to meteorological measurement
sites.

- [`getMeta()`](https://openair-project.github.io/worldmet/reference/getMeta.md)
  : Find a ISD site code and other meta data
- [`getMetaLive()`](https://openair-project.github.io/worldmet/reference/getMetaLive.md)
  : Obtain site meta data from NOAA server
- [`weatherCodes`](https://openair-project.github.io/worldmet/reference/weatherCodes.md)
  : Codes for weather types

## ADMS Data

These functions assist with working with the Atmospheric Dispersion
Modelling System (ADMS).

- [`exportADMS()`](https://openair-project.github.io/worldmet/reference/exportADMS.md)
  : Export a meteorological data frame in ADMS format
