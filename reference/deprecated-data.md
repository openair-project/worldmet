# Deprecated data functions

**\[deprecated\]**

This function is part of an old `worldmet` API. Please use the following
alternatives:

- `exportADMS()` -\>
  [`write_adms()`](https://openair-project.github.io/worldmet/reference/write_adms.md)

- the `path` argument -\>
  [`write_met()`](https://openair-project.github.io/worldmet/reference/write_met.md)

## Usage

``` r
exportADMS(dat, out = "./ADMS_met.MET", interp = FALSE, maxgap = 2)
```

## Arguments

- dat:

  A data frame imported by
  [`importNOAA()`](https://openair-project.github.io/worldmet/reference/deprecated-isd.md).

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
