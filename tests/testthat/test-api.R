library(testthat)
library(purrr)
library(dplyr)
library(tidyr)

aoi <- list(
  c(-112.85438, 57.13472),
  c(-113.14364, 54.74858),
  c(-112.69368, 52.34150),
  c(-112.85438, 57.13472),
  c(-112.85438, 57.13472)
)

bad_aoi <- list(
  c(-112.85438, 53.13472),
  c(-113.14364, 54.74858),
  c(-112.69368, 52.34150),
  c(-112.854385, 57.13472),
  c(-112.85438, 57.13472)
)

test_that("Download without authentication or boundary; single-species", {
  expect_true(!is.null(wt_dd_summary(sensor = 'ARU', species = 'White-throated Sparrow', boundary = NULL)))
})

test_that("Download without authentication with boundary; single-species", {
  expect_true(!is.null(wt_dd_summary(sensor = 'ARU', species = 'White-throated Sparrow', boundary = aoi)))
})

test_that("Download without authentication, bad boundary; single-species", {
  expect_error(!is.null(wt_dd_summary(sensor = 'ARU', species = 'White-throated Sparrow', boundary = bad_aoi)))
})

test_that("Download without authentication, boundary; multiple single-species", {
  expect_true(!is.null(wt_dd_summary(sensor = 'ARU', species = c('White-throated Sparrow','Hermit Thrush'), boundary = aoi)))
})

test_that("Try to do something without authorization", {
  expect_error(wt_download_report(620, 'ARU', 'main'))
})

Sys.setenv(WT_USERNAME = "guest", WT_PASSWORD = "Apple123")
wt_auth(force = TRUE)

test_that("Try to get projects without a sensor id", {
  expect_error(wt_get_projects())
})

test_that("Multiple projects", {
  expect_no_error(wt_get_projects('ARU') |>
  filter(grepl('Public', project_status)) |>
  slice(1:2) |>
  pull(project_id) |>
  wt_download_report('ARU', 'main'))
})

test_that("Multiple projects multiple reports", {
  expect_no_error(wt_get_projects('ARU') |>
    filter(grepl('Public', project_status)) |>
    slice(1:2) |>
    pull(project_id) |>
    wt_download_report('ARU', c('main','ai')))
})

test_that("Multiple projects multiple reports CAM", {
  expect_no_error(wt_get_projects('CAM') |>
                    filter(grepl('Public', project_status)) |>
                    slice(1:2) |>
                    pull(project_id) |>
                    wt_download_report('CAM', c('main','megadetector')))
})

test_that("Try to download something without a report specified", {
  expect_error(wt_download_report(620, 'ARU'))
})

test_that("Download with authentication with boundary; single-species", {
  expect_true(!is.null(wt_dd_summary(sensor = 'ARU', species = 'White-throated Sparrow', boundary = aoi)))
})

test_that("Download with authentication, bad boundary; single-species", {
  expect_error(wt_dd_summary(sensor = 'ARU', species = 'White-throated Sparrow', boundary = bad_aoi))
})

test_that("Download with authentication with boundary; multiple species logged in", {
  expect_true(!is.null(wt_dd_summary(sensor = 'ARU', species = c('White-throated Sparrow','Townsend\'s Warbler'), boundary = aoi)))
})

# Possible test but not necessary due to length it takes to run
# test_that("Timeout test", {
#   expect_true(!is.null(wt_download_report(197, 'CAM', 'main', F, max_seconds = 3000)))
# })

organizations <- tibble(
  name = c("org_admin", "org_read", "no_org_proj_only", "no_org_or_project"),
  id = c(5205, 5454, 5327, 5550),
  should_error = c(FALSE, FALSE, TRUE, TRUE)
)

apis_sync <- c("organization_locations", "organization_visits", "organization_equipment", "organization_deployments", "organization_recordings")
apis_view <- c("organization_locations", "organization_visits", "organization_equipment", "organization_deployments", "organization_recordings", "organization_image_sets", "organization_usage_report")

