#' General convenience functions
#'
#' @description Takes input latitude and longitudes and computes the distances between each set of valid points
#'
#' @param input_from_tibble Use a tibble constructed with a distinct list of location names, latitude and longitude
#' @param input_from_file Use a file downloaded from either an organization or project
#'
#' @import dplyr tibble
#' @importFrom sf st_as_sf
#' @importFrom readr read_csv
#' @importFrom tidyr pivot_longer
#' @export
#'
#' @examples
#' \dontrun{
#' df <- wt_location_distances(input = my_location_tibble, input_from_file)
#' }
#'
#' @return A three-column tibble with the distances between each location

wt_location_distances <- function(input_from_tibble = NULL, input_from_file = NULL) {

  if (is.null(input_from_tibble) & is.null(input_from_file)) {
    stop(
      "Please supply either a tibble or a path to the location list.",
      call. = TRUE
    )
  } else if (!is.null(input_from_tibble) & !is.null(input_from_file)) {
    stop("Please only supply one of tibble or file.", call. = TRUE)
  }

  if (is.null(input_from_file)) {
    inp <- input_from_tibble
  } else
    inp <- read_csv(input_from_file)

  l <- nrow(inp)

  locs <- inp |>
    filter(!is.na(latitude) | !is.na(longitude))

  m <- nrow(locs)

  n <- m - l

  if (n > 0) {
    message(n, 'X rows were skipped as they did not contain a latitude or longitude value.')
  } else {
    message('All rows have a latitude and longitude! Creating the matrix...')
  }

  locs <- locs |>
    select(location, latitude, longitude) |>
    distinct() |>
    st_as_sf(coords = c("longitude","latitude"), crs = 4326) |>
    select(location, geometry) |>
    mutate(id = row_number())

  distances <- st_distance(locs, locs)

  location_ids <- locs |>
    as_tibble() |>
    select(location, id) |>
    relocate(id)

  final_distances <- distances |>
    as_tibble() |>
    rownames_to_column(var = "location_from") |>
    pivot_longer(cols = -location_from, names_to = "distance_to", values_to = "distance") |>
    mutate(distance_to = gsub("V", "", distance_to)) |>
    mutate_at(vars(location_from, distance, distance_to), as.numeric) |>
    filter(!distance == 0) |>
    left_join(location_ids, by = c("location_from" = "id")) |>
    left_join(location_ids, by = c("distance_to" = "id")) |>
    select(location.x, location.y, distance) |>
    rename("location_from" = 1) |>
    rename("distance_to" = 2) |>
    select(location_from, distance_to, distance)

  return(final_distances)

}

#' Filter species from a report
#'
#' @description This function filters the species provided in WildTrax reports to only the groups of interest. The groups available for filtering are mammal, bird, amphibian, abiotic, insect, and unknown. Zero-filling functionality is available to ensure all surveys are retained in the dataset if no observations of the group of interest are available.
#'
#' @param data WildTrax main report or tag report from the `wt_download_report()` function.
#' @param remove Character; groups to filter from the report ("mammal", "bird", "amphibian", "abiotic", "insect", "human", "unknown"). Defaults to retaining bird group only.
#' @param zerofill Logical; indicates if zerofilling should be completed. If TRUE, unique surveys with no observations after filtering are added to the dataset with "NONE" as the value for species_code and/or species_common_name. If FALSE, only surveys with observations of the retained groups are returned. Default is TRUE.
#'
#' @import dplyr
#' @export
#'
#' @examples
#' \dontrun{
#' dat.tidy <- wt_tidy_species(dat, remove=c("mammal", "unknown"), zerofill = T)
#' }
#' @return A dataframe identical to input with observations of the specified groups removed.

