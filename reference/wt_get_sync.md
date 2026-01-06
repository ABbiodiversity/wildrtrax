# Get data from WildTrax syncs and downloads

Fetch data for syncs and downloads in WildTrax. You must specify at
least one of `project` or `organization` depending on the API

## Usage

``` r
wt_get_sync(api, project = NULL, organization = NULL, max_seconds = 300)
```

## Arguments

- api:

  A string specifying the API to query. Must be one of:

  - `"organization_locations"`

  - `"organization_visits"`

  - `"organization_equipment`"

  - `"organization_deployments`"

  - `"organization_recordings`"

  - `"project_locations"`

  - `"project_aru_tasks"`

  - `"project_aru_tags"`

  - `"project_image_metadata"`

  - `"project_camera_tags"`

  - `"project_point_counts"`

- project:

  Numeric; The project id

- organization:

  Numeric; The organization id

- max_seconds:

  Numeric; Number of seconds to force to wait for downloads.

## Value

A tibble with column headers for the specified API call.

## Examples

``` r
if (FALSE) { # \dontrun{
# Authenticate first:
wt_auth()

# Fetch locations by organization
wt_get_sync("organization_locations", organization = 5)

# Fetch locations by project
wt_get_sync("project_locations", project = 620)
} # }
```
