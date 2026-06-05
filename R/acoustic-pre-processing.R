#' Scan acoustic data to a standard format
#'
#' @description Scans directories of audio data
#'
#' @param path Character; The path to the directory with audio files
#' @param file_type Character; File types of wav, wac, flac or all
#' @param extra_cols Boolean; TRUE returns duration, sample rate and channels
#'
#' @importFrom fs dir_ls file_size
#' @importFrom tibble as_tibble
#' @importFrom dplyr mutate select filter case_when arrange
#' @importFrom dplyr group_by row_number ungroup bind_rows
#' @importFrom tuneR readWave
#' @importFrom purrr map map_dbl pluck
#' @importFrom tidyr separate pivot_longer unnest_longer
#' @export
#'
#' @examples
#' \dontrun{
#' wt_audio_scanner(path = ".", file_type = "wav", extra_cols = T)
#' }
#'
#' @return A tibble with a summary of your audio files.

wt_audio_scanner <- function(path, file_type, extra_cols = FALSE) {

  # Create regex for file_type
  if (file_type == "wav" || file_type == "WAV") {
    file_type_reg <- "\\.wav$|\\.WAV$"
  } else if (file_type == "wac") {
    file_type_reg <- "\\.wac$"
  } else if (file_type == "flac") {
    file_type_reg <- "\\.flac$"
  } else if (file_type == "all") {
    file_type_reg <- "\\.wav$|\\.wac$|\\.WAV$|\\.flac$"
  } else {
    stop("Please specify wac, wav, flac or all for file_type.")
  }

  # Scan files, gather metadata
  message("Reading files from directory... \n")
  df <- as_tibble(x = path) |>
    mutate(file_path = map(
      .x = value,
      .f = ~ dir_ls(
        path = .x,
        regexp = file_type_reg,
        recurse = TRUE,
        fail = FALSE
      )
    ))

  # Check if nothing was returned
  if(nrow(df) == 0) {
    stop("No files of the specified file type were found in this directory.")
  }

  # Create the main tibble
  df <- df |>
    unnest_longer(file_path) |>
    mutate(size_Mb = round(map_dbl(.x = file_path, .f = ~file_size(.x)) / 10e5, digits = 2), # Convert file sizes to megabytes
                  file_path = as.character(file_path)) |>
    select(file_path, size_Mb) |>
    filter(!size_Mb < 1) |>
    mutate(file_name = sub("\\..*", "", basename(file_path)), file_type = sub('.*\\.(\\w+)$', '\\1', basename(file_path))) |>
    # Parse location, recording date time and other temporal columns
    separate(file_name, into = c("location", "recording_date_time"), sep = "(?:_0\\+1_|_|__0__|__1__)", extra = "merge", remove = FALSE) |>
    mutate(recording_date_time = sub('.+?(?:__)', '', recording_date_time)) |>
    mutate(recording_date_time = as.POSIXct(strptime(recording_date_time, format = "%Y%m%d_%H%M%S"))) |>
    mutate(julian = as.POSIXlt(recording_date_time)$yday,
           year = as.numeric(format(recording_date_time,"%Y")),
           gps_enabled = case_when(grepl('\\$', file_name) ~ TRUE)) |>
    arrange(location, recording_date_time) |>
    group_by(location, year, julian) |>
    mutate(time_index = row_number()) |> # Ordered list of the recording per day, e.g. first recording of the day = 1, second equals 2, etc.
    ungroup()

  if (extra_cols == FALSE) {
    df_final_simple <- df # Omit the extra columns if chosen
  } else {
    # Scan the wav files first
    if ("wav" %in% df$file_type) {
      df_wav <- df |>
        filter(file_type == "wav") |>
        mutate(data = map(.x = file_path, .f = ~ readWave(.x, from = 0, to = Inf, units = "seconds", header = TRUE))) |>
        mutate(length_seconds = map_dbl(.x = data, .f = ~ round(pluck(.x[["samples"]]) / pluck(.x[["sample.rate"]]), 2)),
                      sample_rate = map_dbl(.x = data, .f = ~ round(pluck(.x[["sample.rate"]]), 2)),
                      n_channels = map_dbl(.x = data, .f = ~ pluck(.x[["channels"]]))) %>%
        select(-data)
    }
    #Then wac files
    if ("wac" %in% df$file_type) {
      df_wac <- df |>
        filter(file_type == "wac") |>
        mutate(wac_info = map(.x = file_path, .f = ~ wt_wac_info(.x)),
                      sample_rate = map_dbl(.x = wac_info, .f = ~ pluck(.x[["sample_rate"]])),
                      length_seconds = map_dbl(.x = wac_info, .f = ~ round(pluck(.x[["length_seconds"]]), 2)),
                      n_channels = map_dbl(.x = wac_info, .f = ~ pluck(.x[["n_channels"]]))) |>
        select(-wac_info)
    }
    #Finally flac
    if ("flac" %in% df$file_type) {
      df_flac <- df |>
        filter(file_type == "flac") |>
        mutate(flac_info = map(.x = file_path, .f = ~ wt_flac_info(.x)),
                      sample_rate = map_dbl(.x = flac_info, .f = ~ pluck(.x, 1)),
                      length_seconds = map_dbl(.x = flac_info, .f = ~ round(pluck(.x, 3), 2)),
                      n_channels = 0) |>
        select(-flac_info)
    }
  }
  # Stitch together
  if (exists("df_final_simple", inherits = FALSE)) {
    df_final <- df_final_simple
  } else {
    dfs <- c("df_wav", "df_wac", "df_flac")
    dfs <- dfs[dfs %in% ls()]
    if (length(dfs)) {
      df_final <- bind_rows(mget(dfs))
    }
  }
  # Return final data frame
  return(df_final)
  }

