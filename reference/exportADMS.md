# Export a meteorological data frame in ADMS format

Writes a text file in the ADMS format to a location of the user's
choosing, with optional interpolation of missing values.

## Usage

``` r
exportADMS(dat, out = "./ADMS_met.MET", interp = FALSE, maxgap = 2)
```

## Arguments

- dat:

  A data frame imported by
  [`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md).

- out:

  A file name for the ADMS file. The file is written to the working
  directory by default.

- interp:

  Should interpolation of missing values be undertaken? If `TRUE` linear
  interpolation is carried out for gaps of up to and including `maxgap`.

- maxgap:

  The maximum gap in hours that should be interpolated where there are
  missing data when `interp = TRUE.` Data with gaps more than `maxgap`
  are left as missing.

## Value

`exportADMS()` returns the input `dat` invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
# import some data then export it
dat <- importNOAA(year = 2012)
exportADMS(dat, out = "~/adms_met.MET")
} # }
```