wt_tidy_species <- function(data,
                            remove = "",
                            zerofill = TRUE) {

  if (is.null(remove)) {
    stop('Not removing any species')
  }

  if (any(!(remove %in% c("mammal", "bird", "amphibian", "abiotic", "insect", "human", "unknown")))) {
    stop("Select remove options from bird, mammal, amphibian, abiotic, insect, human or unknown.")
  }

  #Rename fields if PC
  if("survey_url" %in% colnames(data)){
    data <- data |>
      rename(task_id=survey_id,
             recording_date_time=survey_date)
  }

  if('bird' %in% remove){
    message('Note: By removing birds, you will not be able to use wt_qpad_offsets since QPAD offsets are only available for birds.')
  }

  #Convert to the sql database labels for species class
  remove <- case_when(remove=="mammal" ~ "MAMMALIA",
                      remove=="amphibian" ~ "AMPHIBIA",
                      remove=="abiotic" ~ "ABIOTIC",
                      remove=="insect" ~ "INSECTA",
                      remove=="bird" ~ "AVES",
                      remove=="human" ~ "HUMAN ACTIVITY",
                      remove=="unknown" ~ "unknown",
                      remove=="" ~ remove)

  .species <- wt_get_species()

  #Get the species codes for what you want to filter out
  species.remove <- .species |>
    filter(species_class %in% remove)

  #Add the unknowns if requested
  if("unknown" %in% remove){
    species.remove <- .species %>%
      filter(substr(species_common_name, 1, 12) == "Unidentified") %>%
      rbind(species.remove)
  }

  #Remove those codes from the data
  filtered <- data |>
    filter(!(species_code %in% species.remove$species_code))

  #if you don't need nones, remove other NONEs & return the filtered object
  if(zerofill==FALSE){

    filtered.sp <- filter(filtered, species_code!="NONE")

    #Translate point count field names back
    if("survey_url" %in% colnames(data)){
      filtered.sp <- filtered.sp |>
        rename(survey_id=task_id,
               survey_date = recording_date_time)
    }

    return(filtered.sp)
  }

  #if you do need nones, add them
  if(zerofill==TRUE){

    #first identify the unique visits (task_id) ensure locations are included for proper join
    visit <- data |>
      select(organization, project_id, location, latitude, longitude, location_id, recording_date_time, task_id) |>
      distinct()

    #see if there are any that have been removed
    none <- suppressMessages(anti_join(visit, filtered)) |>
      mutate(species_code = "NONE",
             species_common_name = "NONE",
             species_scientific_name = "NONE")

    #add to the filtered data
    filtered.none <- suppressMessages(full_join(filtered, none)) |>
      arrange(organization, project_id, location, recording_date_time)

    #Translate point count field names back
    if("survey_url" %in% colnames(data)){
      filtered.none <- filtered.none |>
        rename(survey_id=task_id,
               survey_date = recording_date_time)
    }

    #return the filtered object with nones added
    return(filtered.none)

  }

}

#' Replace 'TMTT' abundance with model-predicted values
#'
#' @description This function uses a lookup table of model-predicted values to replace 'TMTT' entries in listener-processed ARU data from WildTrax. The model-predicted values were produced using estimated abundances for 'TMTT' entries in mixed effects model with a Poisson distribution and random effects for species and observer.
#'
#' @param data Dataframe of WildTrax observations, for example the summary report.
#' @param calc Character; method to convert model predictions to integer ("round", "ceiling", or "floor"). See `?round()` for details.
#'
#' @import dplyr
#' @export
#'
#' @examples
#' \dontrun{
#' dat.tmtt <- wt_replace_tmtt(dat, calc="round")
#' }
#' @return A dataframe identical to input with 'TMTT' entries in the abundance column replaced by integer values.

wt_replace_tmtt <- function(data, calc="round"){

  if(!"recording_date_time" %in% colnames(data)){
    stop("The `wt_replace_tmtt` function only works on data from the ARU sensor")
  }

  check_none <- data |>
    select(species_code) |>
    distinct() |>
    pull()

  if (length(check_none) == 1 && check_none == 'NONE') {
    stop('There are no species in this project')
  }

  .tmtt <- readRDS(system.file("extdata", "tmtt_predictions.rds", package="wildrtrax"))

  dat.tmtt <- data |>
    rename(individual_count = abundance) |>
    mutate(id = row_number())

  # only TMTT rows for replacement
  dat.tmt <- dat.tmtt |> filter(individual_count == "TMTT")

  if(nrow(dat.tmt) > 0){
    dat.tmt <- dat.tmt |>
      mutate(
        species_code = ifelse(species_code %in% .tmtt$species_code, species_code, "species"),
        observer_id = as.integer(ifelse(observer_id %in% .tmtt$observer_id, observer_id, 0))
      ) |>
      inner_join(.tmtt |> select(species_code, observer_id, pred),
                 by = c("species_code", "observer_id")) |>
      mutate(
        individual_count = case_when(
          calc == "round"   ~ round(pred),
          calc == "ceiling" ~ ceiling(pred),
          calc == "floor"   ~ floor(pred),
          TRUE ~ NA_real_
        )
      ) |>
      select(-pred)
  }

  # replace TMTT rows with predictions

  dat.tmtt <- dat.tmtt |>
    mutate(individual_count = case_when(individual_count == "TMTT" ~ NA_real_, TRUE ~ as.numeric(individual_count))) |>
    rows_update(dat.tmt, by = c("id")) |>
    select(-id)

  return(dat.tmtt)
}

