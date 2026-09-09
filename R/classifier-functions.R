#' Evaluate a classifier
#'
#' @description Calculates precision, recall, and F-score of BirdNET and/or HawkEars for a requested sequence of thresholds. You can request the metrics at the minute level for recordings that are processed with the species per minute method (1SPM).
#'
#' @param data Output from the `wt_download_report()` function when you request the `main` and `ai` reports
#' @param resolution Character; either "recording" to summarize at the entire recording level or "minute" to summarize the minute level if the `task_method` is "1SPM", or "task"
#' @param remove_species Logical; indicates whether species that are not allowed in the WildTrax project should be removed from the AI report
#' @param species Character; optional subset of species to calculate metrics for (e.g., species = c("OVEN", "OSFL", "BOCH"))
#' @param thresholds Numeric; start and end of sequence of score thresholds at which to calculate performance metrics
#'
#' @import dplyr
#' @export
#'
#' @examples
#' \dontrun{
#' data <- wt_download_report(project_id = 1144, sensor_id = "ARU",
#' reports = c("main", "ai"))
#'
#' eval <- wt_evaluate_classifier(data, resolution = "recording",
#' remove_species = TRUE, thresholds = c(0.1, 0.99))
#' }
#'
#' @return A tibble containing columns for precision, recall, and F-score for each of the requested thresholds.

wt_evaluate_classifier <- function(data, resolution = NULL, remove_species = TRUE,  species = NULL, thresholds = c(0.01, 0.99)){

  # Check if the data object is in the right format
  if (!inherits(data, "list") && !grepl("ai", names(data)[[2]]) && !grepl("main", names(data))[[1]]) {
    stop("The input should be the output of the `wt_download_report()` function with the argument `reports=c('main', 'ai')`")
  }

  # Check if the project has the correct transcription method for evaluation method chosen
  method <- data[[2]]$task_method[1]
  if(method=="NONE"){
    stop("The `wt_evaluate_classifier()` function only works on recordings processed with the '1SPT' or '1SPM' methods")
  }
  if(method=="1SPT" & resolution=="minute"){
    stop("You can only evaluate at the minute resolution for recordings that have been processed with the '1SPM' method")
  }

  # Get the classifier report and filter species as requested
  if(remove_species==TRUE){
    class <- data[[1]] |>
      filter(is_species_allowed_in_project==TRUE)
  } else {
    class <- data[[1]]
  }

  # Summarize the classifier report to the requested resolution
  if(resolution=="task"){

    class <- class |>
      inner_join(data[[2]] |> select(recording_id, task_id) |> distinct(), by = "recording_id")

    detections <- class |>
      rename(start_s = detection_time) |>
      inner_join(data[[2]] |> select(recording_id, task_id, task_duration) |> distinct(), by = c("recording_id" = "recording_id", "task_id" = "task_id")) |>
      filter(!start_s > task_duration) |>
      group_by(location_id, recording_id, task_id, version, species_common_name) |>
      summarise(confidence = max(confidence), .groups="keep") |>
      ungroup() |>
      mutate(classifier = 1)
  } else if(resolution=="minute"){
    detections <- class |>
      mutate(minute = ifelse(detection_time==0, 1, ceiling(detection_time/60))) |>
      group_by(location_id, recording_id, version, species_common_name, minute) |>
      summarise(confidence = max(confidence), .groups="keep") |>
      ungroup() |>
      mutate(classifier = 1)
  } else if(resolution=="recording"){
    detections <- class |>
      group_by(location_id, recording_id, version, species_common_name) |>
      summarise(confidence = max(confidence), .groups="keep") |>
      ungroup() |>
      mutate(classifier = 1)
  } else { stop("A resolution was not specified.")}

  # Tidy up the main report
  if(resolution=="task"){
    main <- wt_tidy_species(data[[2]], remove=c("mammal", "amphibian", "abiotic", "insect", "human", "unknown")) |>
      select(location_id, recording_id, task_id, species_common_name) |>
      unique() |>
      mutate(human = 1)
  } else if(resolution=="minute"){
    main <- wt_tidy_species(data[[2]], remove=c("mammal", "amphibian", "abiotic", "insect", "human", "unknown")) |>
      mutate(minute = ifelse(detection_time==0, 1, ceiling(detection_time/60))) |>
      select(location_id, recording_id, species_common_name, minute) |>
      unique() |>
      mutate(human = 1)
  } else if(resolution=="recording"){
    main <- wt_tidy_species(data[[2]], remove=c("mammal", "amphibian", "abiotic", "insect", "human", "unknown")) |>
      select(location_id, recording_id, species_common_name) |>
      unique() |>
      mutate(human = 1)
  } else {stop("A resolution was not specified.")}

  # Join together
  if (resolution == "minute") {
    both <- full_join(detections, main, by=c("location_id", "recording_id", "species_common_name", "minute")) |>
      mutate(human = ifelse(is.na(human), 0, 1),
             classifier = ifelse(is.na(classifier), 0, 1),
             tp = ifelse(classifier==1 & human==1, 1, 0),
             fp = ifelse(classifier==1 & human==0, 1, 0),
             fn = ifelse(classifier==0 & human==1, 1, 0))
  } else {
    both <- full_join(detections, main, by=c("location_id", "recording_id", "species_common_name")) |>
      mutate(human = ifelse(is.na(human), 0, 1),
             classifier = ifelse(is.na(classifier), 0, 1),
             tp = ifelse(classifier==1 & human==1, 1, 0),
             fp = ifelse(classifier==1 & human==0, 1, 0),
             fn = ifelse(classifier==0 & human==1, 1, 0))
  }

  # Filter to just species of interest if requested
  if(!is.null(species)){
    both <- filter(both, species_common_name %in% species)
  }

  # Total number of human detections
  human_totals <- both |>
    group_by(version) |>
    summarise(human_total = sum(human, na.rm = TRUE)) |>
    ungroup()

  # Make threshold vector
  thresholds_vec <- seq(thresholds[1], thresholds[2], 0.01)

  # Calculate metrics
  prf_combined <- both |>
    left_join(human_totals, by = "version") |>
    filter(!is.na(version)) |>
    group_split(version) |>
    map_dfr(function(df) {map_dfr(thresholds_vec, ~ .wt_calculate_prf(threshold = .x, data = df, human_total = unique(df$human_total))) |>
        mutate(classifier = unique(df$version))
    }) |>
    distinct()
  return(prf_combined)

}

