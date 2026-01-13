library(testthat)

Sys.setenv(WT_USERNAME = "guest", WT_PASSWORD = "Apple123")
wt_auth(force = TRUE)
cypress_hills <- wt_download_report(620, 'ARU', 'main')
pc_proj <- wt_download_report(881, 'PC', 'main')
fake <- ""

# test_that('Audio scanner', {
#   expect_no_error(wt_audio_scanner(".", file_type = "wav", extra_cols = T))
# })
#
# test_that('Audio scanner', {
#   expect_no_error(wt_audio_scanner(".", file_type = "all", extra_cols = T))
# })
#
# test_that('Audio scanner', {
#   file <- wt_audio_scanner(".", file_type = "wav", extra_cols = T)
#   expect_no_error(wt_make_aru_tasks(file, output = NULL, task_method = "1SPT", task_length = 60))
# })
#
# test_that('Guano tags', {
#   file <- wt_audio_scanner(".", file_type = "wav", extra_cols = T) |>
#     filter(location == "S4U08993") |>
#     select(file_path) |>
#     pull()
#   expect_no_error(wt_guano_tags(path = file))
# })
#
# test_that("Authentication works correctly", {
#   expect_true(!is.null(wt_get_projects(sensor = 'ARU')))
#   })

test_that("Downloading ARU report", {
  expect_true(!is.null(cypress_hills))
})

test_that("Testing a Private Project", {
  expect_error(wt_download_report(1373, 'ARU', 'main')==0)
})

test_that("Downloading ARU as PC report", {
  cypress_hills_as_pc <- wt_download_report(620, 'PC', 'main')
  expect_true(!is.null(cypress_hills_as_pc))
})

test_that("Attempting PC as ARU report", {
  expect_true(nrow(wt_download_report(887, 'ARU', 'main'))==0)
})

test_that("Tidying species zero-filling true", {
  cypress_hills_tidy <- wt_tidy_species(cypress_hills, remove = c("abiotic"), zerofill = T)
  expect_true(nrow(cypress_hills_tidy) < nrow(cypress_hills))
})

test_that("Tidying species zero-filling false", {
  cypress_hills_tidy_f <- wt_tidy_species(cypress_hills, remove = c("mammal", "abiotic", "amphibian","unknown"), zerofill = F)
  expect_true(nrow(cypress_hills_tidy_f) < nrow(cypress_hills))
})

library(testthat)
library(wildrtrax)
test_that("Replacing TMTT", {
  Sys.setenv(WT_USERNAME = "guest", WT_PASSWORD = "Apple123")
  wt_auth(force = TRUE)
  cypress_hills <- wt_download_report(620, 'ARU', 'main')
  cypress_hills_tidy <- wt_tidy_species(cypress_hills, remove = c("mammal", "abiotic", "amphibian", "unknown"), zerofill = T)
  cypress_hills_tmtt <- wt_replace_tmtt(cypress_hills_tidy, calc = "round") |>
    select(individual_count) |>
    distinct()
  expect_true(!('TMTT' %in% cypress_hills_tmtt))
})

test_that('Making wide', {
  cypress_hills_tidy <- wt_tidy_species(cypress_hills, remove = c("mammal", "abiotic", "amphibian", "unknown"), zerofill = T)
  cypress_hills_tmtt <- wt_replace_tmtt(cypress_hills_tidy, calc = "round")
  cypress_hills_wide <- wt_make_wide(cypress_hills_tmtt, sound="all")
  expect_true(ncol(cypress_hills_wide) > ncol(cypress_hills_tmtt))
})

test_that('Occupancy formatting', {
  cypress_hills_tidy <- wt_tidy_species(cypress_hills, remove = c("mammal", "abiotic", "amphibian"), zerofill = T)
  cypress_hills_tmtt <- wt_replace_tmtt(cypress_hills_tidy, calc = "round")
  occu <- wt_format_occupancy(cypress_hills_tmtt, species = "OVEN")
  expect_true(class(occu)[1] == 'unmarkedFrameOccu')
})

rep <- wt_download_report(620, 'ARU', c('main','ai'))
rep2 <- wt_download_report(84, 'ARU', c('main','ai'))

test_that('Expect error wrong data', {
  expect_error(wt_evaluate_classifier(fake, resolution = "task"))
})

test_that('Expect error wrong data', {
  expect_no_error(wt_evaluate_classifier(rep, resolution = "task", remove_species = F))
})

test_that('Classifier functions by resolution recording', {
  eval <- wt_evaluate_classifier(rep, resolution = "task", remove_species = TRUE, thresholds = c(0.01,0.99))
  e1 <- wt_classifier_threshold(eval)
  add_sp <- wt_additional_species(rep, remove_species = TRUE, threshold = min(e1$threshold), resolution = "recording")
  expect_true(!is.null(add_sp))
})

test_that('Classifier functions by minute', {
  expect_error(wt_evaluate_classifier(rep, "minute", remove_species = TRUE, thresholds = c(0.01,0.99)))
})

test_that('Classifier functions by resolution location', {
  eval <- wt_evaluate_classifier(rep, resolution = "task", remove_species = TRUE, thresholds = c(0.01,0.99))
  e1 <- wt_classifier_threshold(eval)
  add_sp <- wt_additional_species(rep, remove_species = TRUE, threshold = min(e1$threshold), resolution = "location")
  expect_true(!is.null(add_sp))
})

