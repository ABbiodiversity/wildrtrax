# Get a project summary from WildTrax

Obtain a table listing projects that the user is able to download data
for.

## Usage

``` r
wt_get_projects(sensor)
```

## Arguments

- sensor:

  Can be one of "ARU", "CAM", or "PC"

## Value

A data frame listing the projects that the user can download data for,
including: project name, id, year, number of tasks and project status.

## Examples

``` r
if (FALSE) { # \dontrun{
# Authenticate first:
wt_auth()
wt_get_projects(sensor = "ARU")
} # }
```
