# Download formatted reports from WildTrax

Download various ARU, camera, or point count data from projects across
WildTrax

## Usage

``` r
wt_download_report(project_id, sensor_id, reports, max_seconds = 300)
```

## Arguments

- project_id:

  Numeric; the project ID number that you would like to download data
  for. Use
  [`wt_get_projects()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_get_projects.md)
  to retrieve these IDs.

- sensor_id:

  Character; Can either be "ARU", "CAM", or "PC".

- reports:

  Character; The report type to be returned. Multiple values are
  accepted as a concatenated string.

- max_seconds:

  Numeric; Number of seconds to force to wait for downloads.

## Value

If multiple report types are requested, a list object is returned; if
only one, a dataframe.

## Details

Valid values for argument `report` when `sensor_id` = "CAM" currently
are:

- main

- project

- location

- image_report

- image_set_report

- tag

- megadetector

- definitions

Valid values for argument `report` when `sensor_id` = "ARU" currently
are:

- main

- project

- location

- recording

- tag

- ai

- definitions

Valid values for argument `report` when `sensor_id` = "PC" currently
are:

- main

- project

- location

- point_count

- definitions

## Examples

``` r
if (FALSE) { # \dontrun{
# Authenticate first:
wt_auth()
a_camera_project <- wt_download_report(
project_id = 397, sensor_id = "CAM", reports = c("tag", "image_set_report"))

an_aru_project <- wt_download_report(
project_id = 47, sensor_id = "ARU", reports = c("main", "ai"))
} # }
```
