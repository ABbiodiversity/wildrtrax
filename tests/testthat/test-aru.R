library(testthat)

Sys.setenv(WT_USERNAME = "guest", WT_PASSWORD = "Apple123")
wt_auth(force = TRUE)
cypress_hills <- wt_download_report(620, 'ARU', 'main')
pc_proj <- wt_download_report(881, 'PC', 'main')
fake <- ""
rep <- wt_download_report(620, 'ARU', c('main','ai'))
rep2 <- wt_download_report(84, 'ARU', c('main','ai'))

test_that("Authentication works correctly", {
  expect_no_error(wt_get_projects(sensor = 'ARU'))   })

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

test_that("Replacing TMTT", {
  Sys.setenv(WT_USERNAME = "guest", WT_PASSWORD = "Apple123")
  wt_auth(force = TRUE)
  cypress_hills <- wt_download_report(620, 'ARU', 'main')
  cypress_hills_tidy <- wt_tidy_species(cypress_hills, remove = c("mammal", "abiotic", "amphibian", "unknown"), zerofill = T)
  cypress_hills_tmtt <- wt_replace_tmtt(cypress_hills_tidy, calc = "round") |>
    select(abundance) |>
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
      duration = 300,
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

test_that('Format FWMIS lookups', {
  expect_no_error(wt_download_report(620, 'ARU', "main") |>
    wt_format_data(format = 'FWMIS'))
})

test_that('Guano', {
  expect_no_error(wt_audio_scanner(testthat::test_path(), file_type = "wav", extra_cols = TRUE) |>
                    filter(sample_rate > 192000) %>% purrr::map(.x = .$file_path, .f = ~wt_guano_tags(.x)))
})

test_that('WAC Tests', {
  expect_no_error(wt_audio_scanner(testthat::test_path(), file_type = "wac", extra_cols = TRUE))
})

test_that('Chop tests', {
my_files <- wt_audio_scanner(testthat::test_path(), file_type = "wav", extra_cols = TRUE) |>
  slice(1)
expect_no_error(wt_chop(input = my_files, segment_length = 60, output_folder = testthat::test_path("chop")))})

test_that('Signal level tests', {
  expect_no_error(wt_signal_level(testthat::test_path("1-1A1-CA1-B_20250620_120000.wav"), fmin = 500, fmax = 10000, threshold = 35, channel = "left", aggregate = NULL))
})

test_that('Signal level tests - aggregate', {
  expect_no_error(wt_signal_level(testthat::test_path("1-1A1-CA1-B_20250620_120000.wav"), fmin = 500, fmax = 10000, threshold = 35, channel = "right", aggregate = 10))
})

test_that('Making tasks', {
expect_no_error(wt_audio_scanner(testthat::test_path(), file_type = "wav", extra_cols = TRUE) |>
  slice(1) |>
  wt_make_aru_tasks(output = NULL, task_method = "1SPT", task_length = 60))
})

test_that('Audiomoth formatting', {
  expect_no_error(wt_format_audiomoth_filenames(testthat::test_path("audiomoth")))
                                })

test_that("Audio Analysis Programs workflow runs successfully", {

  # Scan test WAV file
  j <- wt_audio_scanner(
    testthat::test_path(),
    file_type = "wav",
    extra_cols = TRUE
  ) |>
    dplyr::slice(1)

  expect_equal(nrow(j), 1)

  # Run Analysis Programs
  ap_output <- testthat::test_path("ap_output")

  wt_run_ap(
    j,
    output_dir = ap_output,
    path_to_ap = testthat::test_path("APNnew/AnalysisPrograms")
  )

  # Check that AP produced output
  expect_true(dir.exists(ap_output))

  # Wrangle Analysis Programs output
  expect_no_error(wt_glean_ap(
    j,
    input_dir = ap_output,
    purpose = "biotic"
  ))


})