#' Extract relevant metadata from a wac file
#'
#' @description Scrape relevant information from wac (Wildlife Acoustics) file
#'
#' @param path Character; The wac file path
#' @export
#'
#' @return a list with relevant information

wt_wac_info <- function(path) {

  if (sub('.*\\.(\\w+)$', '\\1', basename(path)) != "wac") {
    stop("This is not a wac file.")
  }

  f <- file(path, open = "rb")
  on.exit(close(f))

  name <- readChar(f, 4)
  version <- readBin(con = f, what = integer(), size = 1, endian = "little")
  n_channels <- readBin(con = f, what = integer(), size = 1, endian = "little")
  frame_size <- readBin(con = f, what = integer(), size = 2, endian = "little")
  block_size <- readBin(con = f, what = integer(), size = 2, endian = "little")
  flags <- readBin(con = f, what = integer(), size = 2, endian = "little")
  sample_rate <- readBin(con = f, what = integer(), size = 4, endian = "little")
  samples <- readBin(con = f, what = integer(), size = 4, endian = "little")

  if (n_channels == 1) {
    stereo <- FALSE
  } else {
    stereo <- TRUE
  }

  length_seconds = samples / sample_rate

  return(out = list(sample_rate = sample_rate,
                    n_channels = n_channels,
                    length_seconds = length_seconds))

  }

#' Extract relevant metadata from a flac file
#'
#' @description Scrape relevant information from flac file
#'
#' @param path Character; The flac file path
#'
#' @importFrom seewave wav2flac
#' @importFrom tuneR readWave
#' @export
#'
#' @return a list with relevant information

wt_flac_info <- function(path) {

  if (sub('.*\\.(\\w+)$', '\\1', basename(path)) != "flac") {
    stop("This is not a flac file.")
  }

  newfile <- gsub("\\.flac", ".wav", path)
  wav2flac(path, reverse = TRUE)
  info <- readWave(newfile, header = TRUE)
  file.remove(newfile)

  return(out = list(sample_rate = info$sample.rate,
                    n_channels = info$n_channels,
                    length_seconds = info$samples / info$sample.rate))

  }

#' Get acoustic index values from audio
#'
#' @description For generating acoustic indices and false-colour spectrograms using QUT Ecoacoustics **A**nalysis **P**rograms software. See \url{https://github.com/QutEcoacoustics/audio-analysis} for information about usage and installation of the AP software.
#' Note that this function relies on having this software installed locally.
#'
#' This function will batch calculate summary and spectral acoustic indices and generate false-colour spectrograms for a folder of audio files using the Towsey.Acoustic configuration (yml) file from the AP software.
#' You can use the output from \code{`wt_audio_scanner()`} in the function, or define a local folder with audio files directly.
#'
#' @param x (optional) A data frame or tibble; must contain the absolute audio file path and file name. Use output from \code{`wt_audio_scanner()`}.
#' @param fp_col If x is supplied, the column containing the audio file paths. Defaults to file_path.
#' @param audio_dir (optional) Character; path to directory storing audio files.
#' @param output_dir Character; path to directory where you want outputs to be stored.
#' @param path_to_ap Character; file path to the AnalysisPrograms software package. Defaults to "C:\\AP\\AnalysisPrograms.exe".
#' @param delete_media Logical; when TRUE, removes the underlying sectioned wav files from the Towsey output. Leave to TRUE to save on space after runs.
#'
#' @importFrom dplyr enquo quo_name filter select pull rename
#' @importFrom purrr map
#' @importFrom tibble as_tibble
#' @export
#'
#' @return Output will return to the specific root directory

wt_run_ap <- function(x = NULL, fp_col = file_path, audio_dir = NULL, output_dir, path_to_ap = "C:\\AP\\AnalysisPrograms.exe", delete_media = FALSE) {

  # Make sure at least (and only) one of x or audio_folder has been supplied
  if (is.null(x) & is.null(audio_dir)) {
    stop(
      "Please supply either a dataframe with the x argument, or a path to a directory of audio files with the audio_dir argument.",
      call. = TRUE
    )
  } else if (!is.null(x) & !is.null(audio_dir)) {
    stop("Please only supply one of x or audio_dir", call. = TRUE)
  }

  # Check if output_dir is supplied
  if (missing(output_dir)) {
    stop(
      "Please specify a path to a local directory where you would like outputs to be stored.",
      call. = TRUE
    )
  }

  # Supported AP audio formats
  supported_formats <- "\\.wav$|\\.mp3$|\\.ogg$|\\.flac$|\\.wv$|\\.webm$|\\.wma$"
  convert <- "\\.wac$"

  # List audio files for analysis (vector)
  if (!is.null(x)) {
    # Ensure fp_col is a column name of x
    column <- enquo(fp_col) %>%
      quo_name()
    if (!column %in% names(x)) {
      stop("The value in fp_col does not refer to a column in x.")
    }
    files <- x %>%
      filter(grepl(supported_formats, {{fp_col}})) %>%
      select({{fp_col}}) %>%
      pull()
  } else {
    files <- list.files(audio_dir, pattern = supported_formats, full.names = TRUE)
  }

    print("Starting AnalysisPrograms run - this may take a while depending on your machine and how many files you want to process...")

    files <- files |>
      as_tibble() %>%
      rename("file_path" = 1) %>%
      map(.x = .$file_path, .f = ~suppressMessages(system2(path_to_ap, sprintf('audio2csv "%s" "Towsey.Acoustic.yml" "%s" "-p"', .x, output_dir))))

    if (delete_media == TRUE) {
      .delete_wav_files(output_dir)
      message("Deleting media as requested. This may take a moment...")
    }

  return(message('Done AP Run! Check output folder for results and then run wt_glean_ap for visualizations.'))

  }

