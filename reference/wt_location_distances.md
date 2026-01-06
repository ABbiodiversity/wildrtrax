# General convenience functions

Takes input latitude and longitudes and computes the distances between
each set of valid points

## Usage

``` r
wt_location_distances(input_from_tibble = NULL, input_from_file = NULL)
```

## Arguments

- input_from_tibble:

  Use a tibble constructed with a distinct list of location names,
  latitude and longitude

- input_from_file:

  Use a file downloaded from either an organization or project

## Value

A three-column tibble with the distances between each location

## Examples

``` r
if (FALSE) { # \dontrun{
df <- wt_location_distances(input = my_location_tibble, input_from_file)
} # }
```
