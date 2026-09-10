#' Summarise camera data
#'
#' @description This function takes your independent detection data and summarises it by location, specified time interval, and species.
#'
#' @param detect_data Detection data generated from `wt_ind_det()`.
#' @param raw_data The raw camera tag data, which is used to infer the effort (i.e. date ranges of operation) for each camera. Optionally, can supply effort_data directly instead.
#' @param time_interval Character; Can be either "full", "month", "week", or "day" (default).
#' @param variable Character; Can be either "detections" (default), "presence", "counts", or "all" (if you want all three).
#' @param output_format Character; The format of the dataframe returned to you. Can be either "wide" (default) or "long".
#' @param species_col Defaults to `species_common_name`. The column referring to species. Use to switch between common and scientific names of species, if you have both.
#' @param effort_data Optionally supply your own effort data.
#' @param exclude_out_of_range Logical; Remove days from effort when camera field-of-view is obscured.
#' @param project_col Defaults to `project_id`. The column referring to project in your effort data.
#' @param station_col Defaults to `location`. The column referring to each individual camera station/location in your effort data.
#' @param date_time_col Defaults to `image_date_time`. The column referring to image date-time stamp.
#' @param start_col Defaults to `start_date`. The column indicating the start date of the camera location
#' @param end_col Defaults to `end_date`. The column indicating the end date of the camera location
#' @param detection_id_col Defaults to `detection`. The column indicating the detection id
#' @param start_col_det Defaults to `start_time`. The column indicating the start time of the independent detections
#' @param image_set_id Defaults to `image_set_id`.
#'
#' @import dplyr
#' @importFrom tidyr pivot_longer pivot_wider unnest crossing replace_na drop_na
#' @export
#'
#' @examples
#' \dontrun{
#' summary <- wt_summarise_cam(
#' x, y, time_interval = "day", variable = "detections", output_format = "wide"
#' )
#' }
#'
#' @return A dataframe summarising your camera data by location, time interval, and species.

