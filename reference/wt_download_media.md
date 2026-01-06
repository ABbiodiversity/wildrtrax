# Download media

Download acoustic and image media in batch. Includes the download of tag
clips and spectrograms for the ARU sensor.

## Usage

``` r
wt_download_media(
  input,
  output,
  type = c("recording", "image", "tag_clip_audio", "tag_clip_spectrogram")
)
```

## Arguments

- input:

  The report data

- output:

  The output folder

- type:

  Either recording, image, tag_clip_spectrogram, tag_clip_audio

## Value

An organized folder of media. Assigning wt_download_tags to an object
will return the table form of the data with the functions returning the
after effects in the output directory

## Examples

``` r
if (FALSE) { # \dontrun{
dat.report <- wt_download_report() |>
wt_download_media(output = "my/output/folder", type = "recording")
} # }
```
