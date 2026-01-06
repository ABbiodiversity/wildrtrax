# Find additional species

Check for species reported by BirdNET and HawkEars that the human
listeners did not detect in our project.

## Usage

``` r
wt_additional_species(
  data,
  remove_species = TRUE,
  threshold = 0.5,
  resolution = "task",
  format_to_tags = FALSE,
  output = NULL
)
```

## Arguments

- data:

  Output from the
  [`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)
  function when you request the `main` and `birdnet` reports

- remove_species:

  Logical; indicates whether species that are not allowed in the
  WildTrax project should be removed from the AI report

- threshold:

  Numeric; the desired score threshold

- resolution:

  Character; either "recording" to identify any new species for each
  recording or "location" to identify new species for each location

- format_to_tags:

  Logical; when TRUE, creates a formatted output to turn detections into
  tags for uploading to WildTrax

- output:

  Character; when a valid directory is entered, exports the additional
  detections as tags for sync with a WildTrax project

## Value

A tibble with the same fields as the `birdnet` report with the highest
scoring detection for each new species detection in each recording.

## Examples

``` r
if (FALSE) { # \dontrun{
data <- wt_download_report(project_id = 1144, sensor_id = "ARU",
reports = c("main", "ai"), weather_cols = FALSE)

new <- wt_additional_species(data, remove_species = TRUE,
threshold = 80, resolution="location")
} # }
```
