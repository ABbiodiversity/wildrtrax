# Format WildTrax report for occupancy modelling

This function formats the summary report from the
[`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)
function into an unmarked object for occupancy modelling. The current
version only includes formatting for the ARU sensor and for single
species single season models.

## Usage

``` r
wt_format_occupancy(data, species, siteCovs = NULL)
```

## Arguments

- data:

  Summary report of WildTrax observations from the
  [`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)
  function. Currently only functioning for the ARU sensor.

- species:

  Character; four-letter alpha code for the species desired for
  occupancy modelling.

- siteCovs:

  Optional dataframe of site covariates. Must contain a column with the
  same values as the location field in the data, with one row per unique
  value of location (i.e., one row per site).

## Value

An object of class unmarkedFrameOccu. See
[`?unmarked::unmarkedFrameOccu`](https://ecoverseR.github.io/unmarked/reference/unmarkedFrameOccu.html)
for details.

## Examples

``` r
if (FALSE) { # \dontrun{
dat.occu <- wt_format_occupancy(dat, species="CONI", siteCovs=NULL)
mod <- occu(~ 1 ~ 1, dat.occu)
} # }
```