test_that('Classifier functions by resolution project', {
  eval <- wt_evaluate_classifier(rep, resolution = "task", remove_species = TRUE, thresholds = c(0.01,0.99))
  e1 <- wt_classifier_threshold(eval)
  add_sp <- wt_additional_species(rep, remove_species = TRUE, threshold = min(e1$threshold), resolution = "project")
  expect_true(!is.null(add_sp))
})

test_that('Classifier functions export tags', {
  eval <- wt_evaluate_classifier(rep, resolution = "task", remove_species = TRUE, thresholds = c(0.01,0.99))
  e1 <- wt_classifier_threshold(eval)
  expect_error(wt_additional_species(rep, remove_species = TRUE, threshold = min(e1$threshold), resolution = "location", format_to_tags = T))
})

test_that('Classifier functions by minute with a 1SPM project', {
  expect_no_error(wt_evaluate_classifier(rep2, "minute", remove_species = TRUE, thresholds = c(0.01,0.99)))
})

test_that('Classifier functions by resolution project', {
  expect_no_error(wt_evaluate_classifier(rep, resolution = "recording", remove_species = TRUE, thresholds = c(0.01,0.99)))
})

test_that('Classifier functions by task', {
  eval <- wt_evaluate_classifier(rep, "task", remove_species = TRUE, thresholds = c(0.01,0.99))
  e1 <- wt_classifier_threshold(eval)
  add_sp <- wt_additional_species(rep, remove_species = TRUE, threshold = min(e1$threshold), resolution = "task")
  expect_true(!is.null(add_sp))
})

test_that('Classifier functions by recording', {
  eval <- wt_evaluate_classifier(rep, "recording", remove_species = TRUE, thresholds = c(0.01,0.99))
  e1 <- wt_classifier_threshold(eval)
  add_sp <- wt_additional_species(rep, remove_species = TRUE, threshold = min(e1$threshold), resolution = "task")
  expect_true(!is.null(add_sp))
})

test_that("Songscope tags USPM", {
  expect_no_error(
    wt_songscope_tags(
      testthat::test_path("CONI.txt"),
      output = "env",
      species = "CONI",
      vocalization = "SONG",
      score_filter = 10,
      method = "USPM",
      duration = 180,
      sample_freq = 44100
    )
  )
})

test_that("Songscope tags 1SPT", {
  expect_no_error(
    wt_songscope_tags(
      testthat::test_path("CONI.txt"),
      output = "env",
      species = "CONI",
      vocalization = "SONG",
      score_filter = 10,
      method = "1SPT",
      duration = 180,
      sample_freq = 44100
    )
  )
})

test_that("Kaleidoscope tags", {
  expect_no_error(
    wt_kaleidoscope_tags(
      testthat::test_path("id.csv"),
      output = NULL,
      freq_bump = T
    )
  )
})

test_that("Kaleidoscope tags", {
  expect_no_error(
    wt_kaleidoscope_tags(
      testthat::test_path("id.csv"),
      output = NULL,
      freq_bump = F
    )
  )
})

test_that("Wide with PC", {
  expect_no_error(wt_make_wide(pc_proj))
})


### test 46

ecosys21 <- wt_download_report(685, 'ARU', 'main')

# add a location with 0 birds observed
ecosys21_mod_row <- slice(ecosys21, 1)
ecosys21_mod_row$species_code <- "MOBA"
ecosys21_mod_row$species_scientific_name <- NA
ecosys21_mod_row$vocalization <- "Non-vocal"
ecosys21_mod_row$location_id <- ecosys21_mod_row$location_id+max(ecosys21$location_id)
ecosys21_mod <- bind_rows(ecosys21, ecosys21_mod_row)

# all locations from input should be present in outputs unless not transcribed
ecosys21_locs <- ecosys21_mod |> filter(task_is_complete == TRUE) |>
  distinct(location_id)

ecosys21_tidy <- wt_tidy_species(ecosys21_mod, remove = c("mammal", "abiotic", "amphibian"), zerofill = T)
#> Successfully downloaded the species table!
ecosys21_locs |> anti_join(ecosys21_tidy, by = "location_id") |>
  pull(location_id) |>
  expect_length(0)

ecosys21_tmtt <- wt_replace_tmtt(ecosys21_tidy, calc = "round")
ecosys21_locs |> anti_join(ecosys21_tmtt, by = "location_id") |>
  pull(location_id) |>
  expect_length(0)
#> Error: `.` has length 1, not length 0.

ecosys21_wide <- wt_make_wide(ecosys21_tmtt, sound = "all")
ecosys21_locs |> anti_join(ecosys21_wide, by = "location_id") |>
  pull(location_id) |>
  expect_length(0)
#> Error: `.` has length 1, not length 0.

# total abundance should be 0
filter(ecosys21_wide, location_id == ecosys21_mod_row$location_id) |>
  rowwise() |>
  mutate(tot_birds = sum(c_across(matches("^....$") & !matches("^NONE$")), na.rm = TRUE)) |>
  pull(tot_birds) |>
  expect_equal(0)

test_that('Getting QPAD offsets', {
  library(QPAD)
  cypress_hills <- wt_download_report(620, 'ARU', 'main')
  cypress_hills_tidy <- wt_tidy_species(cypress_hills, remove = c("mammal", "abiotic", "amphibian", "unknown"), zerofill = T)
  cypress_hills_tmtt <- wt_replace_tmtt(cypress_hills_tidy, calc = "round")
  cypress_hills_wide <- wt_make_wide(cypress_hills_tmtt, sound = "all")
  cypress_hills_qpad <- wt_qpad_offsets(cypress_hills_wide, species = "all", version = 3, together = F)
  expect_true(ncol(cypress_hills_qpad) > 1)
})
