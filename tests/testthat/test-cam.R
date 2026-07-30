library(testthat)

Sys.setenv(WT_USERNAME = "guest", WT_PASSWORD = "Apple123")
wt_auth(force = TRUE)
test_data_set <- wt_download_report(project_id = 625, sensor_id = 'CAM', reports = 'main')
ind_detections <- wt_ind_detect(test_data_set, threshold = 60, units = "minutes", datetime_col = image_date_time, remove_human = TRUE, remove_domestic = TRUE)
md_test <- wt_download_report(project_id = 625, sensor_id = 'CAM', reports = 'megadetector')

eff_data <- tibble(
  project_col = c(625),
  station_col = c("1081-NE"),
  start_col = as.Date(c("2021-03-16")),
  end_col = as.Date(c("2021-07-20"))
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
  expect_true("1081-NE" %in% result$location)
  expect_true("Beaver" %in% colnames(result))
})

test_that("Megadetector stuff", {
  expect_true(nrow(md_test) > 1)
})

test_that("valid time intervals are handled", {

  result_day <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "day", output_format = "long")
  result_week <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "week", output_format = "long")
  result_month <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "month", output_format = "long")
  result_full <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "full", output_format = "long")
  result_day_w <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "day", output_format = "wide")
  result_week_w <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "week", output_format = "wide")
  result_month_w <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "month", output_format = "wide")
  result_full_w <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, time_interval = "full", output_format = "wide")

  expect_equal(nrow(result_day), 657968)  # Adjust this based on the actual expected number of rows for each case
  expect_equal(nrow(result_week), 98646)
  expect_equal(nrow(result_month), 25584)
  expect_true(nrow(result_day_w) == 16048)
  expect_true(nrow(result_week_w) == 2406)
  expect_true(nrow(result_month_w) == 624)

})

test_that("all specified variables are included in the summarised output", {
  result <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, variable = "all", time_interval = "day", output_format = "long")
  expect_true(!is.null(result))
})


# Set for issue 81 testing out of range images
#test_that("exclude_out_of_range removes data outside of the camera's field of view", {
  #expect_error(wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, exclude_out_of_range = TRUE, time_interval = "day", output_format = "long", variable = "counts"))
  #result_out <- wt_summarise_cam(detect_data = ind_detections, raw_data = test_data_set, exclude_out_of_range = FALSE, time_interval = "day", output_format = "long", variable = "counts")
  #expect_true(nrow(result_out) > nrow(result))
#})



