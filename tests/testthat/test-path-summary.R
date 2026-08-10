test_that("wt_path_summary prints hierarchy for consistent paths", {

  paths <- c(
    file.path("sample", "site1", "image1.jpg"),
    file.path("sample", "site1", "image2.jpg"),
    file.path("sample", "site2", "image3.jpg")
  )

  expect_output(
    wt_path_summary(paths),
    "All files occur at the same depth"
  )

  expect_output(
    wt_path_summary(paths),
    "Folder hierarchy"
  )

  expect_output(
    wt_path_summary(paths),
    "Level 1"
  )

})


test_that("wt_path_summary warns for inconsistent folder depths", {

  paths <- c(
    file.path("sample", "site1", "image1.jpg"),
    file.path("sample", "site2", "camera1", "image2.jpg")
  )

  expect_warning(
    wt_path_summary(paths),
    "Not all files have the same folder depth"
  )

})


test_that("wt_path_summary handles empty and missing paths", {

  expect_error(
    wt_path_summary(character(0)),
    "`paths` contains no file paths"
  )

  expect_error(
    wt_path_summary(NA_character_),
    "`paths` cannot contain missing values"
  )

  expect_error(
    wt_path_summary(1:5),
    "`paths` must be a character vector"
  )

})


test_that("wt_path_summary checks path_split", {

  paths <- c(
    "sample/site1/image1.jpg",
    "sample/site2/image2.jpg"
  )

  expect_output(
    wt_path_summary(
      paths,
      path_split = "/"
    ),
    "Folder hierarchy"
  )

  expect_error(
    wt_path_summary(
      paths,
      path_split = c("/", "\\")
    ),
    "`path_split` must be NULL or a single character string"
  )

  expect_error(
    wt_path_summary(
      paths,
      path_split = 1
    ),
    "`path_split` must be NULL or a single character string"
  )

})