#' Convert to a wide survey by species dataframe
#'
#' @description This function converts a long-formatted report into a wide survey by species dataframe of abundance values.
#'
#' @param data WildTrax main report or tag report from the `wt_download_report()` function.
#' @param sound Character; vocalization type(s) to retain ("all", "Song", "Call", "Non-vocal"). Can be used to remove certain types of detections. Defaults to "all" (i.e., no filtering).
#'
#' @import dplyr
#' @importFrom tidyr pivot_wider
#' @export
#'
#' @examples
#' \dontrun{
#' dat.tidy <- wt_tidy_species(dat)
#' dat.tmtt <- wt_replace_tmtt(dat.tidy)
#' dat.wide <- wt_make_wide(dat.tmtt, sound="all")
#' }
#' @return A dataframe identical to input with observations of the specified groups removed.

wt_make_wide <- function(data, sound="all"){

  #Steps for ARU data
  if(!"survey_url" %in% colnames(data)){

    #Filter to first detection per individual
    summed <- data |>
      group_by(organization, project_id, location, recording_date_time, task_method, task_is_complete, observer_id, species_code, species_common_name, individual_order) |>
      mutate(first = min(detection_time)) |>
      ungroup() |>
      filter((species_code != "NONE" & detection_time == first) | species_code == "NONE")

    #Remove undesired sound types
    if(!"all" %in% sound){
      sound <- gsub("\\b(\\w)", "\\U\\1", tolower(sound), perl = TRUE)
      summed <- filter(summed, vocalization %in% sound)
    }

    #Make it wide
    wide <- summed |>
      mutate(individual_count = case_when(is.na(individual_count) & species_code == "NONE" ~ "0", grepl("^C",  individual_count) ~ NA_character_, TRUE ~ as.character(individual_count)) |> as.numeric()) |>
      pivot_wider(id_cols = organization:task_method,
                  names_from = "species_code",
                  values_from = "individual_count",
                  values_fn = sum,
                  values_fill = 0,
                  names_sort = TRUE)

  }

  #Steps for point count data
  if("survey_url" %in% colnames(data)){

    #Make it wide and return field names to point count format
    wide <- data |>
      mutate(individual_count = case_when(is.na(individual_count) & species_code == "NONE" ~ "0", grepl("^C",  individual_count) ~ NA_character_, TRUE ~ as.character(individual_count)) |> as.numeric()) |>
      pivot_wider(id_cols = organization:survey_duration_method,
                         names_from = "species_code",
                         values_from = "individual_count",
                         values_fn = sum,
                         values_fill = 0,
                         names_sort = TRUE)

  }

  return(wide)

}

#' Format WildTrax report for occupancy modelling
#'
#' @description This function formats the summary report from the `wt_download_report()` function into an unmarked object for occupancy modelling. The current version only includes formatting for the ARU sensor and for single species single season models.
#'
#' @param data Summary report of WildTrax observations from the `wt_download_report()` function. Currently only functioning for the ARU sensor.
#' @param species Character; four-letter alpha code for the species desired for occupancy modelling.
#' @param siteCovs Optional dataframe of site covariates. Must contain a column with the same values as the location field in the data, with one row per unique value of location (i.e., one row per site).
#'
#' @import dplyr unmarked
#' @importFrom tidyr pivot_wider
#' @export
#'
#' @examples
#' \dontrun{
#' dat.occu <- wt_format_occupancy(dat, species="CONI", siteCovs=NULL)
#' mod <- occu(~ 1 ~ 1, dat.occu)
#' }
#' @return An object of class unmarkedFrameOccu. See `?unmarked::unmarkedFrameOccu` for details.

