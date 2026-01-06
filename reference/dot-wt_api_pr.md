# An internal function to handle generic POST requests to WildTrax

Generic function to handle certain POST requests

## Usage

``` r
.wt_api_pr(path, ..., max_time = 300)
```

## Arguments

- path:

  The path to the API

- ...:

  Argument to pass along into POST query

- max_time:

  The maximum number of seconds the API request can take. By default
  300.