wt_summarise_cam <- function(detect_data, raw_data, time_interval = "day",
                             variable = "detections", output_format = "wide",
                             species_col = species_common_name, effort_data = NULL,
                             exclude_out_of_range = FALSE,
                             project_col = project_id, station_col = location,
                             date_time_col = image_date_time,
                             start_col = start_date, end_col = end_date,
                             detection_id_col = detection,
                             start_col_det = start_time,
                             image_set_id = image_set_id) {

  # Check that only one is supplied
  if (!missing(raw_data) && !is.null(effort_data)) {
    stop("Please only supply a value for one of `raw_data` or `effort_data`.")
  }

  all_vars <- c("detections", "counts", "presence")
  if (length(variable) == 1 &&
      variable %in% c("detections", "counts", "presence", "all")) {
    if (variable == "all") {
      variable <- all_vars
    }
  } else {
    stop("Variable must be one of 'detections', 'counts', 'presence', 'all'.")
  }

  # Todo - check that supplied data contains all necessary columns

  # Check timeframe variable
  int <- c("day", "week", "month", "full")
  if (!time_interval %in% int) {
    stop("Please select a valid time interval: 'day', 'week', 'month', or 'full'.")
  }

  # Check output format
  formats <- c("wide", "long")
  if (!output_format %in% formats) {
    message("Please specify `wide` or `long` in the output_format argument.")
  }

  # Parse the raw or effort data to get time ranges for each camera deployment.
  if (!missing(raw_data)) {

    if (exclude_out_of_range == FALSE) {

      x <- raw_data |>
        group_by({{ project_col }}, {{ station_col }}, {{ image_set_id }}) |>
        summarise(start_date = as.Date(min({{ date_time_col }}, na.rm = TRUE)),
                  end_date   = as.Date(max({{ date_time_col }}, na.rm = TRUE))) |>
        ungroup()

    } else {

      x <- raw_data |>
        arrange({{ project_col }}, {{ station_col }}, {{ image_set_id }}, {{ date_time_col }}) |>
        group_by({{ project_col }}, {{ station_col }}, {{ image_set_id }}) |>
        arrange({{ date_time_col }}) |>
        mutate(cam_ok = is.na(image_fov) | image_fov == "",
               period = cumsum(cam_ok != lag(cam_ok, default = first(cam_ok))) + 1) |>
        filter(cam_ok) |>
        group_by({{ project_col }},  {{ station_col }}, {{ image_set_id }}, period) |>
        summarise(start_date = as.Date(min({{ date_time_col }}, na.rm = TRUE)),
                  end_date   = as.Date(max({{ date_time_col }}, na.rm = TRUE))) |>
        ungroup()

    }

    if (any(c(is.na(x$start_date), is.na(x$end_date)))) {
      message("Parsing of image date time produced NAs, these will be dropped")
      x <- drop_na(x)
    }

    if (nrow(x) == 0) {
      stop("The remaining images in the dataset were all out of the field of view.")
    }

    x <- x |>
      mutate(day = map2(start_date, end_date, ~ seq.Date(.x, .y, by = "day"))) |>
      unnest(day) |>
      distinct({{ project_col }}, {{ station_col }}, {{ image_set_id }}, day) |>
      mutate(year = as.integer(format(day, "%Y"))) |>
      select({{ project_col }}, {{ station_col }}, {{ image_set_id }}, year, day)

  } else {

    # Create x with just effort data (assume raw data is missing)
    x <- effort_data |>
      select(project = {{ project_col }},
             location = {{ station_col }},
             start_date = {{ start_col }},
             end_date = {{ end_col }}) |>
      ungroup()

  }

  # Based on the desired timeframe, assess when each detection occurred
  if (time_interval == "day" | time_interval == "full") {
    y <- detect_data |>
      mutate(year = as.integer(format({{ start_col_det }}, "%Y")),
             day = as.Date({{ start_col_det }}))
    grouping_cols <- c("year", "day")
  } else if (time_interval == "week") {
    y <- detect_data |>
      mutate(year = as.integer(format({{ start_col_det }}, "%G")),
             week = as.integer(format({{ start_col_det }}, "%V")))
    grouping_cols <- c("year", "week")
  } else if (time_interval == "month") {
    y <- detect_data |>
      mutate(year = as.integer(format({{ start_col_det }}, "%Y")),
             month = format({{ start_col_det }}, "%B"))
    grouping_cols <- c("year", "month")
  }

  # Summarise variable of interest
  y <- y |>
    group_by({{ project_col }}, {{ station_col }}, {{ species_col }}, across(all_of(grouping_cols))) |>
    summarise(detections = n(),
              counts = sum(max_animals, na.rm = TRUE)) |>
    ungroup() |>
    mutate(presence = ifelse(detections > 0, 1, 0))

  # Species present in the data
  sp <- y |> select({{ species_col }}) |> distinct()

  # Create long df object of all species x location x timeframe combos
  if (time_interval == "day") {
    z <- x |>
      mutate(n_days_effort = 1) |>
      crossing(sp) |>
      left_join(y) |>
      mutate(across(all_vars, ~ replace_na(.x, 0)))

  } else if (time_interval == "week") {
    x <- x |>
      mutate(year = as.integer(strftime(day, "%G")),
             week = as.integer(strftime(day, "%V"))) |>
      group_by({{ project_col }}, {{ station_col }}, year, week) |>
      summarise(n_days_effort = n_distinct(day)) |>
      ungroup()
    z <- x |>
      crossing(sp) |>
      left_join(y) |>
      mutate(across(all_vars, ~ replace_na(.x, 0)))

  } else if (time_interval == "month") {
    x <- x |>
      mutate(month = format(day, "%B")) |>
      group_by({{ project_col }}, {{ station_col }}, year, month) |>
      summarise(n_days_effort = n_distinct(day)) |>
      ungroup()
    z <- x |>
      crossing(sp) |>
      left_join(y) |>
      mutate(across(all_vars, ~ replace_na(.x, 0)))

  } else if (time_interval == "full") {

    z <- x |>
      crossing(sp) |>
      left_join(y) |>
      mutate(across(all_vars, ~ replace_na(.x, 0))) |>
      group_by({{ project_col }}, {{ station_col }}, year) |>
      mutate(n_days_effort = as.integer(max(day) - min(day)) + 1) |>
      group_by({{ project_col }}, {{ station_col }}, year, {{ species_col }}) |>
      summarise(detections = sum(detections),
                counts = sum(counts),
                presence = ifelse(any(presence == 1), 1, 0),
                n_days_effort = first(n_days_effort)) |>
      ungroup() |>
      mutate(time_interval = "full")
  }

  # Make wide if desired, using
  if (output_format == "wide") {
    z <- z |>
      pivot_wider(id_cols = c({{ project_col }}, {{ station_col }}, year, time_interval, n_days_effort),
                  names_from = {{ species_col }},
                  values_from = {{ variable }},
                  names_sep = ".") |>
      unnest(everything())
  } else if (output_format == "long") {
    z <- z |>
      select({{ project_col }}, {{ station_col }}, year, time_interval, n_days_effort, {{ species_col }}, {{ variable }}) |>
      pivot_longer(cols = {{ variable }}, names_to = "variable", values_to = "value")
  }

  return(z)
}

