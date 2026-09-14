# Standardize Audiomoth Filenames

Recursively scans a directory for `.wav` files produced by Audiomoth
devices and renames them by prepending the parent folder name to each
filename. For example, a file named `20240407_062500.wav` inside a
folder `LOCATION-ABC` becomes `LOCATION-ABC_20240407_062500.wav`.

## Usage

``` r
wt_format_audiomoth_filenames(input_dir)
```

## Arguments

- input_dir:

  Character string. The path to the top-level directory containing
  Audiomoth folders and audio files.

## Value

A tibble with the original filepaths and the corresponding new
filepaths. Files are renamed in place.

## Examples

``` r
if (FALSE) { # \dontrun{
wt_format_audiomoth_filenames("/path/to/my_dir")
} # }
```
