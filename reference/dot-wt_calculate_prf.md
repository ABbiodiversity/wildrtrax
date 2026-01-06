# Internal evaluation function for acoustic classifiers

Internal function to calculate precision, recall, and F-score for a
given score threshold.

## Usage

``` r
.wt_calculate_prf(threshold, data, human_total)
```

## Arguments

- threshold:

  A single numeric value for score threshold

- data:

  Output from the
  [`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)
  function when you request the `main` and `ai` reports

- human_total:

  The total number of detections in the gold standard, typically from
  human listening data (e.g., the main report)

## Value

A vector of precision, recall, F-score, and threshold
