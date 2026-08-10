test_that("wt_extract_folder_level extracts folder levels correctly", {

  paths <- c(
    file.path("sample", "site1", "image1.jpg"),
    file.path("sample", "site2", "image2.jpg"),
    file.path("sample", "site3", "image3.jpg")
  )

  out <- wt_extract_folder_level(
    paths,
    level = 2
  )

  expect_equal(
    out,
    c("site1", "site2", "site3")
  )

})


test_that("wt_extract_folder_level can extract different hierarchy levels", {

  paths <- c(
    file.path("sample", "site1", "camera1", "image1.jpg"),
    file.path("sample", "site2", "camera2", "image2.jpg")
  )

  site <- wt_extract_folder_level(
    paths,
    level = 2
  )

  camera <- wt_extract_folder_level(
    paths,
    level = 3
  )

  expect_equal(
    site,
    c("site1", "site2")
  )

  expect_equal(
    camera,
    c("camera1", "camera2")
  )

})


test_that("wt_extract_folder_level handles custom path separators", {

  paths <- c(
    "sample/site1/image1.jpg",
    "sample/site2/image2.jpg"
  )

  out <- wt_extract_folder_level(
    paths,
    level = 2,
    path_split = "/"
  )

  expect_equal(
    out,
    c("site1", "site2")
  )

})


test_that("wt_extract_folder_level checks inputs", {

  paths <- c(
    file.path("sample", "site1", "image1.jpg")
  )

  expect_error(
    wt_extract_folder_level(1:5, level = 1),
    "`paths` must be a character vector"
  )

  expect_error(
    wt_extract_folder_level(NA_character_, level = 1),
    "`paths` cannot contain missing values"
  )

  expect_error(
    wt_extract_folder_level(character(0), level = 1),
    "`paths` contains no file paths"
  )

  expect_error(
    wt_extract_folder_level(paths, level = 0),
    "`level` must be a positive integer"
  )

  expect_error(
    wt_extract_folder_level(paths, level = "site"),
    "`level` must be a positive integer"
  )

})


test_that("wt_extract_folder_level errors when level does not exist", {

  paths <- c(
    file.path("sample", "site1", "image1.jpg"),
    file.path("sample", "site2", "image2.jpg")
  )

  expect_error(
    wt_extract_folder_level(
      paths,
      level = 5
    ),
    "Some paths have less sub-folders than the level specified"
  )

})
