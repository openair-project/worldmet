# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```r
# Load package for interactive development
devtools::load_all()

# Run all tests
devtools::test()

# Run a single test file
devtools::test(filter = "import_ghcn")

# Check the full package (CRAN-style)
devtools::check()

# Generate documentation from roxygen2 comments
devtools::document()

# Build pkgdown website
pkgdown::build_site()
```

Code formatting uses the `air` formatter (configured in `air.toml`). Run it via the CLI: `air format R/`.

## Architecture

**worldmet** is an R data-access package with two data source families:

### GHCN (current, primary)
- `import_ghcn_stations()` — fetches station metadata from NOAA's GHCNh/GHCNd station list URLs
- `import_ghcn_hourly()` — downloads pipe-delimited (PSV) or Parquet files per station/year from NOAA, then post-processes; the real work happens in the internal `import_single_ghcn_site()` helper
- `import_ghcn_daily()`, `import_ghcn_monthly()` — analogous for lower-frequency data

### ISD (legacy, deprecated by NOAA as of 2025)
- `import_isd_stations()`, `import_isd_hourly()`, `import_isd_lite()` — older API, still functional but NOAA data only goes to 2025
- `deprecated.R` contains the old camelCase aliases (`importNOAA`, `getMeta`, etc.) which delegate to the new functions

### Key internals
- **Parallelism**: `purrr::in_parallel()` (from purrr ≥ 1.1.0) + `mirai` daemons. Users set `mirai::daemons(n)` once per session; the import functions detect this automatically. The `carrier` package is a required dep because `purrr::in_parallel()` needs it even without parallelism.
- **Time averaging**: `worldmet_time_average()` in `utils.R` is a trimmed copy of `openair::timeAverage()`. Wind direction is averaged via U/V decomposition (`calculate_wind_components()`).
- **Output format**: All functions return a `tibble` with a `date` column in UTC `POSIXct`. Column names are abbreviated by default (`wd`, `ws`, `air_temp`, etc.) to match what `openair` expects.
- `write_adms()` / `write_met()` — export helpers for ADMS atmospheric dispersion format and generic RDS/CSV.
- `weatherCodes.rda` — lookup table for WMO present weather codes, loaded lazily.

### Data flow for `import_ghcn_hourly()`
1. Fetch station metadata once via `import_ghcn_stations(database = "hourly", return = "table")`
2. Build station×year combinations with `tidyr::crossing()`
3. Map `import_single_ghcn_site()` over combinations, optionally in parallel via `purrr::in_parallel()`
4. `dplyr::bind_rows()` results, scrub columns if `extra = FALSE`, optionally rename to abbreviated names, optionally time-average to hourly with `worldmet_time_average()`

## Conventions

- British English spelling throughout (`colour`, `licence`, etc.) — set via `Language: en-GB` in DESCRIPTION
- Roxygen2 with markdown enabled; `@family GHCN functions` / `@family ISD functions` tags group related functions
- Internal helpers are marked `@noRd` and not exported
- `rlang::arg_match()` for argument validation; `cli` for all user-facing messages/warnings/errors
- `.data$` pronoun used consistently in `dplyr` pipelines to avoid `R CMD check` notes
