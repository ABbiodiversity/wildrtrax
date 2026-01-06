# Batch download location photos

Download location photos from an Organization **\[experimental\]**

## Usage

``` r
wt_location_photos(organization, output = NULL)
```

## Arguments

- organization:

  Character; The Organization acronym from which photos are being
  downloaded

- output:

  Character; Directory where location photos would be stored on your
  machine

## Value

A folder of photos or an object containing the download information for
said photos

## Examples

``` r
if (FALSE) { # \dontrun{
# Authenticate first:
wt_auth()
wt_location_photos(organization = 'ABMI', output = NULL)
} # }
```