test_that("Project species", {
  expect_no_error(wt_get_project_species(620))
})

test_that("Download media", {
  tmp_dir <- withr::local_tempdir()
  report <- wt_download_report(620, "ARU", "recording") |>
    dplyr::slice(1)
  expect_no_error(
    wt_download_media(
      report,
      type = "recording",
      output = tmp_dir
    )
  )
})

test_that("Download media", {
  tmp_dir <- withr::local_tempdir()
  report <- wt_download_report(620, "ARU", "tag") |>
    dplyr::slice(1)
  expect_no_error(
    wt_download_media(
      report,
      type = "tag_clip_audio",
      output = tmp_dir
    )
  )
})

test_that("Download media", {
  tmp_dir <- withr::local_tempdir()
  report <- wt_download_report(620, "ARU", "tag") |>
    dplyr::slice(1)
  expect_no_error(
    wt_download_media(
      report,
      type = "tag_clip_spectrogram",
      output = tmp_dir
    )
  )
})

test_that("Download media", {
  tmp_dir <- withr::local_tempdir()
  report <- wt_download_report(251, "CAM", "image_report") |>
    dplyr::slice(1)
  expect_no_error(wt_download_media(report, type = "image", output = tmp_dir))
})

test_that("Download media", {
  tmp_dir <- withr::local_tempdir()
  report <- wt_download_report(620, "ARU", "recording") |>
    dplyr::slice(1)
  tmp_file <- wt_download_media(
    report,
    type = "recording",
    output = tmp_dir
  )

  expect_no_error(wt_audio_scanner(tmp_dir, file_type = "flac", extra_cols = T))
})


test_that("Column definitions for reports and syncs", {

####### Check for undefined column types across reports and syncs

  Sys.setenv(WT_USERNAME = "guest", WT_PASSWORD = "Apple123")
  wt_auth(force = TRUE)

report_endpoints <- list(
  list(project = 4867, type = "ARU", reports = c("main","ai","recording","tag","project","location")),
  list(project = 4869, type = "PC", reports = c("main", "project", "location", "point_count")),
  list(project = 4868, type = "CAM", reports = c("main","location", "project", "tag", "megadetector","image_set_report","image_report"))
)

report_cols <- report_endpoints %>%
  map_df(~ {
    df <- wt_download_report(.x$project, .x$type, .x$reports)
    if (is.list(df)) {
      map_df(names(df), function(report) {
        tibble(report_name = names(df[[report]]), source_report = report)
      })
    } else {
      tibble(report_name = names(df), source_report = .x$reports)
    }
  })

sync_endpoints <- list(
  list(api="organization_locations", org=5986),
  list(api="organization_visits", org=5986),
  list(api="organization_equipment", org=5986),
  list(api="organization_deployments", org=5986),
  list(api="organization_recordings", org=5986),
  list(api="project_locations", project=4867),
  list(api="project_aru_tasks", project=4867),
  list(api="project_aru_tags", project=4867),
  list(api="project_image_metadata", project=4868),
  list(api="project_image_tags", project=4868),
  list(api="project_image_sets", project=4868),
  list(api="project_point_counts", project=4869)
)

sync_cols <- sync_endpoints %>%
  map_df(~ {
    args <- if (!is.null(.x$org)) list(api=.x$api, organization=.x$org) else list(api=.x$api, project=.x$project)
    tibble(sync_name = names(do.call(wt_get_sync, args)), source_api = .x$api)
  })

col_names <- report_cols |>
  distinct(report_name)
sync_names <- sync_cols |>
  distinct(sync_name)

col_names_wt_col_types <- .wt_col_types() |> pluck("cols") |> names()

all_names <- c(
  col_names |> pull(report_name),
  sync_names |> pull(sync_name)
) |> unique()

missing_names <- all_names[!(all_names %in% col_names_wt_col_types)]

expect_true(length(missing_names) == 0)

})
