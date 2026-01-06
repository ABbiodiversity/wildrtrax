# Convert to a wide survey by species dataframe

This function converts a long-formatted report into a wide survey by
species dataframe of abundance values.

## Usage

``` r
wt_make_wide(data, sound = "all")
```

## Arguments

- data:

  WildTrax main report or tag report from the
  [`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)
  function.

- sound:

  Character; vocalization type(s) to retain ("all", "Song", "Call",
  "Non-vocal"). Can be used to remove certain types of detections.
  Defaults to "all" (i.e., no filtering).

## Value

A dataframe identical to input with observations of the specified groups
removed.

## Examples

``` r
if (FALSE) { # \dontrun{
dat.tidy <- wt_tidy_species(dat)
dat.tmtt <- wt_replace_tmtt(dat.tidy)
dat.wide <- wt_make_wide(dat.tmtt, sound="all")
} # }
```
