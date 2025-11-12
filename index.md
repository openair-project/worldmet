![](reference/figures/logo.png)

## **worldmet**

### open source tools to access NOAA Integrated Surface Database (ISD) meteorological observations

**worldmet** provides an easy way to access data from the [NOAA
Integrated Surface
Database](https://www.ncei.noaa.gov/products/land-based-station/integrated-surface-database)
(ISD). The ISD contains detailed surface meteorological data from around
the world for over 35,000 locations. See also the
[map](https://gis.ncdc.noaa.gov/maps/ncei). The package outputs
(typically hourly meteorological data) work very well with the
[**openair**](https://github.com/openair-project/openair) package.

*Part of the openair toolkit*

[![openair](https://img.shields.io/badge/openair_core-06D6A0?style=flat-square)](https://openair-project.github.io/openair/)
\|
[![worldmet](https://img.shields.io/badge/worldmet-26547C?style=flat-square)](https://openair-project.github.io/worldmet/)
\|
[![openairmaps](https://img.shields.io/badge/openairmaps-FFD166?style=flat-square)](https://openair-project.github.io/openairmaps/)
\|
[![deweather](https://img.shields.io/badge/deweather-EF476F?style=flat-square)](https://openair-project.github.io/deweather/)

------------------------------------------------------------------------

## 💡 Core Features

**worldmet** has a small handful of core functionality.

- **Access ISD metadata** using
  [`getMeta()`](https://openair-project.github.io/worldmet/reference/getMeta.md).

- **Import ISD monitoring data** using
  [`importNOAA()`](https://openair-project.github.io/worldmet/reference/importNOAA.md),
  with options to improve performance with parallel processing. Data is
  in a format ready to use with, for example,
  [`openair::windRose()`](https://openair-project.github.io/openair/reference/windRose.html).

- **Write files in ADMS format** using
  [`exportADMS()`](https://openair-project.github.io/worldmet/reference/exportADMS.md).

![](reference/figures/feature-banner.png)

------------------------------------------------------------------------

## 📖 Documentation

All **worldmet** functions are fully documented; access documentation
using R in your IDE of choice.

``` r
?worldmet::importNOAA
```

Documentation is also hosted online on the **package website**.

[![website](https://img.shields.io/badge/website-documentation-blue)](https://openair-project.github.io/worldmet/)

A guide to the openair toolkit can be found in the **online book**,
which contains lots of code snippets, demonstrations of functionality,
and ideas for the application of **openair**’s various functions.

[![book](https://img.shields.io/badge/book-code_demos_and_ideas-blue)](https://openair-project.github.io/book/)

------------------------------------------------------------------------

## 🗃️ Installation

**worldmet** can be installed from **CRAN** with:

``` r
install.packages("worldmet")
```

You can also install the development version of **worldmet** from GitHub
using [pak](https://pak.r-lib.org/):

``` r
# install.packages("pak")
pak::pak("openair-project/worldmet")
```

------------------------------------------------------------------------

🏛️ **worldmet** is primarily maintained by [David
Carslaw](https://github.com/davidcarslaw).

📃 **worldmet** is licensed under the [MIT
License](https://openair-project.github.io/worldmet/LICENSE.html).

🧑‍💻 Contributions are welcome from the wider community. See the
[contributing
guide](https://openair-project.github.io/worldmet/CONTRIBUTING.html) and
[code of
conduct](https://openair-project.github.io/worldmet/CODE_OF_CONDUCT.html)
for more information.
