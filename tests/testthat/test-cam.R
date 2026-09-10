library(testthat)

Sys.setenv(WT_USERNAME = "guest", WT_PASSWORD = "Apple123")
wt_auth(force = TRUE)
test_data_set <- wt_download_report(project_id = 798, sensor_id = 'CAM', reports = 'main')
ind_detections <- wt_ind_detect(test_data_set, threshold = 60, units = "minutes", datetime_col = image_date_time, remove_human = TRUE, remove_domestic = TRUE)
md_test <- wt_download_report(project_id = 798, sensor_id = 'CAM', reports = 'megadetector')

eff_data <- tibble(
  project_id = c(798),
  location = c("OG-ABMI-468-53-1"),
  start_date = as.Date(c("2018-02-25")),
  end_date = as.Date(c("2018-08-01 13:15:37"))
)

################################### Camera Test suite

test_that("Downloading CAM report", {
  test_data_set
  expect_true(!is.null(test_data_set))
})


test_that("Individual detections", {
  ind_detections <- wt_ind_detect(test_data_set, threshold = 60, units = "minutes", datetime_col = image_date_time, remove_human = TRUE, remove_domestic = TRUE)
  expect_true(nrow(test_data_set) > nrow(ind_detections))

})

test_that("Individual detections", {
  summary <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "day", variable = "detections", output_format = "wide")
  expect_true(ncol(summary) > ncol(ind_detections))
})

# Test equality of summarized camera data
test_that("Summarise cam", {
  test_data_set
  summary <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "month", variable = "detections", output_format = "wide")
  expect_true(!is.null(test_data_set))
})

test_that("error when both raw_data and effort_data are provided", {
  test_data_set
  expect_error(wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, effort_data = test_data_set), "Please only supply a value for one of `raw_data` or `effort_data`.")
})

test_that("output format 'wide' works correctly", {
  result <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "day", output_format = "wide")
  expect_true("OG-ABMI-406-51-1" %in% result$location)
  expect_true("Gray Wolf" %in% colnames(result))
})

test_that("Megadetector stuff", {
  expect_true(nrow(md_test) > 1)
})

test_that("out of range", {
  exclude_oor <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "day", output_format = "wide", exclude_out_of_range = TRUE)
  no_exclusion <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "day", output_format = "wide", exclude_out_of_range = FALSE)
  expect_true(nrow(exclude_oor) < nrow(no_exclusion))
  no_oor <- test_data_set |> filter(!(image_fov == "OOR"))
  no_exc <- test_data_set
  expect_true(nrow(no_oor) < nrow(no_exc))
})

test_that("weekly summaries", {
result_week <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "week", output_format = "long")
expect_true(max(result_week$n_days_effort) == 7)
})

test_that("full summaries", {
  expect_no_error(result_full <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "full", output_format = "long"))
})

test_that("effort data supplied", {
  expect_no_error(result_data_effort <- wt_summarise_cam(detect_data = ind_detections, time_interval = "day", output_format = "long", effort_data = eff_data))
})

test_that("error ind detect", {
  expect_error(wt_ind_detect(test_data_set, threshold = 60, units = "blah", datetime_col = image_date_time, remove_human = TRUE, remove_domestic = TRUE))
})

test_that("error ind detect2", {
  expect_error(wt_ind_detect(threshold = 60, units = "minutes", datetime_col = image_date_time, remove_human = TRUE, remove_domestic = TRUE))
})

test_that("test 94", {

  dates <- as.POSIXct(
    c(
      "2025-12-28 12:00:00", # ISO 2025 week 52
      "2025-12-29 12:00:00", # ISO 2026 week 1
      "2025-12-31 12:00:00", # ISO 2026 week 1
      "2026-01-01 12:00:00", # ISO 2026 week 1
      "2026-01-04 12:00:00", # ISO 2026 week 1
      "2026-01-05 12:00:00"  # ISO 2026 week 2
    ),
    tz = "UTC"
  )

  result <- tibble::tibble(day = dates) |>
    dplyr::mutate(
      year = as.integer(strftime(day, "%G")),
      week = as.integer(strftime(day, "%V"))
    )

  # Dec 29, 2025 through Jan 4, 2026 are ISO week 1 of 2026
  expect_equal(
    result |>
      dplyr::filter(day >= as.POSIXct("2025-12-29", tz = "UTC"),
                    day <= as.POSIXct("2026-01-04 23:59:59", tz = "UTC")) |>
      dplyr::distinct(year, week),
    tibble::tibble(year = 2026L, week = 1L)
  )

  # Dec 28 is still ISO week 52 of 2025
  expect_equal(
    result$year[result$day == as.POSIXct("2025-12-28 12:00:00", tz = "UTC")],
    2025L
  )

  expect_equal(
    result$week[result$day == as.POSIXct("2025-12-28 12:00:00", tz = "UTC")],
    52L
  )

  # Jan 5 starts ISO week 2 of 2026
  expect_equal(
    result$year[result$day == as.POSIXct("2026-01-05 12:00:00", tz = "UTC")],
    2026L
  )

  expect_equal(
    result$week[result$day == as.POSIXct("2026-01-05 12:00:00", tz = "UTC")],
    2L
  )
})

test_that("test 82 - NA and non-species labels are excluded from detection summaries", {

  test_data <- tibble::tribble(
    ~project_id, ~location, ~image_id, ~image_date_time, ~species_common_name, ~individual_count,
    2626, "A", 1, as.POSIXct("2026-01-01 10:00:00"), NA_character_,       1,
    2626, "A", 2, as.POSIXct("2026-01-01 10:01:00"), "NONE",              1,
    2626, "A", 3, as.POSIXct("2026-01-01 10:02:00"), "STAFF/SETUP",       1,
    2626, "A", 4, as.POSIXct("2026-01-01 10:03:00"), "UNKNOWN",            1,
    2626, "A", 5, as.POSIXct("2026-01-01 10:04:00"), "White-tailed Deer",  1
  )

  result <- wt_ind_detect(
    test_data,
    threshold = 60,
    units = "minutes",
    datetime_col = image_date_time,
    remove_human = TRUE,
    remove_domestic = TRUE
  )

  expect_false(any(is.na(result$species_common_name)))

  expect_false(any(
    result$species_common_name %in%
      c("NONE", "STAFF/SETUP", "UNKNOWN")
  ))

  expect_true(
    "White-tailed Deer" %in% result$species_common_name
  )
})
