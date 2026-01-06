# Convert GUANO embeded metadata to tags and metadata output for a Project

`wt_guano_tags` Takes the embeded classifier output and converts them
into a WildTrax tag template for upload **\[experimental\]**

## Usage

``` r
wt_guano_tags(path, output = NULL, output_file = NULL)
```

## Arguments

- path:

  Character; The path to the input csv

- output:

  Character; Path where the output file will be stored

- output_file:

  Character; Path of the output file

## Value

A csv formatted as a WildTrax tag template

## Examples

``` r
if (FALSE) { # \dontrun{
wt_guano_tags(path = my_audio_file.csv, output = NULL, output_file = NULL)
} # }
```
