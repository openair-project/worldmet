# Export a meteorological data frame in files, chunked by site and year

Writes a text file in the ADMS format to a location of the user's
choosing, with optional interpolation of missing values. At present this
function only works with data from
[`import_isd_hourly()`](https://openair-project.github.io/worldmet/reference/import_isd_hourly.md);
it will later be expanded to work with
[`import_ghcn_hourly()`](https://openair-project.github.io/worldmet/reference/import_ghcn_hourly.md)
also.

## Usage

``` r
write_met(
  x,
  path = ".",
  ext = c("rds", "delim", "parquet"),
  delim = ",",
  suffix = "",
  progress = rlang::is_interactive()
)
```

## Arguments

- x:

  A data frame imported by
  [`import_isd_hourly()`](https://openair-project.github.io/worldmet/reference/import_isd_hourly.md),
  [`import_ghcn_hourly()`](https://openair-project.github.io/worldmet/reference/import_ghcn_hourly.md),
  or
  [`import_ghcn_daily()`](https://openair-project.github.io/worldmet/reference/import_ghcn_daily.md).

- path:

  The path to a directory to save each file. By default, this is the
  working directory.

- ext:

  The file type to use when saving the data. Can be `"rds"`, `"delim"`
  or `"parquet"`. Note that `"parquet"` requires the `arrow` package.

- delim:

  Delimiter used to separate values when `ext = "delim"`. Must be a
  single character. Defaults to being comma-delimited (`","`).

- suffix:

  An additional suffix to append to file names. Useful examples could be
  `"_ISD"`, `"_hourly"`, `"_lite"`, and so on.

- progress:

  Show a progress bar when writing many stations/years? Defaults to
  `TRUE` in interactive R sessions. Passed to `.progress` in
  [`purrr::walk()`](https://purrr.tidyverse.org/reference/map.html).

## Value

`write_met()` returns `path` invisibly.

## See also

Other Met writing functions:
[`write_adms()`](https://openair-project.github.io/worldmet/reference/write_adms.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# import some data then export it
dat <- import_isd_hourly(year = 2012)
write_met(dat)
} # }
```
