# Set of analysis functions

This function takes your independent detection data and summarises it by
location, specified time interval, and species.

## Usage

``` r
wt_summarise_cam(
  detect_data,
  raw_data,
  time_interval = "day",
  variable = "detections",
  output_format = "wide",
  species_col = species_common_name,
  effort_data = NULL,
  exclude_out_of_range = FALSE,
  project_col = project_id,
  station_col = location,
  date_time_col = image_date_time,
  start_col = start_date,
  end_col = end_date,
  detection_id_col = detection,
  start_col_det = start_time,
  image_set_id = image_set_id
)
```

## Arguments

- detect_data:

  Detection data generated from `wt_ind_det()`.

- raw_data:

  The raw camera tag data, which is used to infer the effort (i.e. date
  ranges of operation) for each camera. Optionally, can supply
  effort_data directly instead.

- time_interval:

  Character; Can be either "full", "month", "week", or "day" (default).

- variable:

  Character; Can be either "detections" (default), "presence", "counts",
  or "all" (if you want all three).

- output_format:

  Character; The format of the dataframe returned to you. Can be either
  "wide" (default) or "long".

- species_col:

  Defaults to `species_common_name`. The column referring to species.
  Use to switch between common and scientific names of species, if you
  have both.

- effort_data:

  Optionally supply your own effort data.

- exclude_out_of_range:

  Logical; Remove days from effort when camera field-of-view is
  obscured.

- project_col:

  Defaults to `project_id`. The column referring to project in your
  effort data.

- station_col:

  Defaults to `location`. The column referring to each individual camera
  station/location in your effort data.

- date_time_col:

  Defaults to `image_date_time`. The column referring to image date-time
  stamp.

- start_col:

  Defaults to `start_date`. The column indicating the start date of the
  camera location

- end_col:

  Defaults to `end_date`. The column indicating the end date of the
  camera location

- detection_id_col:

  Defaults to `detection`. The column indicating the detection id

- start_col_det:

  Defaults to `start_time`. The column indicating the start time of the
  independent detections

- image_set_id:

  Defaults to `image_set_id`.

## Value

A dataframe summarising your camera data by location, time interval, and
species.

## Summarise camera data by location, time interval, and species.

NA

## Examples

``` r
if (FALSE) { # \dontrun{
summary <- wt_summarise_cam(
x, y, time_interval = "day", variable = "detections", output_format = "wide"
)
} # }
```
