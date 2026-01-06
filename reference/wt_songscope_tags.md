# Convert Songscope output to tags

Convert Songscope output to tags

## Usage

``` r
wt_songscope_tags(
  input,
  output = c("env", "csv"),
  output_file = NULL,
  species,
  vocalization,
  score_filter,
  method = NULL,
  duration,
  sample_freq
)
```

## Arguments

- input:

  Character; The path to the input csv

- output:

  Character; Path where the output file will be stored

- output_file:

  Character; Path of the output file

- species:

  Character; Short-hand code for the species (see
  [`wt_get_species()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_get_species.md))

- vocalization:

  Character; The vocalization type from either Song, Call, Non-Vocal,
  Nocturnal flight call and Feeding Buzz

- score_filter:

  Numeric; Filter the detections by a score threshold

- method:

  Character; Include options from 1SPT, 1SPM or None

- duration:

  Numeric; length of the task in seconds

- sample_freq:

  Numeric; The sampling frequency in Hz of the recording

## Value

A csv formatted as a WildTrax tag template
