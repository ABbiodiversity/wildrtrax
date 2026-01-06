# Replace 'TMTT' abundance with model-predicted values

This function uses a lookup table of model-predicted values to replace
'TMTT' entries in listener-processed ARU data from WildTrax. The
model-predicted values were produced using estimated abundances for
'TMTT' entries in mixed effects model with a Poisson distribution and
random effects for species and observer.

## Usage

``` r
wt_replace_tmtt(data, calc = "round")
```

## Arguments

- data:

  Dataframe of WildTrax observations, for example the summary report.

- calc:

  Character; method to convert model predictions to integer ("round",
  "ceiling", or "floor"). See `?round()` for details.

## Value

A dataframe identical to input with 'TMTT' entries in the abundance
column replaced by integer values.

## Examples

``` r
if (FALSE) { # \dontrun{
dat.tmtt <- wt_replace_tmtt(dat, calc="round")
} # }
```
