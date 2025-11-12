# Obtain site meta data from NOAA server

Download all NOAA meta data, allowing for re-use and direct querying.

## Usage

``` r
getMetaLive(...)
```

## Arguments

- ...:

  Currently unused.

## Value

a [tibble](https://tibble.tidyverse.org/reference/tibble-package.html)

## See also

Other NOAA ISD functions:
[`getMeta()`](https://openair-project.github.io/worldmet/reference/getMeta.md),
[`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md),
[`importNOAAlite()`](https://openair-project.github.io/worldmet/reference/importNOAAlite.md)

## Examples

``` r
if (FALSE) { # \dontrun{
meta <- getMetaLive()
head(meta)
} # }
```
