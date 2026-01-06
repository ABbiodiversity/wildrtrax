# Changelog

## wildrtrax 1.5

### Major changes

- Migrated to support [**WildTrax 2.0
  APIs**](https://portal.wildtrax.ca/). The legacy function
  `wt_get_download_summary()` has been replaced by
  [`wt_get_projects()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_get_projects.md).
- Added
  [`wt_format_audiomoth_filenames()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_format_audiomoth_filenames.md)
  to prepend location prefixes to
  [AudioMoth](https://www.openacousticdevices.info/audiomoth) recordings
  that contain only date–time stamps.
- Added
  [`wt_get_exif()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_get_exif.md)
  to extract and return EXIF metadata from image files associated with
  Projects.
- Added
  [`wt_guano_tags()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_guano_tags.md)
  to convert embedded GUANO metadata into a WildTrax-compatible tag
  template for upload.
- Added
  [`wt_get_view()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_get_view.md)
  to access structured WildTrax API views and return results as tibbles.
- Added
  [`wt_get_project_species()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_get_project_species.md)
  to retrieve species lists associated with a specific Project.

### Minor changes

- Vignettes improved and updated
- [`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)
  no longer explicitly removes weather columns
- Queries benchmarked as 2-3x on new production server at the University
  of Alberta in Edmonton, Canada
- Continued code coverage and testing improvements

## wildrtrax 1.4

### Major changes

- New function,
  [`wt_get_sync()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_get_sync.md),
  allows users to get columns and data from syncs (upload / download and
  table views) across the system. Functionally replaces
  `wt_get_recordings()`, `wt_get_locations()`, `wt_get_visits()`,
  `wt_get_image_sets()` in one smooth function relevant to the
  Organization or Project needed.
- Fixed a bug that incorrectly adjusted time zones in
  [`wt_qpad_offsets()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_qpad_offsets.md).
  This bug affected QPAD offsets used for [species with time since
  sunrise in the top
  model](https://github.com/borealbirds/QPAD-offsets-correction/blob/main/qpad_tssr_species.csv)
  and in areas outside the Mountain Time Zone (MST/MDT). For more
  information, please see the [BAM QPAD correction
  repository](https://github.com/borealbirds/QPAD-offsets-correction)
  for further details or email <bamp@ualberta.ca> for assistance.

### Minor changes

- Additional argument to
  [`wt_summarise_cam()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_summarise_cam.md)
  using `image_set_id` to adjust for effort across multiple deployments
  (see [\#80](https://github.com/ABbiodiversity/wildrtrax/issues/80));
  additional enhancements for
  [`wt_ind_detect()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_ind_detect.md)
  (see [\#81](https://github.com/ABbiodiversity/wildrtrax/issues/81),
  [\#82](https://github.com/ABbiodiversity/wildrtrax/issues/82).
- \#84 through e2e181a for
  [`wt_ind_detect()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_ind_detect.md),
  species detections are now generated separately for each species and
  then combined afterward into a single output.
- Fixed bugs and enhanced usage of
  [`wt_kaleidoscope_tags()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_kaleidoscope_tags.md)
  (see [\#77](https://github.com/ABbiodiversity/wildrtrax/issues/77)).

## wildrtrax 1.3.3

### Major changes

- Continued GET request support with new functions: `wt_get_visits()`,
  `wt_get_recordings()`, `wt_get_image_sets()`,
  [`wt_get_project_species()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_get_project_species.md)
- `wt_get_threshold` becomes
  [`wt_classifier_threshold()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_classifier_threshold.md)
  to distinguish from other GET functions

### Minor changes

- Camera function maintenance for
  [\#70](https://github.com/ABbiodiversity/wildrtrax/issues/70);
  increasing camera test suites for common permutations
- Branching development to prepare package for WildTrax 2.0.
- Introduced the `max_seconds` argument in
  [`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)
  to provide customizable timeout control for users with slower internet
  connections or larger project downloads.
- Remove QPAD from Remotes. Users should be prompted to download QPAD
  separately if not already installed. Fix in timezone
  ([\#78](https://github.com/ABbiodiversity/wildrtrax/pull/78)).

## wildrtrax 1.3.2

### Major changes

- Support for GET requests; new function `wt_get_locations()` to get
  Organization locations
- Removed `stringr` as dependency

### Minor changes

- Generate R user agent functionally
- Tweaks to LDFCs, including addition of borders for each recording
- Deal with dependency changes for camera functions
  ([\#61](https://github.com/ABbiodiversity/wildrtrax/issues/61),
  [\#63](https://github.com/ABbiodiversity/wildrtrax/issues/63))
- Added README work flows; vignette enhancements

## wildrtrax 1.3.1

### Major changes

- Upgraded authorization and API requests to `httr2`
- Removed `lubridate`, `curl` and `intrval` as dependencies

### Minor changes

- Address camera functionalities from
  [\#60](https://github.com/ABbiodiversity/wildrtrax/issues/60),
  [\#62](https://github.com/ABbiodiversity/wildrtrax/issues/62)
- Add GRTS grid cells for Alaska and contiguous United States for
  [`wt_add_grts()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_add_grts.md)
  ([\#64](https://github.com/ABbiodiversity/wildrtrax/issues/64))
- Use
  [`.wt_col_types()`](https://abbiodiversity.github.io/wildrtrax/reference/dot-wt_col_types.md)
  to dynamically adjust column reports to help address
  ([\#55](https://github.com/ABbiodiversity/wildrtrax/issues/55))
- Moved `wt_calculate_prf()` to internal function

## wildrtrax 1.3.0

### Major changes

- Addition of five new functions:
  - [`wt_dd_summary()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_dd_summary.md)
    for querying data from Data Discover. See
    [APIs](https://abbiodiversity.github.io/wildrtrax/articles/apis.html#data-discover)
    for more information
  - [`wt_evaluate_classifier()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_evaluate_classifier.md),
    `wt_get_threshold()`, and
    [`wt_additional_species()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_additional_species.md)
    for wrangling acoustic automated classification results. See
    [Acoustic
    classifiers](https://abbiodiversity.github.io/wildrtrax/articles/classifiers-tutorial.html)
    for more information.
  - [`wt_add_grts()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_add_grts.md)
    to intersect locations with GRTS IDs from
    [NABat](https://www.nabatmonitoring.org/)
- `wt_download_tags()` now becomes
  [`wt_download_media()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_media.md)
  to support broader media downloads in batch from WildTrax
- Deprecated `wt_report()`

### Minor changes

- Switch to
  [`curl::curl_download()`](https://jeroen.r-universe.dev/curl/reference/curl_download.html)
  for media and assets
- Removed dependencies `pipeR`, `progressr`, `jsonlite`, `future`,
  `furrr`, `tools`, `magrittr`, `markdown`, `rmarkdown` to increase
  package stability but reduces speed for functions such as
  [`wt_audio_scanner()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_audio_scanner.md),
  [`wt_run_ap()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_run_ap.md).
  Moved `vembedr` to suggests for vignettes
- Switched
  [`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)
  to POST requests
- Lowercase package name

------------------------------------------------------------------------

## wildrtrax 1.2.0

### Major changes

- [`wt_chop()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_chop.md)
  now recurses across all input files
- Moving geospatial assets to new repository to lighten package size.
  Asset requests are now made only through usage of
  [`wt_qpad_offsets()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_qpad_offsets.md).

### Minor changes

- Improvements to APIs and acoustic convenience functions to resolve
  issues and PRs
- Improvements to test suite, testing dependencies, code coverage
- Addition of [Camera data wrangling
  vignette](https://abbiodiversity.github.io/wildrtrax/articles/camera-data-wrangling.html)
  and additional
  [tutorials](https://abbiodiversity.github.io/wildrtrax/articles/tutorials.html)

------------------------------------------------------------------------

## wildrtrax 1.1.0

### Major changes

- `wildrtrax` now honours new WildTrax report structures. Future changes
  will incorporate standardized naming in syncing functions.
- Replaced geospatial functionalities from `rgdal`, `rgeos` and
  `maptools` with `sf`, `sp` and `terra` packages. Added functionality
  with the `suntools` package. Users should re-download the package by
  October 2023 in-line with the former package retirement:
  <https://geocompx.org/post/2023/rgdal-retirement/>.

### Minor changes

- Tweaks to [Acoustic data
  wrangling](https://abbiodiversity.github.io/wildrtrax/articles/acoustic-data-wrangling.html)
  for (#16)
- Addition of geospatial assets. Users should be warned package size is
  now ~40 MB.
- Moved TMTT predictions from csv to .RDS file.
- Work flow repairs to
  [`wt_get_species()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_get_species.md)
  and
  [`wt_tidy_species()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_tidy_species.md)
  (#21)
- Replaced
  [`utils::read.csv()`](https://rdrr.io/r/utils/read.table.html) to
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html)
  in
  [`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)
  (#20)

------------------------------------------------------------------------

## wildrtrax 1.0.1

- Patching API errors in
  [`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)
- Adding additional articles on [Acoustic data
  wrangling](https://abbiodiversity.github.io/wildrtrax/articles/acoustic-data-wrangling.html)

------------------------------------------------------------------------

## wildrtrax 1.0.0

### Major changes

- Improvements to
  [`wt_audio_scanner()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_audio_scanner.md)
  - Addition of *flac* as file type
  - Addition of `extra_cols` argument to enable faster scanning when
    argument is set to `FALSE`. This also deals with headerless file
    errors for (#2)
  - Enabled parallel file scanning; microbenchmarked base scanning at
    5.6x faster on a dual-core machine
  - Moved progress bars to the `progressr` package
- Addition of
  [`wt_glean_ap()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_glean_ap.md)
  function to acoustic pre-processing work flow to extract desired data
  from a
  [`wt_run_ap()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_run_ap.md)
  output
- Addition of linking functions in order to add desired media and
  metadata to WildTrax:
  [`wt_make_aru_tasks()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_make_aru_tasks.md),
  [`wt_kaleidoscope_tags()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_kaleidoscope_tags.md)
  and
  [`wt_songscope_tags()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_songscope_tags.md)
- Addition of convenience functions:
  [`wt_location_distances()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_location_distances.md)
  and
  [`wt_chop()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_chop.md)
- Alignment of
  [`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)
  with column headers released in [WildTrax Phase
  8](https://wildtrax.ca/phase-8-spring-2023/) to resolve (#3, \#4, \#5)
- Addition of additional acoustic functions to prepare data for
  analysis:
  [`wt_replace_tmtt()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_replace_tmtt.md),
  [`wt_make_wide()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_make_wide.md),
  [`wt_format_occupancy()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_format_occupancy.md),
  [`wt_qpad_offsets()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_qpad_offsets.md)
- Addition of
  [`wt_get_species()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_get_species.md)
  to download the WildTrax species table and
  [`wt_tidy_species()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_tidy_species.md)
  to filter various taxa
- Addition of `wt_download_tags()` to download images, spectrograms and
  audio clips from tags
- Experimental testing of customizable, automated reports with
  `wt_report()`
- Long-form documentation available for full-cycle environmental work
  flows and new articles for usage of acoustic and camera data analysis
  functions

### Minor improvements and bug fixes

- Moved
  [`wt_run_ap()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_run_ap.md)
  to `furrr::future_map` from `dopar` loop to lessen package
  dependencies
- Quiet console output from
  [`wt_run_ap()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_run_ap.md)
  for Windows users
- Added a `NEWS.md` file to track changes to the package
- Renamed `wt_ind_det` to
  [`wt_ind_detect()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_ind_detect.md)

### Deprecated

- `wt_prob_det()`

------------------------------------------------------------------------

## wildrtrax 0.1.0

- Addition of base functions:
  - **Acoustic**
    - [`wt_audio_scanner()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_audio_scanner.md),
      [`wt_run_ap()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_run_ap.md),
      [`wt_signal_level()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_signal_level.md),
      `wt_prob_det()`
  - **Camera**
    - `wt_ind_det`,
      [`wt_summarise_cam()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_summarise_cam.md)
  - **Authorization and Download from WildTrax**
    - [`wt_auth()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_auth.md),
      `wt_get_download_summary()`,
      [`wt_download_report()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_download_report.md)
