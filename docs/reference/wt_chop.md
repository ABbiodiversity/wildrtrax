# Segment large audio files

"Chops" up wav files into many smaller files of a desired duration and
writes them to an output folder.

## Usage

``` r
wt_chop(input = NULL, segment_length = NULL, output_folder = NULL)
```

## Arguments

- input:

  A data frame or tibble containing information about audio files

- segment_length:

  Numeric; Segment length in seconds. Modulo recording will be exported
  should there be any trailing time left depending on the segment length
  used

- output_folder:

  Character; output path to where the segments will be stored

## Value

No return value, called for file-writing side effects.

## Examples

``` r
if (FALSE) { # \dontrun{
wt_chop(input = my_files, segment_length = 60, output_folder = "output_folder")
} # }
```
