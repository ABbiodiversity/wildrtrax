# Filter species from a report

This function filters the species provided in WildTrax reports to only
the groups of interest. The groups available for filtering are mammal,
bird, amphibian, abiotic, insect, and unknown. Zero-filling
functionality is available to ensure all surveys are retained in the
dataset if no observations of the group of interest are available.

## Usage

``` r
wt_tidy_species(data, remove = "", zerofill = TRUE)
```

## Arguments

- data:

  WildTrax main report or tag report from the
  [`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)
  function.

- remove:

  Character; groups to filter from the report ("mammal", "bird",
  "amphibian", "abiotic", "insect", "human", "unknown"). Defaults to
  retaining bird group only.

- zerofill:

  Logical; indicates if zerofilling should be completed. If TRUE, unique
  surveys with no observations after filtering are added to the dataset
  with "NONE" as the value for species_code and/or species_common_name.
  If FALSE, only surveys with observations of the retained groups are
  returned. Default is TRUE.

## Value

A dataframe identical to input with observations of the specified groups
removed.

## Examples

``` r
if (FALSE) { # \dontrun{
dat.tidy <- wt_tidy_species(dat, remove=c("mammal", "unknown"), zerofill = T)
} # }
```
