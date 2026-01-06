# Identify optimal threshold

Retrieves the score threshold that maximizes F-score, which is a
trade-off between precision and recall.

## Usage

``` r
wt_classifier_threshold(data)
```

## Arguments

- data:

  Tibble output from the
  [`wt_evaluate_classifier()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_evaluate_classifier.md)
  function.

## Value

A single numeric value

## Examples

``` r
if (FALSE) { # \dontrun{
data <- wt_download_report(project_id = 1144, sensor_id = "ARU",
reports = c("main", "ai"), weather_cols = FALSE)

eval <- wt_evaluate_classifier(data, resolution = "recording",
remove_species = TRUE, thresholds = c(10, 99))

threshold_use <- wt_classifier_threshold(eval) |> print()
} # }
```