#' Evaluate independent camera detections
#'
#' @description Create an independent detections dataframe using camera data from WildTrax
#'
#' @param x A dataframe of camera data; preferably, the main report from `wt_download_report()`.
#' @param threshold Numeric; time interval to parse out independent detections.
#' @param units The threshold unit. Can be one of three values, "seconds", "minutes", "hours".
#' @param datetime_col Defaults to `image_date_time`; The column indicating the timestamp of the image.
#' @param remove_human Logical; Should human and human-related tags (e.g. vehicles) be removed? Defaults to TRUE.
#' @param remove_domestic Logical; Should domestic animal tags (e.g. cows) be removed? Defaults to TRUE.
#'
#' @import dplyr
#' @export
#'
#' @examples
#' \dontrun{
#' detections <- wt_ind_detect(x = df, threshold = 30, units = "minutes")
#' }
#'
#' @return A dataframe of independent detections in your camera data, based on the threshold you specified. The df will include information about the duration of each detection, the number of images, the average number of individual animals per image, and the max number of animals in the detection.

wt_ind_detect <- function(x, threshold, units = "minutes", datetime_col = image_date_time, remove_human = TRUE, remove_domestic = TRUE) {

  # Check that x is a dataframe
  if (!is.data.frame(x)) {
    stop("The first argument must supply a dataframe.")
  }

  # Ensure that datetime_col is of class POSIXct; if not, try to convert.
  name <- enquo(datetime_col) |> quo_name()
  if (!inherits(x[[name]], c("POSIXct"))) {
    x <- x |> mutate({{ datetime_col }} := as.POSIXct({{ datetime_col }}, format = "%Y-%m-%d %H:%M:%S", tz = "UTC"))
    message("Your datetime_col has been converted to a POSIXct DateTime.")
  }
  # Check if x contains the required columns - standard output from WildTrax. Probably should make this more flexible.
  req_cols <- c("project_id", "location", "species_common_name", "individual_count")
  if (!all(req_cols %in% colnames(x))) {
    stop("Important columns are missing from the data you have supplied. All of `project_id`, `location`, `species_common_name`, and `individual_count` are required.")
  }

  # Check that the units argument is either seconds, minutes, or hours
  if (!units %in% c("seconds", "minutes", "hours")) {
    stop("Please use 'seconds', 'minutes', or 'hours' as your threshold unit.")
  }

  # Convert threshold to seconds
  if (units == "minutes") {
    threshold <- threshold  * 60
  } else if (units == "hours") {
    threshold <- threshold * 60 * 60
  } else {
    threshold
  }

  # Tags to discard
  t <- c("NONE", "STAFF/SETUP", "UNKNOWN")
  if (remove_human) {
    # Standard WildTrax tags that refer to human(ish) objects
    t <- c(t, "Human", "Vehicle", "Unknown Vehicle", "All Terrain Vehicle", "Train", "Heavy Equipment")
  }
  # Filter out unwanted tags, including NAs
  x <- x |>
    filter(!species_common_name %in% t, !is.na(species_common_name))
  if (remove_domestic) {
    # All tags in WildTrax that refer to domestic animals begin with 'Domestic __'
    x <- filter(x, !grepl("^Domestic", species_common_name))
  }

  # Amalgamate tags of same species in same image; currently broken into two separate rows
  x1 <- x |>
    # Sometimes VNA sneaks in here
    mutate(individual_count = as.numeric(ifelse(individual_count == "VNA", 1, individual_count))) |>
    # Use image_id because sometimes {{datetime_col}} is same for 2 images
    group_by(location, image_id, species_common_name) |>
    mutate(individual_count = sum(individual_count)) |>
    distinct(location, {{ datetime_col }}, species_common_name, individual_count, .keep_all = TRUE) |>
    ungroup()

  # Determine independent detections by species in loop;
  # Done this way so that detections of different species do not reset the timer on one another
  species <- unique(x1$species_common_name)

  # Set up list to store results
  detections <- list()

  for (sp in species) {

    x2 <- x1 |>
      filter(species_common_name == sp) |>
      # Order the dataframe
      arrange(project_id, location, {{ datetime_col }}, species_common_name) |>
      group_by(project_id, location, species_common_name) |>
      # Calculate the time difference between subsequent images
      mutate(interval = as.numeric(difftime({{ datetime_col }}, lag({{ datetime_col }}), units = "secs"))) |>
      # Is this considered a new detection?
      mutate(new_detection = ifelse(is.na(interval) | abs(interval) >= threshold, TRUE, FALSE)) |>
      ungroup() |>
      # Number the independent detections
      mutate(detection = c(1, cumsum(new_detection[-1]) + 1)) |>
      ungroup()

    detections[[sp]] <- x2

  }

  # Summarise detections
  x3 <- bind_rows(detections) |>
    group_by(detection, project_id, location, species_common_name) |>
    summarise(start_time = min({{ datetime_col }}),
              end_time = max({{ datetime_col }}),
              total_duration_seconds = as.numeric(difftime(end_time, start_time, units = "secs")),
              n_images = n(),
              avg_animals_per_image = mean(individual_count),
              max_animals = max(individual_count)) |>
    ungroup() |>
    # Rename detection so that it is clear which species it belongs to
    mutate(detection = paste0(species_common_name, " ", detection))

  # Return x3
  return(x3)

}