#' Extract and plot relevant acoustic index metadata and LDFCs
#'
#' @description This function will use a list of media files from a `wt_*` work flow and outputs from `wt_run_ap()`
#' in order to generate summary plots of acoustic indices and long-duration false-colour spectrograms. This can
#' be viewed as the "final step" in interpreting acoustic index and LDFC values from your recordings.
#'
#' @param x A data frame or tibble; must contain the file name. Use output from \code{`wt_audio_scanner()`}.
#' @param input_dir Character; A folder path where outputs from \code{`wt_run_ap()`} are stored.
#' @param purpose Character; type of filtering you can choose from
#' @param include_ind Logical; Include index results
#' @param include_ldfcs Logical; Include LDFC results
#' @param borders Logical; Include borders to define different recordings
#'
#' @import ggplot2
#' @importFrom dplyr relocate select rename mutate filter distinct inner_join
#' @importFrom fs dir_ls dir_info
#' @importFrom tidyr pivot_longer
#' @importFrom purrr reduce map_dfr map
#' @importFrom readr read_csv
#' @importFrom magick image_read image_append image_border
#' @export
#'
#' @examples
#' \dontrun{
#' wt_glean_ap(x = wt_audio_scanner_data, input_dir = "/path/to/my/files")
#' }
#'
#' @return Output will return the merged tibble with all information, the summary plots of the indices and the LDFC

wt_glean_ap <- function(x = NULL, input_dir, purpose = c("quality","abiotic","biotic"), include_ind = TRUE, include_ldfcs = TRUE, borders = FALSE) {

  # Check to see if the input exists and reading it in
  files <- x

  #Purpose lists
  if (purpose == "quality") {
    purpose_list <- c("Snr","BackgroundNoise")
  } else if (purpose == "abiotic") {
    purpose_list <- c("ClippingIndex","TemporalEntropy","Ndsi")
  } else if (purpose == "biotic") {
    purpose_list <- c("HighFreqCover","MidFreqCover","LowFreqCover","AcousticComplexity","Ndsi")
  } else if (is.null(purpose)) {
    purpose_list <- list_all
  }

  # Check to see if the input exists and reading it in
  if (dir.exists(input_dir)) {
    ind <-
      dir_ls(input_dir, regexp = "*.Indices.csv", recurse = TRUE) |>
        map_dfr( ~ read_csv(.x, show_col_types = FALSE)) |>
        relocate(c(FileName, ResultMinute)) |>
        select(-c(ResultStartSeconds, SegmentDurationSeconds,RankOrder,ZeroSignal)) |>
        pivot_longer(!c(FileName, ResultMinute), names_to = "index_variable", values_to = "index_value")

    ldfcs <-
      dir_info(input_dir, regexp = "*__2Maps.png", recurse = TRUE) |>
      select(path) |>
      rename("image" = 1) |>
      mutate(file_name = sub('__2Maps.png$', '', basename(image)))

  } else {
    stop("Cannot find this directory")
  }

  # Join the indices and LDFCs to the media
  data_to_join <- list(files, if (include_ind) ind else NULL, if (include_ldfcs) ldfcs else NULL) %>%
    discard(is.null)

  data_to_join <- map(data_to_join, function(df) {
    if ("file_name" %in% names(df)) {
      df <- rename(df, FileName = file_name)
    }
    df})

  joined <- reduce(data_to_join, ~inner_join(.x, .y, by = "FileName"))

  if(nrow(joined) > 0){
    print('Files joined!')
  }

  joined_purpose <- joined |>
    filter(index_variable %in% purpose_list)

  # Plot a summary of the indices
  plotted <- joined_purpose |>
    ggplot(aes(x=julian, y=index_value, group=julian, fill=index_variable)) +
    geom_boxplot() +
    scale_fill_viridis_d() +
    theme_bw() +
    facet_wrap(~index_variable, scales = "free_y") +
    theme(legend.position="right", legend.box = "horizontal") +
    guides(fill = guide_legend(title="New Legend Title")) +
    guides(fill = guide_legend(nrow = 25, ncol = 1)) +
    xlab("Julian Date") +
    ylab("Index value") +
    ggtitle("Summary of indices")

  # Plot the LDFC. Apply border only if the condition is TRUE
  ldfc <- joined_purpose |>
    select(image) |>
    distinct() |>
    map(function(x) {
      img <- image_read(x)
      if (borders == TRUE) {
        img <- image_border(img, color = "#00008B", geometry = "0.75x0.75")
      }
      return(img)
    }) %>%
    do.call("c", .) %>%
    image_append()

  # Trim top and bottom and crop
  img_info <- image_info(ldfc)
  img_width <- img_info$width
  img_height <- img_info$height

  top_crop_height <- as.integer(img_height * 0.061)
  bottom_crop_height <- as.integer(img_height * 0.028)
  remaining_height <- as.integer(img_height - top_crop_height - bottom_crop_height)

  cropped_img <- ldfc %>%
    image_crop(geometry = sprintf("%dx%d+0+%d",
                                  img_width,
                                  remaining_height,
                                  top_crop_height))

  return(list(joined,plotted,ldfc))

  }

