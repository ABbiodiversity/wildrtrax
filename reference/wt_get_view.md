# Get data from WildTrax views

Fetch data for tables and views in WildTrax. You must specify at least
one of `project` or `organization` depending on the API
**\[experimental\]**

## Usage

``` r
wt_get_view(api, project = NULL, organization = NULL, max_seconds = 300)
```

## Arguments

- api:

  A string specifying the API to query. Must be one of:

  - `"organization_locations"`

  - `"organization_visits"`

  - `"organization_equipment`"

  - `"organization_deployments`"

  - `"organization_recordings`"

  - `"organization_image_sets`"

  - `"organization_usage_report`

  - `"project_aru_tasks"`

  - `"project_camera_tasks"`

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
wt_get_view("organization_locations", organization = 5205)

# Fetch locations by project
wt_get_view("project_locations", project = 620)
} # }
```