#' Identify optimal threshold
#'
#' @description Retrieves the score threshold that maximizes F-score, which is a trade-off between precision and recall.
#'
#' @param data Tibble output from the `wt_evaluate_classifier()` function.
#'
#' @import dplyr
#' @export
#'
#' @examples
#' \dontrun{
#' data <- wt_download_report(project_id = 1144, sensor_id = "ARU",
#' reports = c("main", "ai"))
#'
#' eval <- wt_evaluate_classifier(data, resolution = "recording",
#' remove_species = TRUE, thresholds = c(10, 99))
#'
#' threshold_use <- wt_classifier_threshold(eval) |> print()
#' }
#'
#' @return A single numeric value

wt_classifier_threshold <- function(data){

  # Filter to highest F-score
  highest_fscore <- data |>
    group_by(classifier) |>
    mutate(fscore = round(fscore, 2)) |>
    filter(fscore == max(fscore, na.rm = TRUE)) |>
    ungroup()

  # Return the highest threshold of highest F-score as a single numeric value
  return(highest_fscore |> group_by(classifier) |> summarise(threshold = max(fscore)) |> distinct())
}


#' Find additional species
#'
#' @description Check for species reported by BirdNET and HawkEars that the human listeners did not detect in our project.
#'
#' @param data Output from the `wt_download_report()` function when you request the `main` and `ai` reports
#' @param remove_species Logical; indicates whether species that are not allowed in the WildTrax project should be removed from the AI report
#' @param threshold Numeric; the desired score threshold
#' @param resolution Character; either "recording" to identify any new species for each recording or "location" to identify new species for each location
#' @param format_to_tags Logical; when TRUE, creates a formatted output to turn detections into tags for uploading to WildTrax
#' @param output Character; when a valid directory is entered, exports the additional detections as tags for sync with a WildTrax project
#'
#' @import dplyr
#' @importFrom readr write_csv
#' @export
#'
#' @examples
#' \dontrun{
#' data <- wt_download_report(project_id = 1144, sensor_id = "ARU",
#' reports = c("main", "ai"))
#'
#' new <- wt_additional_species(data, remove_species = TRUE,
#' threshold = 80, resolution="location")
#' }
#'
#' @return A tibble with the same fields as the `birdnet` report with the highest scoring detection for each new species detection in each recording.