#' Get signals from specific windows of audio
#'
#' @description Signal level uses amplitude and frequency thresholds in order to detect a signal.
#'
#' @param path The path to the wav file
#' @param fmin The frequency minimum
#' @param fmax The frequency maximum
#' @param threshold The desired threshold
#' @param channel Choose "left" or "right" channel
#' @param aggregate Aggregate detections by this number of seconds, if desired
#'
#' @importFrom dplyr mutate lag group_by summarise ungroup
#' @importFrom tuneR readWave
#' @importFrom seewave spectro
#' @export
#'
#' @examples
#' \dontrun{
#' df <- wt_signal_level(path = "")
#' }
#'
#' @return A list object containing the following four elements: output (dataframe), aggregated (boolean), channel (character), and threshold (numeric)
#'

wt_signal_level <- function(path, fmin = 500, fmax = NA, threshold, channel = "left", aggregate = NULL) {

  wav_object <- readWave(path)
  sampling_frequency <- wav_object@samp.rate

  # Recording duration
  recording_duration <- length(wav_object@left) / sampling_frequency

  # Check that channel is set to either left or right
  if (!(channel == "left" | channel == "right")) {
    stop('Please specify "left" or "right" channel.')
  }

  if (channel == "left") {
    wav_object <- wav_object@left
  } else {
    if (length(wav_object@right) %in% c(0, 1)) {
      stop('Channel set to "right", but no right channel')
    }
    wav_object <- wav_object@right
  }

  # Remove DC offset
  wav_object <- wav_object - mean(wav_object)

  # Set breaks
  breaks <- seq(0, recording_duration, 300)
  if (breaks[length(breaks)] != recording_duration) {
    breaks[length(breaks) + 1] <- recording_duration
  }

  samps <- breaks * sampling_frequency
  samps[1] <- 1

  times = c()
  rsl.out <- c()

  for (i in 2:length(breaks)) {
    print(paste0('Calculating segment ', i - 1, ' out of ', length(breaks) - 1))
    s <- spectro(wav_object[samps[i - 1]:samps[i]], f = sampling_frequency, wn = "hamming", wl = 512, ovlp = 50, plot = FALSE, norm = FALSE)
    subset <- which(s$freq >= fmin / 1000)
    if (!is.na(fmax)) {
      subset <- which(s$freq >= fmin / 1000 & s$freq <= fmax / 1000)
    }
    s$freq <- s$freq[subset]
    s$amp <- s$amp[subset,]
    # Calculate max RSL for each window
    rsl <- apply(s$amp, 2, max)
    # Edit times for the chunk
    s$time <- s$time + breaks[i - 1]
    times <- c(times, s$time[rsl > threshold])
    rsl.out <- c(rsl.out, rsl[rsl > threshold])
  }

  if (length(times) > 0) {
    sl <- data.frame(time = times, rsl = rsl.out)
  } else {
    sl <- NA
  }

  # Aggregate (if desired)
  if (!is.null(aggregate)) {
    if (!is.na(sl)) {
      sl <- sl |>
        mutate(time_lag = lag(time),
               new_detection = ifelse((time - time_lag) >= aggregate, 1, 0),
               detection = c(0, cumsum(new_detection[-1])) + 1) |>
        group_by(detection) |>
        summarise(mean_rsl = mean(rsl),
                  start_time_s = min(time),
                  end_time_s = max(time)) |>
        ungroup() |>
        mutate(detection_length = end_time_s - start_time_s)
      aggregated <- TRUE
    } else {
      sl
      aggregated <- FALSE
      warning("No signals met the threshold criteria. Output not aggregated.")
    }
  } else {
    if (!is.na(sl)) {
      sl
      aggregated <- FALSE
    } else {
      sl
      aggregated <- FALSE
      warning("No signals met the threshold critera.")
    }
  }

  # Create list object
  d <- list(
    output = sl,
    aggregated = aggregated,
    channel = channel,
    threshold = threshold
  )

  return(d)

}

#' Segment large audio files
#'
#' @description "Chops" up wav files into many smaller files of a desired duration and writes them to an output folder.
#'
#' @param input A data frame or tibble containing information about audio files
#' @param segment_length Numeric; Segment length in seconds. Modulo recording will be exported should there be any trailing time left depending on the segment length used
#' @param output_folder Character; output path to where the segments will be stored
#'
#' @importFrom tuneR readWave writeWave
#' @importFrom tibble add_column
#' @importFrom dplyr select mutate filter across
#' @importFrom tidyr unnest_longer
#' @importFrom purrr pmap
#'
#' @export
#'
#' @examples
#' \dontrun{
#' wt_chop(input = my_files, segment_length = 60, output_folder = "output_folder")
#' }
#'
#' @return No return value, called for file-writing side effects.

