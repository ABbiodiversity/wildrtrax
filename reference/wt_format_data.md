# Format data for a specified portal

This function takes the WildTrax reports and converts them to the
desired format **\[experimental\]**

## Usage

``` r
wt_format_data(input, format = c("FWMIS", "NABAT"))
```

## Arguments

- input:

  A report from
  [`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)

- format:

  A format i.e. 'FWMIS' or 'NABAT'

## Value

A tibble with the formatted report

## Examples

``` r
if (FALSE) { # \dontrun{

dat <- wt_download_report(reports = c("main","visit","equipment")) |>
wt_format_data(format = 'FWMIS')
} # }
```
