# Using {worldmet} to Locate, Import & Visualise Meteorological Data

``` r
library(worldmet)
```

## Show all sites

The function to use to find which sites are available is
[`getMeta()`](https://openair-project.github.io/worldmet/reference/getMeta.md).
While this function can be run using different options, it can be
easiest to run it without any options. This produces a map of all the
available sites, which can be quickly accessed.

Click to expand the markers until you find the site of interest (shown
by a blue marker). This reveals some site information including the site
name and the start and end date of available data. The most important
information revealed in the marker is the code, which is used to access
the data.

``` r
getMeta()
#> # A tibble: 12,773 × 12
#>    usaf  wban  station ctry  st    call  latitude longitude `elev(m)` begin     
#>    <chr> <chr> <chr>   <chr> <chr> <chr>    <dbl>     <dbl>     <dbl> <date>    
#>  1 0100… 99999 EDGEOYA NO    NA    NA        78.2      22.8      14   1973-01-01
#>  2 0100… 99999 NY-ALE… SV    NA    NA        78.9      11.9       7.7 1973-01-06
#>  3 0100… 99999 LONGYE… SV    NA    ENSB      78.2      15.5      26.8 1975-09-29
#>  4 0100… 99999 KARL X… SV    NA    NA        80.6      25         5   1955-01-01
#>  5 0101… 99999 ANDOYA  NO    NA    ENAN      69.3      16.1      13.1 1931-01-03
#>  6 0101… 99999 KVITOYA SV    NA    NA        80.1      31.5      10   1986-11-18
#>  7 0101… 99999 HEKKIN… NO    NA    NA        69.6      17.8      14   1980-03-14
#>  8 0101… 99999 KONGSO… NO    NA    NA        78.9      28.9      20   1993-05-01
#>  9 0101… 99999 AKSELO… SV    NA    NA        77.7      14.8       6   1973-01-01
#> 10 0102… 99999 SORKAP… SV    NA    NA        76.5      16.6      10   2010-10-08
#> # ℹ 12,763 more rows
#> # ℹ 2 more variables: end <date>, code <chr>
```

When using
[`getMeta()`](https://openair-project.github.io/worldmet/reference/getMeta.md)
it will probably be useful to read the information into a data frame.
Note that `plot = FALSE` stops the function from providing the map.

``` r
met_info <- getMeta(plot = FALSE)
```

## Search based on latitude and longitude

Often, one has an idea of the region in which a site is of interest. For
example, if the interest was in sites close to London, the latitude and
longitude can be supplied and a search is carried out of the 10 nearest
sites to that location. There is also an option n that can be used in
change the number of nearest sites shown. If a lat/lon is provided,
clicking on the blue marker will show the approximate distance between
the site and the search coordinates.

``` r
getMeta(lat = 51.5, lon = 0)
#> # A tibble: 10 × 13
#>    usaf  wban  station ctry  st    call  latitude longitude `elev(m)` begin     
#>    <chr> <chr> <chr>   <chr> <chr> <chr>    <dbl>     <dbl>     <dbl> <date>    
#>  1 0376… 99999 LONDON… GB    NA    EGLC      51.5     0.055       5.8 1988-01-29
#>  2 0377… 99999 ST JAM… UK    NA    NA        51.5    -0.117       5   2009-12-18
#>  3 0376… 99999 BIGGIN… UK    NA    EGKB      51.3     0.033     182.  1988-01-05
#>  4 0378… 99999 KENLEY… UK    NA    NA        51.3    -0.083     170   1988-02-01
#>  5 0367… 99999 NORTHO… UK    NA    EGWU      51.6    -0.418      37.8 1973-01-01
#>  6 0377… 99999 LONDON… GB    NA    EGLL      51.5    -0.461      25.3 1948-12-01
#>  7 0377… 99999 LONDON… GB    NA    EGKK      51.1    -0.19       61.6 1973-01-01
#>  8 0368… 99999 ROTHAM… UK    NA    NA        51.8    -0.358     128   2013-08-20
#>  9 0376… 99999 CHARLW… UK    NA    NA        51.1    -0.229      68   1992-03-01
#> 10 0368… 99999 LONDON… GB    NA    EGSS      51.9     0.235     106.  1973-01-01
#> # ℹ 3 more variables: end <date>, code <chr>, dist <dbl>
```

## Importing Data

To obtain the data the user must supply a `code` (see above) and year(s)
of interest. For example, to download data for Heathrow Airport in 2010
(code 037720-99999):

``` r
met_london <- importNOAA(code = "037720-99999", year = 2010)
head(met_london)
```

    #> # A tibble: 6 × 25
    #>   code        station date                latitude longitude  elev    ws      wd
    #>   <fct>       <fct>   <dttm>                 <dbl>     <dbl> <dbl> <dbl>   <dbl>
    #> 1 037720-999… HEATHR… 2010-01-01 00:00:00     51.5    -0.461  25.3  3.27  17.4  
    #> 2 037720-999… HEATHR… 2010-01-01 01:00:00     51.5    -0.461  25.3  3.1    6.13 
    #> 3 037720-999… HEATHR… 2010-01-01 02:00:00     51.5    -0.461  25.3  3.1   15.6  
    #> 4 037720-999… HEATHR… 2010-01-01 03:00:00     51.5    -0.461  25.3  2.93  17.0  
    #> 5 037720-999… HEATHR… 2010-01-01 04:00:00     51.5    -0.461  25.3  2.77   0.606
    #> 6 037720-999… HEATHR… 2010-01-01 05:00:00     51.5    -0.461  25.3  2.43 356.   
    #> # ℹ 17 more variables: air_temp <dbl>, atmos_pres <dbl>, visibility <dbl>,
    #> #   dew_point <dbl>, RH <dbl>, ceil_hgt <dbl>, cl_1 <dbl>, cl_2 <dbl>,
    #> #   cl_3 <dbl>, cl <dbl>, cl_1_height <dbl>, cl_2_height <dbl>,
    #> #   cl_3_height <dbl>, precip_12 <dbl>, precip_6 <dbl>, pwc <chr>, precip <dbl>

A wind rose (for example) can easily be plotted using `openair`:

``` r
# load openair
openair::windRose(met_london)
```

![](worldmet_files/figure-html/unnamed-chunk-2-1.png)

## Parallel Processing

If you are importing a lot of meteorological data, this can take a long
while. This is because each combination of year and station requires
downloading a separate data file from NOAA’s online data directory, and
the time each download takes can quickly add up.
[`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md)
can use parallel processing to speed downloading up, powered by the
capable [mirai](https://mirai.r-lib.org) package. If users have any
[mirai](https://mirai.r-lib.org) “daemons” set,
[`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md)
will download files in parallel. The greatest benefits will be seen if
you spawn as many daemons as you have cores on your machine, although
one fewer than the available cores is often a good rule of thumb. Your
mileage may vary, however, and naturally spawning more daemons than
station-year combinations will lead to diminishing returns.

``` r
# set workers - once per session
mirai::daemons(4)

# import lots of data - NB: no change in importNOAA()!
big_met <- importNOAA(code = "037720-99999", year = 2010:2020)
```

Historically, parallelism in
[worldmet](https://openair-project.github.io/worldmet/) was achieved
with [doParallel](https://github.com/RevolutionAnalytics/doparallel),
[foreach](https://github.com/RevolutionAnalytics/foreach) and
`{parallel}` and was activated using the `n.cores` argument. While this
will still work, it is recommended users set their own daemons before
using
[`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md).
This should avoid any issues with mistakenly spawning too many daemons,
or accidentally spawning daemons within other daemons.