wt_chop <- function(input = NULL, segment_length = NULL, output_folder = NULL) {

  # Check if output folder exists
  if (!dir.exists(output_folder)) {
    stop("The output directory does not exist.")
  }

  # Validate segment length
  if (is.null(segment_length) || !is.numeric(segment_length) || segment_length <= 0) {
    stop("Segment length must be a positive numeric value.")
  }

  # Check for input and output folder overlap
  if (any(grepl(normalizePath(output_folder), normalizePath(input$file_path)))) {
    stop("The output folder cannot be the same as the input file directory to prevent overwriting.")
  }

  # Prepare input data
  inp <- input |>
    select(file_path, recording_date_time, location, file_type, length_seconds) |>
    add_column(length_sec = segment_length) |>
    mutate(longer = ifelse(length_seconds >= length_sec, TRUE, FALSE),
           length_seconds = round(length_seconds, 0))

  # Check for too short recordings
  if (any(inp$length_seconds < segment_length)) {
    stop("Some recordings are shorter than the segment length.")
  }

  # Generate start times and new file paths
  inp2 <- inp %>%
    mutate(start_times = purrr::map2(length_seconds, length_sec, ~ seq(0, .x - .y, by = .y))) %>%
    unnest_longer(start_times) %>%
    filter(start_times + length_sec <= length_seconds) %>%
    mutate(new_file = paste0(output_folder, "/", location, "_", format(recording_date_time + as.difftime(start_times, units = "secs"), "%Y%m%d_%H%M%S"), ".", file_type)) %>%
    mutate(across(c(length_sec, start_times), as.numeric))

  # Process audio files with validation
  inp2 %>%
    pmap(.l = list(file_path = .$file_path, new_file = .$new_file, length_sec = .$length_sec, start_times = .$start_times),
                .f = ~ {
                  file_path <- ..1
                  new_file <- ..2
                  length_sec <- as.numeric(..3)
                  start_times <- as.numeric(..4)
                  cat("Processing:\n  File:", file_path, "\n  Start:", start_times, "\n  Length:", length_sec, "\n  New File:", new_file, "\n")
                  if (!file.exists(file_path)) {
                    message("File not found: ", file_path)
                    return(NULL)
                  }

                  tryCatch({
                    writeWave(readWave(file_path, from = start_times, to = start_times + length_sec, units = "seconds"), filename = new_file, extensible = TRUE)}, error = function(e) {
                    message("Error processing file: ", file_path, " - ", e$message)})
                }
    )
}

#' Standardize Audiomoth Filenames
#'
#' Recursively scans a directory for `.wav` files produced by Audiomoth devices and renames them by prepending the parent folder name to each filename. For example, a file named `20240407_062500.wav` inside a folder `LOCATION-ABC` becomes `LOCATION-ABC_20240407_062500.wav`.
#'
#' @param input_dir Character string. The path to the top-level directory containing Audiomoth folders and audio files.
#'
#' @importFrom dplyr rename mutate filter
#' @importFrom tibble as_tibble
#' @importFrom purrr pwalk
#'
#' @return A tibble with the original filepaths and the corresponding new filepaths. Files are renamed in place.
#'
#' @examples
#' \dontrun{
#' wt_format_audiomoth_filenames("/path/to/my_dir")
#' }
#'
#' @export

wt_format_audiomoth_filenames <- function(input_dir) {

  if(dir.exists(input_dir) == FALSE) {
    stop(message("This directory does not exist."))
    }

  files <- list.files(input_dir, pattern = "\\.wav$", recursive = TRUE, full.names = TRUE) |>
      as_tibble() |>
      rename(filepath = value) |>
      mutate(parentfolder = basename(dirname(filepath)),
             filename = basename(filepath),
             dirpath = dirname(filepath),
             newpath = file.path(dirpath, paste0(parentfolder, "_", filename)))

    pwalk(list(files$filepath, files$newpath), file.rename)

    return(files)

}

#' Linking media to WildTrax
#'
#' The following suite of functions will help you wrangle media and data together
#' in order to upload them to WildTrax. You can make tasks(https://www.wildtrax.ca/home/resources/guide/projects/aru-projects.html)
#' and tags(https://www.wildtrax.ca/home/resources/guide/acoustic-data/acoustic-tagging-methods.html) using the results from a
#' `wt_audio_scanner()` tibble or the hits from one of two Wildlife Acoustics programs Songscope() and Kaleidoscpe().
#'
#' @description `wt_make_aru_tasks()` uses a `wt_audio_scanner()` input tibble to create a task template to upload to a WildTrax project.
#'
#' @param input Character; An input `wt_audio_scanner()` tibble. If not a `wt_audio_scanner()` tibble, the data must contain at minimum the location, recording_date_time and file_path as columns.
#' @param output Character; Path where the output task csv file will be stored
#' @param task_method Character; Method type of the task. Options are 1SPM, 1SPT and None.
#' @param task_length Numeric; Task length in seconds. Must be between 1 - 1800 and can be up to two decimal places.
#'
#' @importFrom dplyr select distinct mutate case_when
#' @importFrom tibble add_column
#' @importFrom readr write_csv
#'
#' @export
#'
#' @examples
#' \dontrun{
#' wt_make_tasks(input = my_audio_tibble, output = tasks.csv, task_method = "1SPT", task_length = 180)
#' }
#'
#' @return A csv formatted as a WildTrax task template

