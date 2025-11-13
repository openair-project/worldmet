# Using {worldmet} to Locate, Import & Visualise Meteorological Data

``` r
library(worldmet)
```

## Importing Hourly Meteorological Data

### Show all sites

The function to use to find which sites are available is
[`import_ghcn_stations()`](https://openair-project.github.io/worldmet/reference/import_ghcn_stations.md).

``` r
import_ghcn_stations()
#> # A tibble: 34,181 × 11
#>    id    name  country state network   lat   lng elevation gsn_flag hcn_crn_flag
#>    <chr> <chr> <chr>   <chr> <chr>   <dbl> <dbl>     <dbl> <chr>    <chr>       
#>  1 AAI0… REIN… AA      NA    I        12.5 -70.0      18.3 NA       NA          
#>  2 ACL0… BARB… AC      TX    L        17.6 -61.8       5   NA       NA          
#>  3 ACM0… COOL… AC      NA    M        17.1 -61.8      10   NA       NA          
#>  4 ACU5… SOMB… AC      NA    U        18.6 -63.5      10   NA       NA          
#>  5 ACU5… SOMB… AC      NA    U        18.6 -63.5      12   NA       NA          
#>  6 ACU5… SOMB… AC      NA    U        18.6 -63.5      14   NA       NA          
#>  7 ACU5… SOMB… AC      NA    U        18.6 -63.5      16   NA       NA          
#>  8 ACU5… SOMB… AC      NA    U        18.6 -63.5       9   NA       NA          
#>  9 ACW0… ST J… AC      NA    W        17.1 -61.8      19.2 NA       NA          
#> 10 AEI0… ABU … AE      NA    I        24.4  54.7      26.8 NA       NA          
#> # ℹ 34,171 more rows
#> # ℹ 1 more variable: wmo_id <chr>
```

A better way to explore available stations is by using `return = "map"`,
which shows each station on an interactive map. Click to expand the
markers until you find the site of interest (shown by a blue marker),
which can then be clicked for further information. The most important
information revealed in the marker is the station ID, which is used to
access the data.

``` r
import_ghcn_stations(return = "map")
```

### Search based on latitude and longitude

Often, one has an idea of the region in which a site is of interest. For
example, if the interest was in sites close to London, the latitude and
longitude can be supplied and a search is carried out of the 10 nearest
sites to that location. There is also an option n that can be used in
change the number of nearest sites shown. If a lat/lng is provided,
clicking on the blue marker will show the approximate distance between
the site and the search coordinates.

``` r
import_ghcn_stations(lat = 51.5, lng = 0, return = "map")
```

### Importing Data

To obtain the data the user must supply a station ID and year(s) of
interest. For example, to download data for Heathrow Airport in 2024 (ID
`UKI0000EGLL`):

``` r
met_london <- import_ghcn_hourly("UKI0000EGLL", year = 2025)
head(met_london)
```

    #> # A tibble: 6 × 44
    #>   id          station  date                  lat    lng  elev air_temp dew_temp
    #>   <chr>       <chr>    <dttm>              <dbl>  <dbl> <dbl>    <dbl>    <dbl>
    #> 1 UKI0000EGLL HEATHROW 2024-01-01 00:00:00  51.5 -0.461  25.3      8.1      5.3
    #> 2 UKI0000EGLL HEATHROW 2024-01-01 00:20:00  51.5 -0.461  25.3      8        5  
    #> 3 UKI0000EGLL HEATHROW 2024-01-01 00:50:00  51.5 -0.461  25.3      8        4  
    #> 4 UKI0000EGLL HEATHROW 2024-01-01 01:00:00  51.5 -0.461  25.3      7.8      4.8
    #> 5 UKI0000EGLL HEATHROW 2024-01-01 01:20:00  51.5 -0.461  25.3      8        4  
    #> 6 UKI0000EGLL HEATHROW 2024-01-01 01:50:00  51.5 -0.461  25.3      8        4  
    #> # ℹ 36 more variables: atmos_pres <dbl>, sea_pres <dbl>, wd <dbl>, ws <dbl>,
    #> #   wg <dbl>, precip <dbl>, rh <dbl>, wet_bulb <dbl>, wx_mw1 <chr>,
    #> #   wx_mw2 <chr>, wx_mw3 <chr>, wx_au1 <chr>, wx_au2 <chr>, wx_au3 <chr>,
    #> #   wx_aw1 <chr>, wx_aw2 <chr>, wx_aw3 <chr>, snow_depth <dbl>,
    #> #   visibility <dbl>, altimeter <dbl>, pres_03 <dbl>, sc_1 <chr>,
    #> #   sc_baseht_1 <dbl>, sc_2 <chr>, sc_baseht_2 <dbl>, sc_3 <chr>,
    #> #   sc_baseht_3 <dbl>, precip_03 <dbl>, precip_06 <dbl>, precip_09 <dbl>, …

A wind rose (for example) can easily be plotted using `openair`:

``` r
# use function from openair
openair::windRose(met_london)
```

![](worldmet_files/figure-html/windrose-1.png)

## Other Data Types

Also available in `worldmet` are:

- [`import_ghcn_daily()`](https://openair-project.github.io/worldmet/reference/import_ghcn_daily.md),
  which imports daily average data. Users may select specific stations,
  but all available years for that station will be downloaded.

- [`import_ghcn_monthly_temp()`](https://openair-project.github.io/worldmet/reference/import_ghcn_monthly.md),
  which imports monthly average temperatures for the entire GHCN.

- [`import_ghcn_monthly_prcp()`](https://openair-project.github.io/worldmet/reference/import_ghcn_monthly.md),
  which imports monthly total precipitation for specific stations.

Outside of the GHCN, `worldmet` gives access to the historic Integrated
Surface Database (ISD), with functions:

- [`import_isd_stations()`](https://openair-project.github.io/worldmet/reference/import_isd_stations.md)
  to obtain metadata, and

- [`import_isd_hourly()`](https://openair-project.github.io/worldmet/reference/import_isd_hourly.md)
  and
  [`import_isd_lite()`](https://openair-project.github.io/worldmet/reference/import_isd_lite.md)
  to obtain measurement data.

## Writing Data

Two functions are made available for writing out the imported data for
other uses.

- [`write_met()`](https://openair-project.github.io/worldmet/reference/write_met.md)
  will write short-term data imported from the GHCN or ISD as individual
  files (either delimited, RDS, or parquet files) split by the year and
  monitoring station.

- [`write_adms()`](https://openair-project.github.io/worldmet/reference/write_adms.md)
  will write out (at present) ISD data in a format compatible with the
  Atmospheric Dispersion Modelling System (ADMS).
