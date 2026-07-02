test_that("wt_image_paths finds image files recursively", {

  tmp <- tempfile()
  dir.create(tmp)

  dir.create(file.path(tmp, "site1"))
  dir.create(file.path(tmp, "site2"))

  file.create(file.path(tmp, "site1", "image1.jpg"))
  file.create(file.path(tmp, "site1", "image2.JPG"))
  file.create(file.path(tmp, "site2", "image3.jpeg"))
  file.create(file.path(tmp, "site2", "notes.txt"))

  out <- wt_image_paths(tmp)

  expect_length(out, 3)
  expect_true(all(file.exists(out)))
  expect_true(all(
    grepl(
      "\\.(jpg|jpeg)$",
      out,
      ignore.case = TRUE
    )
  ))

})


test_that("wt_image_paths handles case sensitivity", {

  tmp <- tempfile()
  dir.create(tmp)

  file.create(file.path(tmp, "image1.jpg"))
  file.create(file.path(tmp, "image2.JPG"))

  out_case <- wt_image_paths(
    tmp,
    ignore.case = FALSE
  )

  out_ignore <- wt_image_paths(
    tmp,
    ignore.case = TRUE
  )

  expect_length(out_case, 1)
  expect_length(out_ignore, 2)

})


test_that("wt_image_paths checks arguments", {

  tmp <- tempfile()
  dir.create(tmp)

  expect_error(
    wt_image_paths(1),
    "`path` must be a single character string"
  )

  expect_error(
    wt_image_paths("not_a_directory"),
    "`path` does not exist"
  )

  expect_error(
    wt_image_paths(
      tmp,
      pattern = 1
    ),
    "`pattern` must be a single character string"
  )

  expect_error(
    wt_image_paths(
      tmp,
      ignore.case = 1
    ),
    "`ignore.case` must be TRUE or FALSE"
  )

})
