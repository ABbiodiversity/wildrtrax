# Scan acoustic data to a standard format

Scans directories of audio data

## Usage

``` r
wt_audio_scanner(path, file_type, extra_cols = FALSE)
```

## Arguments

- path:

  Character; The path to the directory with audio files

- file_type:

  Character; File types of wav, wac, flac or all

- extra_cols:

  Boolean; TRUE returns duration, sample rate and channels

## Value

A tibble with a summary of your audio files.

## Examples

``` r
if (FALSE) { # \dontrun{
wt_audio_scanner(path = ".", file_type = "wav", extra_cols = T)
} # }
```
