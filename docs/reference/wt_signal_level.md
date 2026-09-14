# Get signals from specific windows of audio

Signal level uses amplitude and frequency thresholds in order to detect
a signal.

## Usage

``` r
wt_signal_level(
  path,
  fmin = 500,
  fmax = NA,
  threshold,
  channel = "left",
  aggregate = NULL
)
```

## Arguments

- path:

  The path to the wav file

- fmin:

  The frequency minimum

- fmax:

  The frequency maximum

- threshold:

  The desired threshold

- channel:

  Choose "left" or "right" channel

- aggregate:

  Aggregate detections by this number of seconds, if desired

## Value

A list object containing the following four elements: output
(dataframe), aggregated (boolean), channel (character), and threshold
(numeric)

## Examples

``` r
if (FALSE) { # \dontrun{
df <- wt_signal_level(path = "")
} # }
```
