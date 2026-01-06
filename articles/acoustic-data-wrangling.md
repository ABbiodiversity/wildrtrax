# Acoustic data wrangling

The recommended workflow to wrangle together data for analysis in
`wildrtrax` is as follows. Once you have your data from
[`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md).

- Remove unneeded species:
  [`wt_tidy_species()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_tidy_species.md)
- Convert TMTT counts to numeric:
  [`wt_replace_tmtt()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_replace_tmtt.md)
- Convert the species to a wide format:
  [`wt_make_wide()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_make_wide.md)

``` r
# Start by getting everything you need
Sys.setenv(WT_USERNAME = 'guest', WT_PASSWORD = 'Apple123')
wt_auth()
my_report <- wt_download_report(project_id = 620, sensor_id = 'ARU', reports = "main")
```

## Data wrangling

Let’s use some of the functins that are available to start cleaning up a
data set. For this question, we don’t need certain abiotic and mammal
codes so let’s remove those with
[`wt_tidy_species()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_tidy_species.md),

``` r
my_tidy_data <- wt_tidy_species(my_report, remove = c("mammal"), zerofill = F)

# Difference in rows
round((nrow(my_tidy_data)/nrow(my_report)),2)
#> [1] 0.85
```

So about 15% of detections were mammals. Next, convert TMTT (too many to
tag) counts to numeric:

``` r
my_tmtt_data <- wt_replace_tmtt(data = my_tidy_data, calc = "round")
#> # A tibble: 330 × 31
#>    organization project_id location  location_id location_buffer_m longitude
#>    <chr>             <int> <chr>           <int>             <dbl>     <dbl>
#>  1 BU                  620 CHPP-WP-1       94515                NA     -110.
#>  2 BU                  620 CHPP-WP-1       94515                NA     -110.
#>  3 BU                  620 CHPP-WP-1       94515                NA     -110.
#>  4 BU                  620 CHPP-WP-1       94515                NA     -110.
#>  5 BU                  620 CHPP-WP-1       94515                NA     -110.
#>  6 BU                  620 CHPP-WP-1       94515                NA     -110.
#>  7 BU                  620 CHPP-WP-1       94515                NA     -110.
#>  8 BU                  620 CHPP-WP-1       94515                NA     -110.
#>  9 BU                  620 CHPP-WP-1       94515                NA     -110.
#> 10 BU                  620 CHPP-WP-1       94515                NA     -110.
#> # ℹ 320 more rows
#> # ℹ 25 more variables: latitude <dbl>, equipment_make <chr>,
#> #   equipment_model <chr>, recording_id <dbl>, recording_date_time <dttm>,
#> #   task_id <dbl>, task_is_complete <lgl>, task_duration <dbl>,
#> #   task_method <chr>, species_code <chr>, species_common_name <chr>,
#> #   species_scientific_name <chr>, individual_order <int>, tag_id <int>,
#> #   individual_count <chr>, vocalization <chr>, detection_time <dbl>, …
```

and finally, widen the data into a species matrix.

``` r
my_wide_data <- wt_make_wide(data = my_tmtt_data, sound = "all")

head(my_wide_data)
#> # A tibble: 6 × 77
#>   organization project_id location  location_id location_buffer_m longitude
#>   <chr>             <int> <chr>           <int>             <dbl>     <dbl>
#> 1 BU                  620 CHPP-WP-1       94515                NA     -110.
#> 2 BU                  620 CHPP-WP-1       94515                NA     -110.
#> 3 BU                  620 CHPP-WP-1       94515                NA     -110.
#> 4 BU                  620 CHPP-WP-1       94515                NA     -110.
#> 5 BU                  620 CHPP-WP-2       94518                NA     -110.
#> 6 BU                  620 CHPP-WP-2       94518                NA     -110.
#> # ℹ 71 more variables: latitude <dbl>, equipment_make <chr>,
#> #   equipment_model <chr>, recording_id <dbl>, recording_date_time <dttm>,
#> #   task_id <dbl>, task_is_complete <lgl>, task_duration <dbl>,
#> #   task_method <chr>, AMCR <dbl>, AMRE <dbl>, AMRO <dbl>, BAOR <dbl>,
#> #   BBMA <dbl>, BCCH <dbl>, BHCO <dbl>, BHGR <dbl>, CANG <dbl>, CEDW <dbl>,
#> #   CHSP <dbl>, CONI <dbl>, COPO <dbl>, CORA <dbl>, COYE <dbl>, DEJU <dbl>,
#> #   DUFL <dbl>, EAPH <dbl>, GCKI <dbl>, GHOW <dbl>, HAWO <dbl>, LAZB <dbl>, …
```

## Occupancy modelling

You can also perform a single-season, single-species occupancy work flow
using
[`wt_format_occupancy()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_format_occupancy.md)
once the data is downloaded.

``` r
dat.occu <- wt_format_occupancy(my_report, species="WCSP", siteCovs=NULL)
mod <- unmarked::occu(~ 1 ~ 1, dat.occu)
mod
#> 
#> Call:
#> unmarked::occu(formula = ~1 ~ 1, data = dat.occu)
#> 
#> Occupancy (logit-scale):
#>  Estimate    SE    z P(>|z|)
#>      1.22 0.893 1.36   0.172
#> 
#> Detection (logit-scale):
#>  Estimate    SE      z P(>|z|)
#>    -0.297 0.333 -0.891   0.373
#> 
#> AIC: 66.07266 
#> Number of sites: 8
```
