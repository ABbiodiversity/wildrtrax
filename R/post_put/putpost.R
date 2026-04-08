put_location <- function(
    name,
    organization_id,
    latitude = NULL,
    longitude = NULL,
    visibility_id = 2,
    is_true_coordinates = TRUE
) {

  body <- list(
    name = name,
    organizationId = organization_id,
    latitude = latitude,
    longitude = longitude,
    visibilityId = visibility_id,
    isTrueCoordinates = is_true_coordinates
  )

  res <- request("https://www-api.wildtrax.ca") |>
    req_url_path_append("bis/insert-update-location") |>
    req_headers(
      Authorization = paste("Bearer", wildrtrax:::._wt_auth_env_$access_token),
      `Content-Type` = "application/json"
    ) |>
    req_user_agent(wildrtrax:::.gen_ua()) |>
    req_method("POST") |>
    req_body_json(body, auto_unbox = TRUE) |>
    req_perform()

  out <- resp_body_json(res, simplifyVector = TRUE)

  # replace NULL with NA
  out <- lapply(out, function(x) if (is.null(x)) NA else x)

  tibble::as_tibble(out)
}

put_location_visit <- function(
    location_id,
    date,
    land_features = list(),
    bait_id = 0
) {

  body <- list(
    date = as.character(date),
    locationId = location_id,
    landFeatures = land_features,
    baitId = bait_id
  )

  res <- request("https://www-api.wildtrax.ca") |>
    req_url_path_append("bis/insert-update-location-visit") |>
    req_headers(
      Authorization = paste("Bearer", wildrtrax:::._wt_auth_env_$access_token),
      `Content-Type` = "application/json"
    ) |>
    req_user_agent(wildrtrax:::.gen_ua()) |>
    req_method("POST") |>
    req_body_json(body, auto_unbox = TRUE) |>
    req_perform()

  out <- resp_body_json(res, simplifyVector = TRUE)

  # replace NULLs with NA
  out <- lapply(out, function(x) if (is.null(x)) NA else x)

  tibble::as_tibble(out)
}

put_deployment <- function(
    equipment_id,
    deploy_visit_id,
    location_id,
    organization_id,
    time_lapse_enabled = TRUE,
    triggers_enabled = TRUE,
    child_equipment = list()
) {

  body <- list(
    timeLapseEnabled = time_lapse_enabled,
    triggersEnabled = triggers_enabled,
    childEquipment = child_equipment,
    equipmentId = equipment_id,
    deployVisitId = deploy_visit_id,
    locationId = location_id,
    organizationId = organization_id
  )

  res <- request("https://www-api.wildtrax.ca") |>
    req_url_path_append("bis/insert-update-location-equipment") |>
    req_headers(
      Authorization = paste("Bearer", wildrtrax:::._wt_auth_env_$access_token),
      `Content-Type` = "application/json"
    ) |>
    req_user_agent(wildrtrax:::.gen_ua()) |>
    req_method("POST") |>
    req_body_json(body, auto_unbox = TRUE) |>
    req_perform()

  out <- resp_body_json(res, simplifyVector = TRUE)

  out <- lapply(out, function(x) if (is.null(x)) NA else x)

  tibble::as_tibble(out)
}
