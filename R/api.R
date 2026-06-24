#' Authenticate into WildTrax
#'
#' @description Obtain Auth0 credentials using WT_USERNAME and WT_PASSWORD stored as environment variables
#'
#' @param force Logical; whether or not the force re-authentication even if token has not expired. Defaults to FALSE.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Authenticate first:
#' wt_auth(force = FALSE)
#' }
#'

wt_auth <- function(force = FALSE) {

  if (!exists("._wt_auth_env_"))
    stop("Cannot find the correct environment.", call. = TRUE)

  if (force || .wt_auth_expired())
    .wt_auth()

  invisible(NULL)

}

#' Get data from WildTrax syncs and downloads
#'
#' @description Fetch data for syncs and downloads in WildTrax. You must specify at least one of `project` or `organization` depending on the API
#'
#' @param api A string specifying the API to query. Must be one of:
#' \itemize{
#'   \item `"organization_locations"`
#'   \item `"organization_visits"`
#'   \item `"organization_equipment`"
#'   \item `"organization_deployments`"
#'   \item `"organization_recordings`"
#'   \item `"project_locations"`
#'   \item `"project_aru_tasks"`
#'   \item `"project_aru_tags"`
#'   \item `"project_image_metadata"`
#'   \item `"project_image_sets`
#'   \item `"project_camera_tags"`
#'   \item `"project_point_counts"`
#' }
#' @param project Numeric; The project id
#' @param organization Numeric; The organization id
#' @param max_seconds Numeric; Number of seconds to force to wait for downloads.
#'
#' @import httr2 dplyr
#' @importFrom readr read_csv cols
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Authenticate first:
#' wt_auth()
#'
#' # Fetch locations by organization
#' wt_get_sync("organization_locations", organization = 5)
#'
#' # Fetch locations by project
#' wt_get_sync("project_locations", project = 620)
#' }
#'
#' @return A tibble with column headers for the specified API call.

wt_get_sync <- function(api, project = NULL, organization = NULL, max_seconds = 300) {

  if (is.null(api) || api == "") stop("The 'api' field is required.", call. = FALSE)

  api_pseudonyms <- list(
    organization_locations   = "download-location-by-org-id",
    organization_visits      = "download-location-visits-by-org-id",
    organization_equipment   = "download-equipment-by-org-id",
    organization_deployments = "download-location-equipment-by-organization-id",
    organization_recordings  = "download-recordings-by-org-id",
    project_locations        = "download-location",
    project_aru_tasks        = "download-tasks-by-project-id",
    project_aru_tags         = "download-tags-by-project-id",
    project_image_metadata   = "download-camera-tasks-by-project-id",
    project_image_sets       = "download-image-set-by-project-id",
    project_camera_tags      = "download-camera-tags-by-project-id",
    project_point_counts     = "download-point-count-by-project-id"
  )

  api_key <- api_pseudonyms[[api]] %||% api
  api_path <- paste0("/bis/", api_key)

  query_param <- if (!is.null(organization)) {
    list(orgId = .get_org_id(organization))
  } else if (!is.null(project)) {
    list(projectId = project)
  } else {
    stop("Either 'project' or 'organization' must be provided.", call. = FALSE)
  }

  message("Calling... ", api_path)
  tmp <- tempfile(fileext = ".csv")

  .wt_api_pr(api_path, query_param, max_time = max_seconds, out_path = tmp)

  col_spec <- if (api == "project_image_metadata") cols(image_comments = col_character()) else readr::cols()
  read_csv(tmp, col_types = col_spec, show_col_types = FALSE)

}
