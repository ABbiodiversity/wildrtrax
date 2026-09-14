# Download data from Data Discover

Download Data Discover results from projects across WildTrax

## Usage

``` r
wt_dd_summary(sensor = c("ARU", "CAM", "PC"), species = NULL, boundary = NULL)
```

## Arguments

- sensor:

  The sensor you wish to query from either 'ARU', 'CAM' or 'PC'

- species:

  The species you want to search for (e.g. 'White-throated Sparrow').
  Multiple species can be included.

- boundary:

  The custom boundary you want to use. Must be a list of at least four
  latitude and longitude points where the last point is a duplicate of
  the first, or an object of class "bbox" (as produced by sf::st_bbox)

## Value

A list of two tibbles one from the map and the other from the data

## Examples

``` r
if (FALSE) { # \dontrun{

aoi <- list(
c(-110.85438, 57.13472),
c(-114.14364, 54.74858),
c(-110.69368, 52.34150),
c(-110.85438, 57.13472)
)

dd <- wt_dd_summary(sensor = 'ARU', species = 'White-throated Sparrow', boundary = aoi)
} # }
```