wt_format_occupancy <- function(data,
                                species,
                                siteCovs=NULL){

  #Rename fields if PC
  if("survey_url" %in% colnames(data)){
    data <- data |>
      rename(task_id=survey_id,
             recording_date_time = survey_date,
             observer_id = observer,
             task_method = survey_duration_method)
  }

  #Wrangle observations and observation covariates for the species of interest
  visits <- data |>
    filter(species_code==species) |>
    select(location, recording_date_time) |>
    distinct() |>
    mutate(occur=1) |>
    right_join(data |>
                 select(location, recording_date_time, observer_id, task_method) |>
                 distinct(),
               by=c("location", "recording_date_time")) |>
    mutate(occur = ifelse(is.na(occur), 0, 1),
                  doy = as.POSIXlt(recording_date_time)$yday + 1,
                  hr = as.numeric(as.numeric(format(recording_date_time, "%H")) + as.numeric(format(recording_date_time, "%M")) / 60)) |>
    group_by(location) |>
    arrange(recording_date_time) |>
    mutate(visit = row_number()) |>
    ungroup()

  #Create location X recording dataframe of observations (1 for detected, 0 for undetected)
  y <- visits |>
    select(location, visit, occur) |>
    pivot_wider(id_cols = location, names_from = visit, values_from = occur) |>
    arrange(location) |>
    select(-location) |>
    data.frame()

  #Create location X recording dataframes for observation covariates (doy = day of year, hr = hour of day, method = processing method, observer = observer ID)
  doy <- visits |>
    select(location, visit, doy) |>
    pivot_wider(id_cols = location, names_from = visit, values_from = doy) |>
    arrange(location) |>
    select(-location) |>
    data.frame()

  doy2 <- visits |>
    mutate(doy2 = doy^2) |>
    select(location, visit, doy2) |>
    pivot_wider(id_cols = location, names_from = visit, values_from = doy2) |>
    arrange(location) |>
    select(-location) |>
    data.frame()

  hr <- visits |>
    select(location, visit, hr) |>
    pivot_wider(id_cols = location, names_from = visit, values_from = hr) |>
    arrange(location) |>
    select(-location) |>
    data.frame()

  hr2 <- visits |>
    mutate(hr2 = hr^2) |>
    select(location, visit, hr2) |>
    pivot_wider(id_cols = location, names_from = visit, values_from = hr2) |>
    arrange(location) |>
    select(-location) |>
    data.frame()

  method <- visits |>
    select(location, visit, task_method) |>
    mutate(task_method = as.factor(task_method)) |>
    pivot_wider(id_cols = location, names_from = visit, values_from = task_method) |>
    arrange(location) |>
    select(-location) |>
    data.frame()

  observer <- visits |>
    select(location, visit, observer_id) |>
    mutate(observer = as.factor(observer_id)) |>
    pivot_wider(id_cols = location, names_from = visit, values_from = observer) |>
    arrange(location) |>
    select(-location) |>
    data.frame()

  #Create a list of the observation covariates
  obsCovs <- list(doy=doy, doy2=doy2, hr=hr, hr2=hr2, observer=observer)

  #Order site covs dataframe if one is provided
  if(!is.null(siteCovs)){

    #Check length of siteCovs object, remove if incorrect
    locs <- length(unique(data$location))

    if(nrow(siteCovs)!=locs){
      siteCovs <- NULL
      warning('Length of siteCovs dataframe does not match observation data')
    }

    else{
      #Arrange by location so that matches the location X recording dataframes
      siteCovs <- siteCovs |>
        arrange(location)
    }
  }

  #Put together as an unmarked object for single species occupancy models
  options(warn=-1)
  if(is.null(siteCovs)){
    umf <- unmarkedFrameOccu(y=y, siteCovs=NULL, obsCovs=obsCovs)
  } else {
    umf <- unmarkedFrameOccu(y=y, siteCovs=siteCovs, obsCovs=obsCovs)
  }
  options(warn=0)

  #return the unmarked object
  return(umf)

}

#' Intersect locations to add a GRTS ID
#'
#' @description This function intersects location data with the GRTS ID provided by [NABat](https://www.nabatmonitoring.org/)
#'
#' @param data Data containing locations
#' @param group_locations_in_cell Option to provide distinct location names if points are found in the same cell. Sequentially provides a number for each GRTS ID e.g. 3-1, 3-2, etc.
#'
#' @import dplyr sf
#' @importFrom tibble as_tibble
#' @importFrom tidyr separate
#' @importFrom readr read_csv
#' @importFrom purrr map_dbl
#' @export
#'
#' @examples
#' \dontrun{
#'
#' dat.grts <- wt_download_report(reports = "location")
#' grts.data <- wt_add_grts(dat.grts)
#' }
#' @return A dataframe with the additional GRTS IDs