wt_make_aru_tasks <- function(input, output=NULL, task_method = c("1SPM","1SPT","None"), task_length) {

  task_prep <- input

  req_cols <- c("location","recording_date_time","length_seconds", "recording_sample_frequency")

  if (!any(names(task_prep) %in% req_cols)){
    stop("Missing certain columns. Check that you have file_path, location and recording_date_time at a minimum in order to generate tasks.")
  }

  req_methods <- c("1SPM","1SPT","None")

  if (!(task_method %in% req_methods)) {
    stop("This isn't an accepted method. Use 1SPM, 1SPT or None.")
  }

  if ((is.numeric(task_length) && task_length >= 1 && task_length < 1800) == FALSE) {
    stop("task_length must be a number and between 1 and 1800 seconds.")
  }

  tasks <- task_prep |>
    rename(recording_sample_frequency = sample_rate) |>
    select(location, recording_date_time, length_seconds, recording_sample_frequency) |>
    distinct() |>
    mutate(task_duration = case_when(length_seconds < task_length ~ NA_real_, TRUE ~ task_length)) |> #Make sure recording length is long enough
    select(-length_seconds) |>
    add_column(method = task_method, .after = "recording_date_time") |>
    relocate(recording_sample_frequency, .after = "method") |>
    relocate(task_duration, .after = "recording_sample_frequency") |>
    rename(task_method = method) |>
    add_column(task_is_complete = FALSE, .after = "task_duration") |>
    add_column(observer = "", .after = "task_is_complete") |>
    add_column(task_comments = "", .after = "observer") |>
    add_column(internal_task_id = "", .after = "task_comments") |>
    mutate(recording_date_time = as.character(recording_date_time))

  no_length <- tasks |>
    filter(is.na(task_duration))

  if ((nrow(no_length)) > 0) {
    message(nrow(no_length), ' rows are shorter than the desired task length')
  }

  if (!is.null(tasks)) {
    message("Converted recordings to tasks. Go to your project and use Manage > Upload Tasks to synchorize the results.")
  }

  if (is.null(output)) {
    return(tasks)
  } else {
    return(write_csv(tasks, output))
  }
}

#' Convert Kaleidoscope output to tags
#'
#' @description `wt_kaleidoscope_tags` Takes the classifier output from Wildlife Acoustics Kaleidoscope and converts them into a WildTrax tag template for upload
#'
#' @param input Character; The path to the input csv
#' @param output Character; Path where the output file will be stored
#' @param freq_bump Boolean; Set to TRUE to add a buffer to the frequency values exported from Kaleidoscope. Helpful for getting more context around a signal in species verification
#'
#' @importFrom dplyr relocate mutate select rename group_by ungroup rowwise case_when mutate_at
#' @importFrom tibble as_tibble add_column
#' @importFrom readr read_csv write_csv cols
#' @importFrom tidyr drop_na separate separate_rows
#'
#' @export
#'
#' @examples
#' \dontrun{
#' wt_kaleidoscope_tags(input = input.csv, output = tags.csv, freq_bump = TRUE)
#' }
#'
#' @return A csv formatted as a WildTrax tag template

wt_kaleidoscope_tags <- function (input, output = NULL, freq_bump = TRUE) {

  #Check to see if the input exists and reading it in
  if (file.exists(input)) {
    in_tbl <- read_csv(input, col_names = TRUE, na = c("", "NA"), col_types = cols())
  } else {
    stop ("File cannot be found")
  }

  # Cleaning things up for the tag template
  in_tbl_wtd <- in_tbl |>
    select(INDIR, `IN FILE`, DURATION, OFFSET, Dur, `AUTO ID*`, `MANUAL ID`, Fmin, Fmax) |>
    separate(`IN FILE`, into = c("location", "recording_date_time"), sep = "(?:_0\\+1_|_|__0__|__1__)", extra = "merge", remove = FALSE) |>
    separate_rows(`MANUAL ID`, sep = ",\\s*") |>
    relocate(location, .before = everything()) |>
    relocate(recording_date_time, .after = location) |>
    mutate(recording_date_time = sub('.*?(?:__)?(\\d{4})(\\d{2})(\\d{2})_(\\d{2})(\\d{2})(\\d{2})\\..*$', '\\1-\\2-\\3 \\4:\\5:\\6', recording_date_time)) |>
    rename("task_duration" = 5,
                  "tag_start_time" = 6,
                  "tag_duration" = 7,
                  "min_tag_freq" = 10,
                  "max_tag_freq" = 11) |>
    mutate(species_code = if_else(!is.na(`MANUAL ID`), `MANUAL ID`, `AUTO ID*`))|>
    mutate(species_individual_comments = if_else(!is.na(`MANUAL ID`), "Manual ID", "AUTO ID"))|>
    select(-(`AUTO ID*`:`MANUAL ID`))|>
    select(-(INDIR:`IN FILE`)) |>
    mutate(species_code = case_when(species_code == "NOID|NoID" ~ "UBAT",
                                    species_code == "HIF" ~ "HighF",
                                    species_code == "LOF" ~ "LowF",
                                    species_code == "EPFU" ~ "EPTFUS",
                                    species_code == "LANO" ~ "LASNOC",
                                    species_code == "MYLU" ~ "MYOLUC",
                                    species_code == "MYVO" ~ "MYOVOL",
                                    species_code == "MYSE" ~ "MYOSEP",
                                    species_code == "MYEV" ~ "MYOEVO",
                                    species_code == "LACI" ~ "LASCIN",
                                    species_code == "LABO" ~ "LASBOR",
                                    species_code == "MYCI" ~ "MYOCIL",
                                    TRUE ~ species_code),
           tag_start_time = case_when(tag_start_time == 0 ~ 0.1, TRUE ~ tag_start_time)) |>
    add_column(task_method = "None", .after = "recording_date_time") |>
    add_column(observer = "Not Assigned", .after = "task_duration") |>
    group_by(location, recording_date_time, task_duration, species_code) |>
    mutate(individual_number = row_number()) |>
    ungroup() |>
    add_column(vocalization = "", .after = "individual_number") |>
    add_column(abundance = 1, .after= "vocalization") |>
    mutate(vocalization = case_when(species_code == "Noise" ~ "Non-vocal", TRUE ~ "Call")) |>
    add_column(internal_tag_id = "", .after = "max_tag_freq") |>
    mutate(recording_date_time = as.character(recording_date_time)) |>
    rowwise() |>
    mutate(tag_duration = case_when(tag_duration > tag_duration ~ tag_duration, TRUE ~ tag_duration)) |>
    mutate(tag_duration = case_when(is.na(tag_duration) ~ tag_duration - tag_start_time, TRUE ~ tag_duration),
           min_tag_freq = case_when(is.na(min_tag_freq) ~ 12000, TRUE ~ min_tag_freq * 1000),
           max_tag_freq = case_when(is.na(max_tag_freq) ~ 96000, TRUE ~ max_tag_freq * 1000)) |>
    ungroup() |>
    mutate_at(vars(task_duration, min_tag_freq, max_tag_freq), ~round(.,2)) |>
    mutate(min_tag_freq = case_when(freq_bump == TRUE ~ min_tag_freq - 10000, TRUE ~ min_tag_freq),
           max_tag_freq = case_when(freq_bump == TRUE ~ max_tag_freq + 10000, TRUE ~ max_tag_freq)) |>
    relocate(task_duration, .after = task_method) |>
    relocate(tag_start_time, .after = abundance) |>
    relocate(tag_duration, .after = tag_start_time) |>
    relocate(min_tag_freq, .after = tag_duration) |>
    relocate(max_tag_freq, .after = min_tag_freq) |>
    relocate(internal_tag_id, .after = max_tag_freq) |>
    mutate(recording_sample_frequency = "", .after = task_method) |>
    mutate(task_is_complete = "f", .after = task_duration) |>
    drop_na()

  if(!is.null(output)) { return(write_csv(in_tbl_wtd, file = output)) } else {return(in_tbl_wtd)}

  print("Converted to WildTrax tags. Go to your WildTrax project > Manage > Upload Tags.")

  }

