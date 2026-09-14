# Extract and plot relevant acoustic index metadata and LDFCs

This function will use a list of media files from a `wt_*` work flow and
outputs from
[`wt_run_ap()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_run_ap.md)
in order to generate summary plots of acoustic indices and long-duration
false-colour spectrograms. This can be viewed as the "final step" in
interpreting acoustic index and LDFC values from your recordings.

## Usage

``` r
wt_glean_ap(
  x = NULL,
  input_dir,
  purpose = c("quality", "abiotic", "biotic"),
  include_ind = TRUE,
  include_ldfcs = TRUE,
  borders = FALSE
)
```

## Arguments

- x:

  A data frame or tibble; must contain the file name. Use output from
  `` `wt_audio_scanner()` ``.

- input_dir:

  Character; A folder path where outputs from `` `wt_run_ap()` `` are
  stored.

- purpose:

  Character; type of filtering you can choose from

- include_ind:

  Logical; Include index results

- include_ldfcs:

  Logical; Include LDFC results

- borders:

  Logical; Include borders to define different recordings

## Value

Output will return the merged tibble with all information, the summary
plots of the indices and the LDFC

## Examples

``` r
if (FALSE) { # \dontrun{
wt_glean_ap(x = wt_audio_scanner_data, input_dir = "/path/to/my/files")
} # }
```