wt_additional_species <- function(data, remove_species = TRUE, threshold = 0.5, resolution="task", format_to_tags = FALSE, output = NULL){

  # Check if the data object is in the right format
  if (!inherits(data, "list") && !grepl("ai", names(data)[[2]]) && !grepl("main", names(data))[[1]]) {
    stop("The input should be the output of the `wt_download_report()` function with the argument `reports=c('main', 'ai')`")
  }

  #Get the classifier report and filter species as requested
  if(remove_species==TRUE){
    class <- data[[1]] |>
      filter(is_species_allowed_in_project==TRUE) |>
      filter(confidence >= threshold)
  } else {
    class <- data[[1]]
  }

  #Summarize the reports and put together at the desired resolution

  if(resolution=="task"){

    #Clean things up
    class <- class |>
      rename(ai_detection_time = detection_time) |>
      inner_join(data[[2]] |> select(recording_id, task_id) |> distinct(), by = "recording_id")

    #Classifier report
    detections <- class |>
      inner_join(data[[2]] |> select(recording_id, task_id, task_duration) |> distinct(), by = c("recording_id" = "recording_id", "task_id" = "task_id")) |>
      filter(!ai_detection_time > task_duration) |>
      group_by(location_id, recording_id, task_id, species_common_name) |>
      summarise(confidence = max(confidence)) |>
      ungroup()

    #Main report
    main <- wt_tidy_species(data[[2]], remove=c("mammal", "amphibian", "abiotic", "insect", "human", "unknown")) |>
      select(location_id, recording_id, task_id, species_common_name) |>
      distinct()

    #Put together
    new <- anti_join(detections, main, by=c("location_id", "recording_id", "task_id", "species_common_name")) |>
      left_join(class, by=c("location_id", "recording_id", "task_id", "species_common_name", "confidence"), multiple="all")
    if (nrow(new) == 0) {
      stop("There were no additional species detected.")
    } else {
      new <- new |>
        group_by(location_id, recording_id,task_id, species_common_name, confidence) |>
        sample_n(1) |>
        ungroup()
    }
  }

  if(resolution=="recording"){

    #Classifier report
    detections <- class |>
      group_by(location_id, recording_id, species_common_name) |>
      summarise(confidence = max(confidence), .groups="keep") |>
      ungroup()

    #Main report
    main <- wt_tidy_species(data[[2]], remove=c("mammal", "amphibian", "abiotic", "insect", "human", "unknown")) |>
      select(location_id, recording_id, species_common_name) |>
      distinct()

    #Put together
    new <- anti_join(detections, main, by=c("location_id", "recording_id", "species_common_name")) |>
      left_join(class, by=c("location_id", "recording_id", "species_common_name", "confidence")) |>
      group_by(location_id, recording_id, species_common_name, confidence) |>
      sample_n(1) |>
      ungroup()

  }

  if(resolution=="location"){

    #Classifier report
    detections <- class |>
      filter(confidence >= threshold) |>
      group_by(location_id, species_common_name) |>
      summarise(confidence = max(confidence),  .groups="keep") |>
      ungroup()

    #Main report
    main <- wt_tidy_species(data[[2]], remove=c("mammal", "amphibian", "abiotic", "insect", "human", "unknown")) |>
      select(location_id, species_common_name) |>
      distinct()

    #Put together
    new <- anti_join(detections, main, by=c("location_id", "species_common_name")) |>
      left_join(class, by=c("location_id", "species_common_name", "confidence"), multiple="all") |>
      group_by(location_id, species_common_name, confidence) |>
      sample_n(1) |>
      ungroup()

  }

  if(resolution=="project"){

    #Classifier report
    detections <- class |>
      filter(confidence >= threshold) |>
      group_by(species_common_name) |>
      summarise(confidence = max(confidence),  .groups="keep") |>
      ungroup()

    #Main report
    main <- wt_tidy_species(data[[2]], remove=c("mammal", "amphibian", "abiotic", "insect", "human", "unknown")) |>
      select(species_common_name) |>
      distinct()

    #Put together
    new <- anti_join(detections, main, by=c("species_common_name")) |>
      left_join(class, by=c("species_common_name", "confidence"), multiple="all") |>
      group_by(species_common_name, confidence) |>
      sample_n(1) |>
      ungroup()

  }

  if(format_to_tags == TRUE){

    if(resolution != "task"){
      message("Currently tag uploads are best supported when you resolve at the task level. You may encounter an error otherwise. If you used `wt_additional_species(resolution='recording')` change the task lengths to the maximum length of the recording in your project")
    }

    new_export <- new |>
      relocate(location) |>
      relocate(recording_date_time, .after = location) |>
      inner_join(data[[2]] |> select(task_id, task_method, task_duration, task_is_complete) |> distinct(), by = "task_id") |>
      relocate(task_duration, .after = recording_date_time) |>
      relocate(task_method, .after = task_duration) |>
      mutate(observer = "Not Assigned", .after = task_method) |>
      relocate(species_code, .after = observer) |>
      group_by(task_id, species_code) |>
      mutate(individual_number = row_number(), .after = species_code) |>
      ungroup() |>
      mutate(vocalization = "SONG", .after = individual_number) |>
      mutate(abundance = 1, .after = vocalization) |>
      rename(tag_start_time = ai_detection_time) |>
      relocate(tag_start_time, .after = abundance) |>
      mutate(tag_duration = "", .after = tag_start_time) |>
      mutate(min_tag_freq = "", .after = tag_duration) |>
      mutate(max_tag_freq = "", .after = min_tag_freq) |>
      mutate(species_individual_comments = paste0(version, " Confidence: ", confidence), .after = max_tag_freq) |>
      mutate(tag_is_hidden_for_verification = FALSE, .after = species_individual_comments) |>
      mutate(recording_sample_frequency = 44100, .after = tag_is_hidden_for_verification) |>
      mutate(internal_tag_id = "", .after = recording_sample_frequency) |>
      select(-c(location_id:task_is_complete))

    return(new_export)

    write_csv(new_export, paste0(output, "/ai_tags.csv"))

  } else {

    return(new)

  }
}
