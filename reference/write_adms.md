# Export a meteorological data frame in ADMS format

Writes a text file in the ADMS format to a location of the user's
choosing, with optional interpolation of missing values. At present this
function only works with data from
[`import_isd_hourly()`](https://openair-project.github.io/worldmet/reference/import_isd_hourly.md);
it will later be expanded to work with
[`import_ghcn_hourly()`](https://openair-project.github.io/worldmet/reference/import_ghcn_hourly.md)
also.

## Usage

``` r
write_adms(x, file = "./ADMS_met.MET", interp = FALSE, max_gap = 2)
```

## Arguments

- x:

  A data frame imported by
  [`import_isd_hourly()`](https://openair-project.github.io/worldmet/reference/import_isd_hourly.md).

- file:

  A file name for the ADMS file. The file is written to the working
  directory by default.

- interp:

  Should interpolation of missing values be undertaken? If `TRUE` linear
  interpolation is carried out for gaps of up to and including
  `max_gap`.

- max_gap:

  The maximum gap in hours that should be interpolated where there are
  missing data when `interp = TRUE.` Data with gaps more than `max_gap`
  are left as missing.

## Value

`write_adms()` returns the input `dat` invisibly.

## See also

Other Met writing functions:
[`write_met()`](https://openair-project.github.io/worldmet/reference/write_met.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# import some data then export it
dat <- import_isd_hourly(year = 2012)
write_adms(dat, file = "~/adms_met.MET")
} # }
```