#' Convert Songscope output to tags
#'
#' @param input Character; The path to the input csv
#' @param output Character; Path where the output file will be stored
#' @param output_file Character; Path of the output file
#' @param species Character; Short-hand code for the species (see `wt_get_species()`)
#' @param vocalization Character; The vocalization type from either Song, Call, Non-Vocal, Nocturnal flight call and Feeding Buzz
#' @param method Character; Include options from 1SPT, 1SPM or None
#' @param score_filter Numeric; Filter the detections by a score threshold
#' @param duration Numeric; length of the task in seconds
#' @param sample_freq Numeric; The sampling frequency in Hz of the recording
#'
#' @importFrom dplyr rename mutate filter select group_by ungroup relocate
#' @importFrom tibble add_column
#' @importFrom readr read_table
#' @importFrom tidyr separate
#'
#' @export
#'
#' @return A csv formatted as a WildTrax tag template

wt_songscope_tags <- function (input, output = c("env","csv"), output_file=NULL, species, vocalization, score_filter, method = NULL, duration, sample_freq) {

  # Check to see if the input exists and reading it in
  if (file.exists(input)) {
    in_tbl <- read_table(input, col_names = FALSE, show_col_types = FALSE)
  } else {
    stop ("File cannot be found")
  }

  if ((output == "csv") & is.null(output_file)) {
    stop("Specify an output file name for the tag csv")
  } else if (output == "env") {
    print("Reading file...")
  }

  # Cleaning things up for the tag template
  in_tbl_wtd <- in_tbl |>
    rename("file_path" = 1) |>
    rename("tag_start_time" = 2) |>
    rename("tag_duration" = 3) |>
    rename("level" = 4) |>
    rename("Quality" = 5) |>
    rename("Score" = 6) |>
    rename("recognizer" = 7) |>
    rename("comments"= 8) |>
    mutate(file_name = sub("\\.[^.]+$", "", sub("^.*\\\\", "", file_path))) |>
    separate(file_name, into = c("location", "recording_date_time"), sep = "(?:_0\\+1_|_|__0__|__1__)", extra = "merge", remove = FALSE) |>
    mutate(tag_start_time = as.numeric(tag_start_time)) |>
    mutate(recording_date_time = as.POSIXct(recording_date_time, format = "%Y%m%d_%H%M%S"))

  if (method == "USPM") {

    in_tbl_wtd <- in_tbl_wtd |>
      filter(Score >= score_filter) |>
      mutate(task_method = method, .after = "recording_date_time") |>
      mutate(task_duration = duration, .after = "task_method") |>
      mutate(observer = "Not Assigned", .after = "tag_duration") |>
      mutate(species_code = species, .after = "observer") |>
      group_by(location, recording_date_time, task_method, task_duration, observer, species_code) |>
      mutate(individual_number = 1) |>
      ungroup() |>
      mutate(`vocalization` = vocalization, .after = individual_number) |>
      add_column(abundance = 1, .after= "vocalization") |>
      relocate(tag_start_time, .after = abundance) |>
      relocate(tag_duration, .after = tag_start_time) |>
      add_column(min_tag_freq = "", .after= "tag_duration") |>
      add_column(max_tag_freq = "", .after= "min_tag_freq") |>
      mutate(species_individual_comments = paste(`level`, Quality, Score, recognizer, sep = "/"), .after = "max_tag_freq") |>
      mutate(tag_is_hidden_for_verification = FALSE) |>
      mutate(recording_sample_frequency = 44100) |>
      mutate(internal_tag_id = "", .after = "max_tag_freq") |>
      select(location, recording_date_time, task_duration, task_method, observer, species_code,
             individual_number, vocalization, abundance, tag_start_time, tag_duration,
             min_tag_freq, max_tag_freq, species_individual_comments, tag_is_hidden_for_verification, recording_sample_frequency, internal_tag_id)

  } else if (method == "1SPT") {

    in_tbl_wtd <- in_tbl_wtd |>
      filter(Score >= score_filter) |>
      add_column(task_method = "1SPT", .after = "recording_date_time") |>
      add_column(task_duration = duration, .after = "task_method") |>
      add_column(observer = "Not Assigned", .after = "task_duration") |>
      add_column(species_code = species, .after = "observer") |>
      group_by(location, recording_date_time, task_method, task_duration, species_code) |>
      mutate(individual_number = row_number()) |>
      ungroup() |>
      filter(!individual_number > 1) |>
      mutate(`vocalization` = vocalization) |>
      add_column(abundance = 1, .after= "vocalization") |>
      relocate(tag_start_time, .after = abundance) |>
      relocate(tag_duration, .after = tag_start_time) |>
      add_column(min_tag_freq = "", .after= "tag_duration") |>
      add_column(max_tag_freq = "", .after= "min_tag_freq") |>
      mutate(species_individual_comments = paste(`level`, Quality, Score, recognizer, sep = "/"), .after = "max_tag_freq") |>
      add_column(tag_is_hidden_for_verification = FALSE) |>
      mutate(recording_sample_frequency = 44100) |>
      add_column(internal_tag_id = "", .after = "max_tag_freq") |>
      select(location, recording_date_time, task_method, task_duration, observer, species_code,
             individual_number, vocalization, abundance, tag_start_time, tag_duration,
             min_tag_freq, max_tag_freq, species_individual_comments, tag_is_hidden_for_verification, recording_sample_frequency, internal_tag_id)

  } else {

    stop("Only USPM and 1SPT uploads are supported at this time")

  }

  if (max(in_tbl_wtd$tag_start_time > duration)) {
    message("Warning: there are tags outside the length of the chosen task. You will not be able to sync these tags since they exceed the task duration")
  }

  # Write the file
  if (output == "env") {
    return(in_tbl_wtd)
    print("Converted to WildTrax tags. Review the output, generate a CSV, then go to your WildTrax project > Manage > Upload Tags")
  } else if (output == "csv") {
    return(list(in_tbl_wtd, write_csv(in_tbl_wtd, file = output_file)))
    print("Converted to WildTrax tags. Review the output CSV then go to your WildTrax project > Manage > Upload Tags")
  }

}

