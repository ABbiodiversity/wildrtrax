library(testthat)
library(purrr)
library(dplyr)
library(tidyr)

# test_that("errors when WT_USERNAME or WT_PASSWORD are missing", {
#   withr::with_envvar(
#     c(WT_USERNAME = "", WT_PASSWORD = ""),
#     expect_error(
#       .wt_auth(),
#       "Environment variables are not set"
#     )
#   )
# })

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

test_that("Get functions for all API combinations with specific project restrictions", {
  # Set environment variables and authenticate
  Sys.setenv(WT_USERNAME = "guest", WT_PASSWORD = "Apple123")
  wt_auth(force = TRUE)

  # Test for each API using pseudonyms
  expect_no_error(wt_get_sync(api = "organization_locations", organization = 5205))
  expect_no_error(wt_get_sync(api = "organization_visits", organization = 5205))
  expect_no_error(wt_get_sync(api = "organization_equipment", organization = 5205))
  expect_no_error(wt_get_sync(api = "organization_deployments", organization = 5205))
  expect_no_error(wt_get_sync(api = "organization_recordings", organization = 5205))
  expect_no_error(wt_get_sync(api = "project_locations", project = 620))
  expect_no_error(wt_get_sync(api = "project_aru_tasks", project = 620))
  expect_no_error(wt_get_sync(api = "project_aru_tags", project = 620))
  expect_no_error(wt_get_sync(api = "project_image_metadata", project = 251))
  expect_no_error(wt_get_sync(api = "project_camera_tags", project = 251))
  expect_no_error(wt_get_sync(api = "project_point_counts", project = 804))
})


test_that("Get functions for all API combinations with specific project restrictions", {
  # Set environment variables and authenticate
  Sys.setenv(WT_USERNAME = "guest", WT_PASSWORD = "Apple123")
  wt_auth(force = TRUE)

  # Test for each API using pseudonyms
  expect_no_error(wt_get_view(api = "organization_locations", organization = 5205))
  expect_no_error(wt_get_view(api = "organization_visits", organization = 5205))
  expect_no_error(wt_get_view(api = "organization_equipment", organization = 5205)) # TEXT PLAIN
  expect_no_error(wt_get_view(api = "organization_deployments", organization = 5205))
  expect_no_error(wt_get_view(api = "organization_recordings", organization = 5205))
  expect_no_error(wt_get_view(api = "organization_image_sets", organization = 5205))
  expect_no_error(wt_get_view(api = "organization_usage_report", organization = 5205))
  expect_no_error(wt_get_view(api = "project_aru_tasks", project = 620))
  expect_no_error(wt_get_view(api = "project_camera_tasks", project = 251))
  expect_no_error(wt_get_view(api = "project_point_counts", project = 804))
})

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


#######

test_that("Complex column check across reports and sync", {

report_endpoints <- list(
  list(project = 620, type = "ARU", reports = c("main","ai","recording","tag","project","location")),
  list(project = 881, type = "PC", reports = c("main", "project", "location", "point_count")),
  list(project = 251, type = "CAM", reports = c("main","location", "project", "tag", "megadetector","image_set_report","image_report"))
)

report_cols <- report_endpoints %>%
  map_df(~ {
    df <- wt_download_report(.x$project, .x$type, .x$reports)
    # Flatten if list of dataframes, preserving which report each col came from
    if (is.list(df)) {
      map_df(names(df), function(report) {
        tibble(report_name = names(df[[report]]), source_report = report)
      })
    } else {
      tibble(report_name = names(df), source_report = .x$reports)
    }
  }) %>%
  distinct() %>%
  mutate(in_report = TRUE)

sync_endpoints <- list(
  list(api="organization_locations", org=5205),
  list(api="organization_visits", org=5205),
  list(api="organization_equipment", org=5205),
  list(api="organization_deployments", org=5205),
  list(api="organization_recordings", org=5205),
  list(api="project_locations", project=620),
  list(api="project_aru_tasks", project=620),
  list(api="project_aru_tags", project=620),
  list(api="project_image_metadata", project=251),
  list(api="project_camera_tags", project=251),
  list(api="project_point_counts", project=804)
)

sync_cols <- sync_endpoints %>%
  map_df(~ {
    args <- if (!is.null(.x$org)) list(api=.x$api, organization=.x$org) else list(api=.x$api, project=.x$project)
    tibble(sync_name = names(do.call(wt_get_sync, args)), source_api = .x$api)
  }) %>%
  distinct() |>
  mutate(in_sync = TRUE)

all_columns <- full_join(report_cols |> rename(column_name = report_name), sync_cols |> rename(column_name = sync_name), by = "column_name") |>
  mutate(report_or_sync = coalesce(in_report, in_sync),
         report_name = ifelse(!is.na(in_report), column_name, NA_character_),
         sync_name = ifelse(!is.na(in_sync), column_name, NA_character_)) |>
  select(column_name, report_or_sync, report_name, sync_name)

expect_no_error(all_columns) #EXPECT WE ACTUALLY EXPECT AN ERROR - KEEP WORKING ON THIS

})

