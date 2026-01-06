# Camera data wrangling

The use of camera traps in ecological studies has become increasingly
popular for monitoring wildlife. Managing and analyzing camera trap data
efficiently is important for extracting meaningful and accurate
insights. In this vignette, we will explore how to perform camera data
wrangling, specifically focusing on the ABMI’s [Ecosystem Health 2014
data
set](https://portal.wildtrax.ca/home/camera-deployments.html?sensorId=CAM&projectId=205).

Use the
[`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)
function to retrieve the main report for the CAM sensor in the Ecosystem
Health 2014 project:

``` r
eh14_raw <- wt_download_report(
  project_id = 205, 
  sensor_id = "CAM",
  report = "main"
)
```

``` r
head(eh14_raw)
```

    ##   project_id location location_id latitude longitude location_buffer_m
    ## 1        205   509-NW       47752  56.6338 -111.7007              5500
    ## 2        205   509-NW       47752  56.6338 -111.7007              5500
    ## 3        205   509-NW       47752  56.6338 -111.7007              5500
    ## 4        205   509-NW       47752  56.6338 -111.7007              5500
    ## 5        205   509-NW       47752  56.6338 -111.7007              5500
    ## 6        205   509-NW       47752  56.6338 -111.7007              5500
    ##   equipment_serial image_id     image_date_time image_set_id image_fov
    ## 1   P900HF12171487  5584838 2014-03-24 14:05:41         1344      <NA>
    ## 2   P900HF12171487  5584839 2014-03-24 14:05:43         1344      <NA>
    ## 3   P900HF12171487 15413607 2014-03-24 14:05:45         1344      <NA>
    ## 4   P900HF12171487 15413608 2014-03-24 14:05:46         1344      <NA>
    ## 5   P900HF12171487 15413500 2014-03-24 14:05:47         1344      <NA>
    ## 6   P900HF12171487 15413561 2014-03-24 14:05:50         1344      <NA>
    ##   image_snow image_snow_depth_m image_water_depth_m species_scientific_name
    ## 1         NA                 NA                  NA                    <NA>
    ## 2         NA                 NA                  NA                    <NA>
    ## 3         NA                 NA                  NA                    <NA>
    ## 4         NA                 NA                  NA                    <NA>
    ## 5         NA                 NA                  NA                    <NA>
    ## 6         NA                 NA                  NA                    <NA>
    ##   species_common_name individual_count age_class sex_class behaviours
    ## 1         STAFF/SETUP              VNA       VNA       VNA       <NA>
    ## 2         STAFF/SETUP              VNA       VNA       VNA       <NA>
    ## 3         STAFF/SETUP              VNA       VNA       VNA       <NA>
    ## 4         STAFF/SETUP              VNA       VNA       VNA       <NA>
    ## 5         STAFF/SETUP              VNA       VNA       VNA       <NA>
    ## 6         STAFF/SETUP              VNA       VNA       VNA       <NA>
    ##   health_diseases coat_colours coat_attributes tine_attributes direction_travel
    ## 1            <NA>         <NA>            <NA>            <NA>             <NA>
    ## 2            <NA>         <NA>            <NA>            <NA>             <NA>
    ## 3            <NA>         <NA>            <NA>            <NA>             <NA>
    ## 4            <NA>         <NA>            <NA>            <NA>             <NA>
    ## 5            <NA>         <NA>            <NA>            <NA>             <NA>
    ## 6            <NA>         <NA>            <NA>            <NA>             <NA>
    ##   has_collar has_eartag  ihf      observer observer_id tag_comments
    ## 1         NA         NA <NA> Kate Broadley         245         <NA>
    ## 2         NA         NA <NA> Kate Broadley         245         <NA>
    ## 3         NA         NA <NA> Kate Broadley         245         <NA>
    ## 4         NA         NA <NA> Kate Broadley         245         <NA>
    ## 5         NA         NA <NA> Kate Broadley         245         <NA>
    ## 6         NA         NA <NA> Kate Broadley         245         <NA>
    ##   tag_needs_review tag_is_verified image_in_wildtrax  tag_id
    ## 1            FALSE           FALSE              TRUE 3368979
    ## 2            FALSE           FALSE              TRUE 3368980
    ## 3            FALSE           FALSE              TRUE 9246962
    ## 4            FALSE           FALSE              TRUE 9246963
    ## 5            FALSE           FALSE              TRUE 9246918
    ## 6            FALSE           FALSE              TRUE 9246946

Evaluate **independent detections** with
[`wt_ind_detect()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_ind_detect.md):

``` r
# Back to the Ecosystem Health 2014 data.

eh14_detections <- wt_ind_detect(
  x = eh14_raw, 
  threshold = 30,
  units = "minutes",
  remove_human = TRUE, 
  remove_domestic = TRUE 
)
```

``` r
head(eh14_detections, width = 75) 
```

    ##                        detection project_id location
    ## 1                Snowshoe Hare 1        205   509-NW
    ## 2            White-tailed Deer 1        205   509-NW
    ## 3                   Black Bear 1        205   509-SW
    ## 4                  Canada Lynx 1        205   509-SW
    ## 5                    Gray Wolf 1        205   509-SW
    ## 6 Grouse, Ptarmigan and allies 1        205   509-SW
    ##            species_common_name          start_time            end_time
    ## 1                Snowshoe Hare 2014-03-27 02:10:28 2014-03-27 02:10:28
    ## 2            White-tailed Deer 2014-06-20 11:35:08 2014-06-20 11:35:08
    ## 3                   Black Bear 2014-06-05 07:30:17 2014-06-05 07:33:38
    ## 4                  Canada Lynx 2014-04-04 22:19:04 2014-04-04 22:20:04
    ## 5                    Gray Wolf 2014-04-28 19:04:00 2014-04-28 19:06:57
    ## 6 Grouse, Ptarmigan and allies 2014-03-25 13:39:12 2014-03-25 13:39:16
    ##   total_duration_seconds n_images avg_animals_per_image max_animals
    ## 1                      0        1                     1           1
    ## 2                      0        1                     1           1
    ## 3                    201        9                     1           1
    ## 4                     60        9                     1           1
    ## 5                    177       23                     1           1
    ## 6                      4        3                     1           1

So there are **313** independent detections in this data set, when using
a threshold of 30 minutes.

The output from
[`wt_ind_detect()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_ind_detect.md)
gave us some useful information. But we probably need to do additional
wrangling for our data to be in the proper format for certain modeling
techniques (e.g. habitat modeling, occupancy). For example, we want to
evaluate the number of detections in a specified time interval
(e.g. daily, weekly, or monthly), *including zeroes*.

## Summarise your camera data

With
[`wt_summarise_cam()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_summarise_cam.md)
you can get:

- The output from
  [`wt_ind_detect()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_ind_detect.md)
  (e.g. the object `eh14_detections`)
- Your raw data (e.g. the object `eh14_raw`)
- The time interval you’re interested in (e.g. weekly)
- The variable you’re interested in (e.g. detections, presence/absence)
- The desired output format (‘wide’ or ‘long’)

``` r
# A call to `wt_summarise_cam()`:

eh14_summarised <- wt_summarise_cam(
  # Supply your detection data
  detect_data = eh14_detections,
  # Supply your raw image data
  raw_data = eh14_raw,
  # Now specify the time interval you're interested in 
  time_interval = "week",
  # What variable are you interested in?
  variable = "detections",
  # Your desired output format (wide or long) 
  output_format = "wide" 
)
```

``` r
head(eh14_summarised)
```

    ##   project_id location year week n_days_effort Black Bear Canada Lynx Coyote
    ## 1        205   509-NW 2014   13             7          0           0      0
    ## 2        205   509-NW 2014   14             7          0           0      0
    ## 3        205   509-NW 2014   15             7          0           0      0
    ## 4        205   509-NW 2014   16             7          0           0      0
    ## 5        205   509-NW 2014   17             7          0           0      0
    ## 6        205   509-NW 2014   18             7          0           0      0
    ##   Cranes, Rails, Coots Crow Deer Ducks, Swans, Geese Fisher Gray Jay Gray Wolf
    ## 1                    0    0    0                   0      0        0         0
    ## 2                    0    0    0                   0      0        0         0
    ## 3                    0    0    0                   0      0        0         0
    ## 4                    0    0    0                   0      0        0         0
    ## 5                    0    0    0                   0      0        0         0
    ## 6                    0    0    0                   0      0        0         0
    ##   Grouse, Ptarmigan and allies Marten Moose Red Fox Red Squirrel Snowshoe Hare
    ## 1                            0      0     0       0            0             1
    ## 2                            0      0     0       0            0             1
    ## 3                            0      0     0       0            0             0
    ## 4                            0      0     0       0            0             0
    ## 5                            0      0     0       0            0             0
    ## 6                            0      0     0       0            0             0
    ##   Songbird Unidentified White-tailed Deer
    ## 1        0            0                 0
    ## 2        0            0                 0
    ## 3        0            0                 0
    ## 4        0            0                 0
    ## 5        0            0                 0
    ## 6        0            0                 0

And now you can get straight into the science!
