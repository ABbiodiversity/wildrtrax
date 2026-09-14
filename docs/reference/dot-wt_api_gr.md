# An internal function to handle generic GET requests to WildTrax

Generic function to handle certain GET requests

## Usage

``` r
.wt_api_gr(path, ..., max_time = 300)
```

## Arguments

- path:

  The path to the API

- ...:

  Argument to pass along into GET query

- max_time:

  The maximum number of seconds the API request can take. By default
  300.
