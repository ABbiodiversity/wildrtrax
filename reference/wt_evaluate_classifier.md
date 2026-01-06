# Evaluate a classifier

Calculates precision, recall, and F-score of BirdNET and/or HawkEars for
a requested sequence of thresholds. You can request the metrics at the
minute level for recordings that are processed with the species per
minute method (1SPM).

## Usage

``` r
wt_evaluate_classifier(
  data,
  resolution = NULL,
  remove_species = TRUE,
  species = NULL,
  thresholds = c(0.01, 0.99)
)
```

## Arguments

- data:

  Output from the
  [`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)
  function when you request the `main` and `ai` reports

- resolution:

  Character; either "recording" to summarize at the entire recording
  level or "minute" to summarize the minute level if the `task_method`
  is "1SPM", or "task"

- remove_species:

  Logical; indicates whether species that are not allowed in the
  WildTrax project should be removed from the AI report

- species:

  Character; optional subset of species to calculate metrics for (e.g.,
  species = c("OVEN", "OSFL", "BOCH"))

- thresholds:

  Numeric; start and end of sequence of score thresholds at which to
  calculate performance metrics

## Value

A tibble containing columns for precision, recall, and F-score for each
of the requested thresholds.

## Examples

``` r
if (FALSE) { # \dontrun{
data <- wt_download_report(project_id = 1144, sensor_id = "ARU",
reports = c("main", "ai"), weather_cols = FALSE)

eval <- wt_evaluate_classifier(data, resolution = "recording",
remove_species = TRUE, thresholds = c(0.1, 0.99))
} # }
```
