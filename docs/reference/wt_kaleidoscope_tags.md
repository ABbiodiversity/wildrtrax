# Convert Kaleidoscope output to tags

`wt_kaleidoscope_tags` Takes the classifier output from Wildlife
Acoustics Kaleidoscope and converts them into a WildTrax tag template
for upload

## Usage

``` r
wt_kaleidoscope_tags(input, output = NULL, freq_bump = TRUE)
```

## Arguments

- input:

  Character; The path to the input csv

- output:

  Character; Path where the output file will be stored

- freq_bump:

  Boolean; Set to TRUE to add a buffer to the frequency values exported
  from Kaleidoscope. Helpful for getting more context around a signal in
  species verification

## Value

A csv formatted as a WildTrax tag template

## Examples

``` r
if (FALSE) { # \dontrun{
wt_kaleidoscope_tags(input = input.csv, output = tags.csv, freq_bump = TRUE)
} # }
```
