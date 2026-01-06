# Internal function for QPAD offsets

Functions to format reports for qpad offset calculation.

## Usage

``` r
.make_x(data, tz = "local", check_xy = TRUE)
```

## Arguments

- data:

  Dataframe output from the `wt_make_wide` function.

- tz:

  Character; whether or not the data is in local or UTC time ("local",
  or "utc"). Defaults to "local".

- check_xy:

  Logical; check whether coordinates are within the range that QPAD
  offsets are valid for.

## Details

QPAD offsets, wrapped by the `wt_qpad_offsets` function.