wt_add_grts <- function(data, group_locations_in_cell = FALSE) {

  if(!all(c("location","latitude","longitude") %in% names(data))){
    stop('Data must contains columns for location, latitude and longitude')
  }

  if(anyNA(data$latitude) | anyNA(data$longitude)){
    stop('Some latitdues and longitudes are missing. Cannot find GRTS cells without a latitude and longitude.')
  }

  if (any(data$latitude < -90 | data$latitude > 90 | data$longitude < -180 | data$longitude > 180)) {
    stop('Some latitudes or longitudes are not within the correct coordinate system.')
  }

  # Filter things down a bit by bbox so the intersection doesn't take too long
  points_sf <- st_as_sf(data, coords = c("longitude", "latitude"), crs = 4326)
  points_bbox <- st_as_sfc(st_bbox(points_sf))
  bbox_sf <- st_sf(geometry = points_bbox)
  # Define bounding boxes for each region
  bbox_canada <- st_set_crs(st_sf(st_as_sfc(st_bbox(c(xmin = -173.179, ymin = 34.43, xmax = -16.35, ymax = 85.17)), crs = 4326)), 4326)
  bbox_alaska <-  st_set_crs(st_sf(st_as_sfc(st_bbox(c(xmin = -179.99863, ymin = 51.214183, xmax = -129.9795, ymax = 71.538800)), crs = 4326)), 4326)
  bbox_contig <- st_set_crs(st_sf(st_as_sfc(st_bbox(c(xmin = -127.94485, ymin = 22.91700, xmax = -65.26265, ymax = 51.54421)), crs = 4326)), 4326)

  # Initialize an empty list to collect the datasets
  grts_list <- list()

  # Check for intersection eventually
  if (nrow(data) > 0) {
    grts_list[[length(grts_list) + 1]] <- readr::read_csv('https://code.usgs.gov/fort/nabat/nabatr/-/raw/dffbf6afda4d390dbe4d2bf8c51e854b960a33dd/data/GRTS_coords_Canada.csv', show_col_types = FALSE)
  }

  if (nrow(data) > 0) {
    grts_list[[length(grts_list) + 1]] <- readr::read_csv('https://code.usgs.gov/fort/nabat/nabatr/-/raw/dffbf6afda4d390dbe4d2bf8c51e854b960a33dd/data/GRTS_coords_Alaska.csv', show_col_types = FALSE)
  }

  # Check for intersection with contiguous US
  if (nrow(data) > 0) {
    grts_list[[length(grts_list) + 1]] <- readr::read_csv('https://code.usgs.gov/fort/nabat/nabatr/-/raw/dffbf6afda4d390dbe4d2bf8c51e854b960a33dd/data/GRTS_coords_CONUS.csv', show_col_types = FALSE)
  }

  # If any datasets were downloaded, bind them together
  if (length(grts_list) > 0) {
    grts_chosen <- bind_rows(grts_list)
  } else {
    stop('No overlaps could be found with this data.')
    grts_chosen <- NULL
  }

  # Optional: Check if grts_chosen is NULL before proceeding
  if (is.null(grts_chosen)) {
    stop('No intersected data to proceed with.')
  }

  # Convert grid cells to sf polygons
  grid_cells_sf <- grts_chosen |>
    separate(lowerleft, into = c("lowerleft_lat", "lowerleft_lon"), sep = ",", convert = TRUE) |>
    separate(upperleft, into = c("upperleft_lat", "upperleft_lon"), sep = ",", convert = TRUE) |>
    separate(upperright, into = c("upperright_lat", "upperright_lon"), sep = ",", convert = TRUE) |>
    separate(lowerright, into = c("lowerright_lat", "lowerright_lon"), sep = ",", convert = TRUE) |>
    separate(center, into = c("center_lat", "center_lon"), sep = ",", convert = TRUE) |>
    rowwise() |>
    mutate(geometry = list(st_polygon(list(matrix(c(lowerleft_lon, lowerleft_lat, upperleft_lon, upperleft_lat, upperright_lon, upperright_lat, lowerright_lon, lowerright_lat, lowerleft_lon, lowerleft_lat), ncol = 2, byrow = TRUE))))) |>
    ungroup() |>
    st_as_sf(crs = 4326) |>
    select(GRTS_ID, geometry)

  # If CRS are different, transform bbox_sf to match the CRS of grid_cells_sf
  if (!identical(st_crs(grid_cells_sf), st_crs(bbox_sf))) {
    bbox_sf <- st_transform(st_make_valid(bbox_sf), st_crs(st_make_valid(grid_cells_sf)))
  }

  grid_cells_filtered <- grid_cells_sf |> suppressWarnings(st_intersection(bbox_sf))

  # Perform spatial join to find which polygon each point falls into
  if(nrow(grid_cells_filtered) == 0){
    stop('There are no grid cells that intersect the points')
  } else {
    result <- suppressWarnings(st_join(points_sf, grid_cells_filtered, join = st_within))
  }

  # Convert back to tibble and select relevant columns
  new_data <- result |>
    as_tibble() |>
    relocate(GRTS_ID, .after = location) |>
    st_drop_geometry() |>
    mutate(longitude = map_dbl(geometry, 1),
           latitude  = map_dbl(geometry, 2)) |>
    relocate(latitude, .after = GRTS_ID) |>
    relocate(longitude, .after = latitude) |>
    select(-geometry)

  if (group_locations_in_cell == TRUE) {
    new_data2 <- new_data |>
      group_by(GRTS_ID) |>
      mutate(GRTS_suffix = paste0(GRTS_ID, "-", row_number())) |>
      ungroup() |>
      relocate(GRTS_suffix, .after = GRTS_ID)

    return(new_data2)
  } else {
    return(new_data)
  }
}

