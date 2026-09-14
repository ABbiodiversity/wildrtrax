# Get acoustic index values from audio

For generating acoustic indices and false-colour spectrograms using QUT
Ecoacoustics **A**nalysis **P**rograms software. See
<https://github.com/QutEcoacoustics/audio-analysis> for information
about usage and installation of the AP software. Note that this function
relies on having this software installed locally.

This function will batch calculate summary and spectral acoustic indices
and generate false-colour spectrograms for a folder of audio files using
the Towsey.Acoustic configuration (yml) file from the AP software. You
can use the output from `` `wt_audio_scanner()` `` in the function, or
define a local folder with audio files directly.

## Usage

``` r
wt_run_ap(
  x = NULL,
  fp_col = file_path,
  audio_dir = NULL,
  output_dir,
  path_to_ap = "C:\\AP\\AnalysisPrograms.exe",
  delete_media = FALSE
)
```

## Arguments

- x:

  (optional) A data frame or tibble; must contain the absolute audio
  file path and file name. Use output from `` `wt_audio_scanner()` ``.

- fp_col:

  If x is supplied, the column containing the audio file paths. Defaults
  to file_path.

- audio_dir:

  (optional) Character; path to directory storing audio files.

- output_dir:

  Character; path to directory where you want outputs to be stored.

- path_to_ap:

  Character; file path to the AnalysisPrograms software package.
  Defaults to "C:\AP\AnalysisPrograms.exe".

- delete_media:

  Logical; when TRUE, removes the underlying sectioned wav files from
  the Towsey output. Leave to TRUE to save on space after runs.

## Value

Output will return to the specific root directory
