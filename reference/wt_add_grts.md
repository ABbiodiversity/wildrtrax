# Intersect locations to add a GRTS ID

This function intersects location data with the GRTS ID provided by
[NABat](https://www.nabatmonitoring.org/)

## Usage

``` r
wt_add_grts(data, group_locations_in_cell = FALSE)
```

## Arguments

- data:

  Data containing locations

- group_locations_in_cell:

  Option to provide distinct location names if points are found in the
  same cell. Sequentially provides a number for each GRTS ID e.g. 3-1,
  3-2, etc.

## Value

A dataframe with the additional GRTS IDs

## Examples

``` r
if (FALSE) { # \dontrun{

dat.grts <- wt_download_report(reports = "location")
grts.data <- wt_add_grts(dat.grts)
} # }
```