#' Format data for a specified portal
#'
#' @description This function takes the WildTrax reports and converts them to the desired format
#' `r lifecycle::badge("experimental")`
#'
#' @param input A report from `wt_download_report()`
#' @param format A format i.e. 'FWMIS' or 'NABAT'
#'
#' @import dplyr httr2
#' @export
#'
#' @examples
#' \dontrun{
#'
#' dat <- wt_download_report(reports = c("main","visit","equipment")) |>
#' wt_format_data(format = 'FWMIS')
#' }
#' @return A tibble with the formatted report

wt_format_data <- function(input, format = c('FWMIS','NABAT')){

  ## User agent
  u <- .gen_ua()

  spp_fwmis <- request("https://www-api.wildtrax.ca") |>
    req_url_path_append("/bis/get-species-fwmis-map") |>
    req_headers(
      Authorization = paste("Bearer", ._wt_auth_env_$access_token),
      Pragma = "no-cache",
      Referer = "https://www.wildtrax.ca/"
    ) |>
    req_user_agent(u) |>
    req_perform() |>
    resp_body_json()

  # spps <- httr::content(spp_fwmis)
  spps_tibble <- map_dfr(spp_fwmis, ~ tibble(species_id = .x$sfw_species_id, sfw_name = .x$sfw_name, sfw_name_cam = .x$sfw_name_cam)) |>
    inner_join(wt_get_species() |> select(species_id, species_common_name), by = ("species_id"))

    return(spps_tibble)
  }

#' Get EXIF metadata from images
#'
#' @description This function gets all relevant EXIF metadata from images in Projects
#' `r lifecycle::badge("experimental")`
#'
#' @param data `wt_download_report(reports = c(image_report))` object containing
#'
#' @import dplyr httr2
#' @importFrom tidyr unnest_wider
#' @importFrom purrr map
#' @export
#'
#' @examples
#' \dontrun{
#'
#' dat <- wt_download_report(reports = c("image_report"))
#' exif.data <- wt_get_exif(dat)
#' }
#' @return A dataframe with the EXIF metadata for each image

wt_get_exif <- function(data) {

  # Check if authentication has expired:
  if (.wt_auth_expired())
    stop("Please authenticate with wt_auth().", call. = FALSE)

  input_data <- data

  all_images <- input_data |>
    select(image_id) |>
    distinct() |>
    mutate(
      exif = map(
        image_id,
        ~ tryCatch(
          {
            request("https://www-api.wildtrax.ca") |>
              req_url_path_append("bis", "camera", "get-image-exif") |>
              req_url_query(imageId = .x) |>
              req_headers(
                Authorization = paste("Bearer", ._wt_auth_env_$access_token)
              ) |>
              req_user_agent(.gen_ua()) |>
              req_timeout(300) |>
              req_perform() |>
              resp_body_json()
          },
          error = function(e) {"Failed to retrieve EXIF for image_id { .x }"})))
    #tidyr::unnest_wider(exif)

  return(all_images)

}

