# Evaluate independent camera detections

Create an independent detections dataframe using camera data from
WildTrax

## Usage

``` r
wt_ind_detect(
  x,
  threshold,
  units = "minutes",
  datetime_col = image_date_time,
  remove_human = TRUE,
  remove_domestic = TRUE
)
```

## Arguments

- x:

  A dataframe of camera data; preferably, the main report from
  [`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md).

- threshold:

  Numeric; time interval to parse out independent detections.

- units:

  The threshold unit. Can be one of three values, "seconds", "minutes",
  "hours".

- datetime_col:

  Defaults to `image_date_time`; The column indicating the timestamp of
  the image.

- remove_human:

  Logical; Should human and human-related tags (e.g. vehicles) be
  removed? Defaults to TRUE.

- remove_domestic:

  Logical; Should domestic animal tags (e.g. cows) be removed? Defaults
  to TRUE.

## Value

A dataframe of independent detections in your camera data, based on the
threshold you specified. The df will include information about the
duration of each detection, the number of images, the average number of
individual animals per image, and the max number of animals in the
detection.

## Examples

``` r
if (FALSE) { # \dontrun{
detections <- wt_ind_detect(x = df, threshold = 30, units = "minutes")
} # }
```
