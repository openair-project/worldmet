# Codes for weather types

This data frame consists of the weather description codes used in the
ISD. It is not of general use to most users.

## Usage

``` r
weatherCodes
```

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 100
rows and 2 columns.

## Details

- pwc:

  Weather code, which can be merged with the `pwc` column in
  [`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md)
  datasets.

- description:

  Description associated with the weather codes.

## Examples

``` r
weatherCodes
#> # A tibble: 100 × 2
#>    pwc   description                                       
#>    <chr> <chr>                                             
#>  1 00    clear skies                                       
#>  2 01    clouds dissolving                                 
#>  3 02    state of sky unchanged                            
#>  4 03    clouds developing                                 
#>  5 04    visibility reduced by smoke                       
#>  6 05    smoke                                             
#>  7 06    widespread dust in suspension not raised by wind  
#>  8 07    dust or sand raised by wind                       
#>  9 08    well developed dust or sand whirls                
#> 10 09    dust or sand storm within sight but not at station
#> # ℹ 90 more rows
```
