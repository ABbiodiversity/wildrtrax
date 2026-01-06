# Authenticate into WildTrax

Obtain Auth0 credentials using WT_USERNAME and WT_PASSWORD stored as
environment variables

## Usage

``` r
wt_auth(force = FALSE)
```

## Arguments

- force:

  Logical; whether or not the force re-authentication even if token has
  not expired. Defaults to FALSE.

## Examples

``` r
if (FALSE) { # \dontrun{
# Authenticate first:
wt_auth(force = FALSE)
} # }
```
