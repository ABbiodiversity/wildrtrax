# Get EXIF metadata from images

This function gets all relevant EXIF metadata from images in Projects
**\[experimental\]**

## Usage

``` r
wt_get_exif(data)
```

## Arguments

- data:

  `wt_download_report(reports = c(image_report))` object containing

## Value

A dataframe with the EXIF metadata for each image

## Examples

``` r
if (FALSE) { # \dontrun{

dat <- wt_download_report(reports = c("image_report"))
exif.data <- wt_get_exif(dat)
} # }
```
