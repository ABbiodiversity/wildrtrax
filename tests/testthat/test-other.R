library(testthat)

Sys.setenv(WT_USERNAME = "guest", WT_PASSWORD = "Apple123")
wt_auth(force = TRUE)
bats <- wt_download_report(685, 'ARU', 'location')
locs <- wt_download_report(620, 'ARU', 'location')
cam <- wt_download_report(251, 'CAM', 'image_report')

test_that("._wt_auth_env_ exists after load", {
  expect_true(exists("._wt_auth_env_"))
  expect_true(is.environment(._wt_auth_env_))
})

test_that('Add GRTS ID', {
  grts <- wt_add_grts(bats, group_locations_in_cell = TRUE)
  expect_true(!is.null(grts))
})

test_that('Location distances', {
  locs_dist <- wt_location_distances(locs)
  expect_true(!is.null(locs_dist))
})

test_that('EXIF gets when they are wrong', {
  expect_true(nrow(cam |> slice(1) |> wt_get_exif()) == 1)
})

test_that('EXIF gets when they are wrong', {
  expect_true(nrow(cam |> slice(1) |> wt_get_exif()) == 1)
})

test_that('Get an org ID', {
  expect_no_error(.get_org_id("ABMI"))
})

test_that("Language", {
  expect_no_error(.language("en"))
  expect_no_error(.language("fr"))
})

test_that("Location distances not a tibble", {
  expect_error(wt_location_distances(input_from_tibble = list()))
})

test_that("Tidy species wrong classes", {
  Sys.setenv(WT_USERNAME = "guest", WT_PASSWORD = "Apple123")
  wt_auth(force = TRUE)
  proj <- wt_download_report(620, 'ARU', 'main')
  expect_error(wt_tidy_species(proj, remove = "nothing"))
})


