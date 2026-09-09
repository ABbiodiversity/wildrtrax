# Convert GUANO embeded metadata to tags and metadata output for a Project

`wt_guano_tags` Takes the embeded classifier output and converts them
into a WildTrax tag template for upload **\[experimental\]**

## Usage

``` r
wt_guano_tags(path, output = FALSE, output_file = NULL)
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
# Process a single audio file
wt_guano_tags("/path/to/audio_file.wav")

# Process audio files from a directory
wt_audio_scanner("/path/to/audio", file_type = "wav", extra_cols = TRUE) |>
  purrr::map(.x = .$file_path, .f = ~wt_guano_tags(.x)) |>
  bind_rows()
} # }
```