#' Convert GUANO embeded metadata to tags and metadata output for a Project
#'
#' @description `wt_guano_tags` Takes the embeded classifier output and converts them into a WildTrax tag template for upload
#' `r lifecycle::badge("experimental")`
#'
#' @param path Character; The path to the input csv
#' @param output Character; Path where the output file will be stored
#' @param output_file Character; Path of the output file

#' @importFrom dplyr rename
#' @importFrom tidyr pivot_longer
#' @importFrom tibble as_tibble
#'
#' @export
#'
#' @examples
#' \dontrun{
#' wt_guano_tags(path = my_audio_file.csv, output = NULL, output_file = NULL)
#' }
#'
#' @return A csv formatted as a WildTrax tag template

wt_guano_tags <- function(path, output = NULL, output_file = NULL) {

  wav_path <- path
  con <- file(wav_path, "rb")
  on.exit(close(con), add = TRUE)

  read_chunk <- function(con) {
    id <- tryCatch(rawToChar(readBin(con, "raw", 4)), error   = function(e) NA_character_, warning = function(w) NA_character_)
    size <- readBin(con, "integer", 1, size = 4, endian = "little")
    data <- readBin(con, "raw", size)
    list(id = id, size = size, data = data)
  }

  # Skip RIFF header (RIFF + size + WAVE)
  readBin(con, "raw", 12)

  chunks <- list()

  while (TRUE) {
    peek <- tryCatch(readBin(con, "raw", 1), error = function(e) NULL, warning = function(w) NULL)
    if (is.null(peek) || length(peek) == 0) break
    seek(con, -1, origin = "current")
    chunks[[length(chunks) + 1]] <- read_chunk(con)
  }

  # Extract GUANO chunk
  idx <- which(vapply(chunks, function(x) x$id, "") == "guan")
  guan <- chunks[[idx]]

  # Decode text
  guan_txt <- rawToChar(guan$data, multiple = TRUE)
  guan_txt <- paste(guan_txt, collapse = "")
  lines <- unlist(strsplit(guan_txt, "\n"))
  kv <- do.call(rbind, lapply(lines, function(x) {
    parts <- strsplit(x, ":", fixed = TRUE)[[1]]
    key <- trimws(parts[1])
    value <- trimws(paste(parts[-1], collapse = ":"))
    c(key, value)
  }))
  guan_tibble <- tibble(key = kv[,1], value = kv[,2])

  # Convert to WildTrax tags and metadata
  guan_tags <- guan_tibble |>
    pivot_wider(names_from = key, values_from = value) |>
    rename(location = `Loc Position`)

  guan_extra <- guan_tibble |>
    pivot_wider(names_from = key, values_from = value) |>
    rename(guano_version = `GUANO|Version`)

  return(list(guan_tags, guan_extra))

}

