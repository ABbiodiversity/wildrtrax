# Helper function for creating JPEG images with EXIF timestamps
make_test_images <- function(
    directory,
    dates
){

  paths <- file.path(
    directory,
    paste0(
      "image",
      seq_along(dates),
      ".jpg"
    )
  )

  img <- matrix(
    1,
    nrow = 10,
    ncol = 10
  )

  for(i in seq_along(paths)){

    jpeg::writeJPEG(
      img,
      paths[i]
    )

    exifr::exiftool_call(
      args = c(
        paste0(
          "-DateTimeOriginal=",
          shQuote(dates[i])
        ),
        "-overwrite_original",
        shQuote(paths[i])
      )
    )

  }

  paths

}


test_that("wt_image_datetime extracts EXIF datetimes exactly", {

  skip_if_not_installed("exifr")
  skip_if_not_installed("jpeg")


  tmp <- tempfile()
  dir.create(tmp)

  paths <- make_test_images(
    tmp,
    dates = c(
      "2020:01:01 12:00:00",
      "2020:01:02 12:00:00",
      "2020:01:03 12:00:00"
    )
  )

  out <- wt_image_datetime(
    paths,
    method = "exact",
    tz = "UTC"
  )

  expect_equal(
    nrow(out),
    3
  )

  expect_true(
    inherits(
      out$DateTimeOriginal,
      "POSIXct"
    )
  )

  expect_equal(
    format(
      out$DateTimeOriginal,
      "%Y-%m-%d %H:%M:%S"
    ),
    c(
      "2020-01-01 12:00:00",
      "2020-01-02 12:00:00",
      "2020-01-03 12:00:00"
    )
  )

})


test_that("wt_image_datetime fast method samples images", {

  skip_if_not_installed("exifr")
  skip_if_not_installed("jpeg")

  tmp <- tempfile()
  dir.create(tmp)

  paths <- make_test_images(
    tmp,
    dates = paste0(
      "2020:01:",
      sprintf("%02d", 1:10),
      " 12:00:00"
    )
  )

  out <- wt_image_datetime(
    paths,
    method = "fast",
    n = 2,
    tz = "UTC"
  )

  expect_equal(
    sum(!is.na(out$DateTimeOriginal)),
    4
  )

})


test_that("wt_image_datetime fast method samples within groups", {

  skip_if_not_installed("exifr")
  skip_if_not_installed("jpeg")

  tmp <- tempfile()
  dir.create(tmp)

  paths <- make_test_images(
    tmp,
    dates = paste0(
      "2020:01:",
      sprintf("%02d", 1:8),
      " 12:00:00"
    )
  )

  groups <- rep(
    c("site1", "site2"),
    each = 4
  )

  out <- wt_image_datetime(
    paths,
    method = "fast",
    group = groups,
    n = 1,
    tz = "UTC"
  )

  expect_equal(
    sum(!is.na(out$DateTimeOriginal)),
    4
  )

  expect_true(
    "group" %in% names(out)
  )

  expect_equal(
    as.character(out$group),
    groups
  )

})


test_that("wt_image_datetime returns character dates without timezone", {

  skip_if_not_installed("exifr")
  skip_if_not_installed("jpeg")

  tmp <- tempfile()
  dir.create(tmp)

  paths <- make_test_images(
    tmp,
    dates = "2020:01:01 12:00:00"
  )

  expect_warning(
    out <- wt_image_datetime(
      paths,
      method = "exact"
    ),
    "`tz` was NULL"
  )

  expect_true(
    is.character(out$DateTimeOriginal)
  )

})


test_that("wt_image_datetime checks inputs", {

  expect_error(
    wt_image_datetime(1:5),
    "`paths` must be a character vector"
  )

  expect_error(
    wt_image_datetime(character(0)),
    "`paths` contains no file paths"
  )

  expect_error(
    wt_image_datetime(NA_character_),
    "`paths` cannot contain missing values"
  )

  expect_error(
    wt_image_datetime(
      "image.jpg",
      group = c("a", "b")
    ),
    "`group` must have the same length as `paths`"
  )

  expect_error(
    wt_image_datetime(
      "image.jpg",
      group = 1
    ),
    "`group` must be either a character vector or factor"
  )

  expect_error(
    wt_image_datetime(
      "image.jpg",
      n = 1.5
    ),
    "`n` must be a single positive integer"
  )

  expect_error(
    wt_image_datetime(
      "image.jpg",
      tz = "not_a_timezone"
    ),
    "`tz` must be a timezone represented in `OlsonNames()`",
    fixed  = TRUE
  )

})