#' Get QPAD offsets
#'
#' @description This function calculates statistical offsets that account for survey-specific and species-specific variation in availability for detection and perceptibility of birds. This function requires download of the `QPAD` R package and should be used on the output of the `wt_make_wide()` function
#'
#' @param data Dataframe output from the `wt_make_wide()` function.
#' @param species Character; species for offset calculation. Can be a list of 4-letter AOU codes (e.g., c("TEWA", "OSFL", "OVEN")) or "all" to calculate offsets for every species in the input dataframe for which offsets are available. Defaults to "all".
#' @param version Numeric; version of QPAD offsets to use (2, or 3). Defaults to 3.
#' @param together Logical; whether or not offsets should be bound to the input dataframe or returned as a separate object.
#'
#' @references Solymos et al. 2013. Calibrating indices of avian density from non-standardized survey data: making the most of a messy situation. Methods in Ecology and Evolution, 4, 1047-1058.
#'
#' @import dplyr
#' @export
#'
#' @examples
#' \dontrun{
#' remotes::install_github("borealbirds/QPAD")
#'
#' dat.clean <- wt_tidy_species(dat)
#' dat.tmtt <- wt_replace_tmtt(dat.clean)
#' dat.wide <- wt_make_wide(dat.tmtt, sound="all")
#' dat.qpad <- wt_qpad_offsets(dat.wide, species="all", version=3, together = TRUE)
#' }
#' @return A dataframe containing the QPAD values either by themselves or with the original wide data if `together = TRUE`

wt_qpad_offsets <- function(data, species = c("all"), version = 3, together=FALSE) {

  if(!requireNamespace("QPAD")) {
    stop("The QPAD package is required for this function. Please install it using remotes::install_github('borealbirds/QPAD')")
  }

  # Rename fields if PC
  if ("survey_url" %in% colnames(data)) {
    data <- data |>
      rename(task_id = survey_id,
             recording_date_time = survey_date,
             observer_id = observer) |>
      rowwise() |>
      mutate(durationMethod = ifelse(substr(survey_duration_method, nchar(survey_duration_method), nchar(survey_duration_method)) == "+",
                                     substr(survey_duration_method, 1, nchar(survey_duration_method) - 2),
                                     survey_duration_method),
             chardur = gregexpr("-", durationMethod, fixed = TRUE),
             chardurmax = max(unlist(chardur)),
             task_duration = as.numeric(substr(durationMethod, chardurmax + 1, nchar(durationMethod) - 3)) * 60,
             chardis = gregexpr("-", survey_distance_method, fixed = TRUE),
             chardismax = max(unlist(chardis)),
             distance1 = substr(survey_distance_method, chardismax + 1, nchar(survey_distance_method) - 1),
             task_distance = ifelse(distance1 %in% c("AR", "IN"), Inf, as.numeric(distance1))) |>
      ungroup()
  }

  #Load QPAD estimates
  cat("\nLoading QPAD estimates... ")
  load_BAM_QPAD <- get("load_BAM_QPAD",  envir = asNamespace("QPAD"))
  load_BAM_QPAD(version)

  #Make prediction object
  cat("Extracting covariates for offset calculation. This may take a moment.")
  x <- .make_x(data)

  #Make the species list
  if("all" %in% species) spp <- sort(intersect(getBAMspecieslist(), colnames(data))) else spp <- species

  #Set up the offset loop
  cat("\nCalculating offsets...")
  off <- matrix(0, nrow(x), length(spp))
  colnames(off) <- spp

  #Make the offsets
  for (i in 1:length(spp)){
    cat("\n", spp[i])
    o <- .make_off(spp[i], x)
    off[,i] <- o$offset
  }

  #Return output as dataframe if separate output requested
  if(together==FALSE){
    return(data.frame(off))
  }

  #Put together if requested
  if(together==TRUE){
    out <- cbind(data,
                 data.frame(off) |>
                   rename_with(.fn=~paste0(.x, ".off")))

    #Translate point count field names back
    if("survey_url" %in% colnames(data)){
      out <- out |>
        rename(survey_id=task_id,
               survey_date = recording_date_time,
               observer = observer_id) |>
        select(-durationMethod, -chardur, -chardurmax, -task_duration, -chardis, -chardismax, -distance1, -task_distance)
    }

    return(out)
  }

  cat("\nDone!")

}
