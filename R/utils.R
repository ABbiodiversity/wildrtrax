#' Generate user agent
#'
#' @description Generic function to to encapsulate user agents
#'
#' @keywords internal

.gen_ua <- function() {
  user_agent <- getOption("HTTPUserAgent")
  if (is.null(user_agent)) {
    user_agent <- sprintf("R/%s; R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os))
  }
  user_agent <- paste0("wildrtrax ", as.character(packageVersion("wildrtrax")), "; ", user_agent)
  return(user_agent)
}

#' Internal functions
#'
#' WildTrax authentication
#'
#' @description Get Auth0 token and assign information to the hidden environment
#'
#' @keywords internal
#'
#' @import httr2

.wt_auth <- function() {

  # ABMI Auth0 client ID
  cid <- rawToChar(
    as.raw(c(0x45, 0x67, 0x32, 0x4d, 0x50, 0x56, 0x74, 0x71, 0x6b,
             0x66, 0x33, 0x53, 0x75, 0x4b, 0x53, 0x35, 0x75, 0x58, 0x7a, 0x50,
             0x39, 0x37, 0x6e, 0x78, 0x55, 0x31, 0x33, 0x5a, 0x32, 0x4b, 0x31,
             0x69)))

  # Initialize request to Auth0
  req <-  request("https://abmi.auth0.com/")

  if (Sys.getenv("WT_USERNAME") == "" || Sys.getenv("WT_PASSWORD") == "") {
    stop(
      "Environment variables are not set:\n",
      " - WT_USERNAME: ", ifelse(Sys.getenv("WT_USERNAME") == "", "MISSING", "SET"), "\n",
      " - WT_PASSWORD: ", ifelse(Sys.getenv("WT_PASSWORD") == "", "MISSING", "SET"), "\n",
      "Please set these variables using Sys.setenv() or add them to your .Renviron file."
    )
  }

  r <- req |>
    req_url_path("oauth/token") |>
    req_body_form(
      audience = "http://www.wildtrax.ca",
      grant_type = "password",
      client_id = cid,
      username = Sys.getenv("WT_USERNAME"),
      password = Sys.getenv("WT_PASSWORD")
    ) |>
    req_error(is_error = function(resp) FALSE) |>
    req_perform()

  # Check for authentication errors
  if (resp_is_error(r)) {
    stop(sprintf(
      "Authentication failed [%s]\n%s",
      resp_status(r),
      resp_body_json(r)$error_description
    ),
    call. = FALSE)
  }

  # Parse the JSON response
  x <- resp_body_json(r)

  # Calculate token expiry time
  t0 <- Sys.time()
  x$expiry_time <- t0 + x$expires_in

  # Check if the authentication environment exists
  if (!exists("._wt_auth_env_")) {
    stop("Cannot find the correct environment.", call. = FALSE)
  }

  # Send the token information to the ._wt_auth_env_ environment
  list2env(x, envir = ._wt_auth_env_)

  message("Authentication into WildTrax successful.")

  invisible(NULL)

}

#' Internal function to check if Auth0 token has expired
#'
#' @description Check if the Auth0 token has expired
#'
#' @keywords internal
#'

.wt_auth_expired <- function () {

  if (!exists("._wt_auth_env_"))
    stop("Cannot find the correct environment.", call. = TRUE)

  if (is.null(._wt_auth_env_$expiry_time))
    return(TRUE)

  ._wt_auth_env_$expiry_time <= Sys.time()
}

#' Define classes
#'
#' @description Internal helper that assigns one of four classes, ARU,
#'   camera, point count, or ultrasonic, to an object within the scope of
#'   the package. Called implicitly inside other wildrtrax functions
#'   not intended to be called directly by users.
#'
#' @param x An object (typically a data frame or list) to classify.
#' @param type Character string specifying the class to assign. One of
#'   "ARU", "camera", "point_count", or "ultrasonic".
#'
#' @return The input object with an added class attribute (`wt_aru`,
#'   `wt_camera`, `wt_point_count`, or `wt_ultrasonic`), plus the shared
#'   `wt_data` class.
#'
#' @keywords internal
#' @noRd

.wt_classes <- function(x, type = c("ARU", "camera", "point_count", "ultrasonic")) {

  type <- match.arg(type)

  wt_class <- switch(
    type,
    ARU = "wt_aru",
    camera = "wt_camera",
    point_count = "wt_point_count",
    ultrasonic = "wt_ultrasonic"
  )

  class(x) <- c(wt_class, "wt_data", class(x))

  x

}

#' Set of API functions
#'
#' @section Defines the API functions utilized to get data from WildTrax
#'
#' @description Generic function to handle POST requests
#'
#' @param path The path to the API
#' @param ... Argument to pass along into POST query
#' @param max_time The maximum number of seconds the API request can take. By default 300.
#'
#' @keywords internal
#'
#' @import httr2

.wt_api_pr <- function(path, query_params = list(), ..., max_time = 300, out_path = NULL) {

  if (.wt_auth_expired()) stop("Please authenticate with wt_auth().", call. = FALSE)

  req <- request("https://www-api.wildtrax.ca") |>
    req_url_path_append(path) |>
    req_url_query(!!!query_params) |>
    req_headers(Authorization = paste("Bearer", ._wt_auth_env_$access_token)) |>
    req_user_agent(.gen_ua()) |>
    req_method("POST") |>
    req_timeout(max_time)

  req_perform(req, path = out_path)

}

#' @description Generic function to handle GET requests
#'
#' @param path The path to the API
#' @param ... Argument to pass along into GET query
#' @param max_time The maximum number of seconds the API request can take. By default 300.
#'
#' @keywords internal
#'
#' @import httr2

.wt_api_gr <- function(path, query_params = list(), ..., max_time = 300, out_path = NULL) {

  if (.wt_auth_expired()) stop("Please authenticate with wt_auth().", call. = FALSE)

  req <- request("https://www-api.wildtrax.ca") |>
    req_url_path_append(path) |>
    req_url_query(!!!query_params) |>
    req_headers(Authorization = paste("Bearer", ._wt_auth_env_$access_token)) |>
    req_user_agent(.gen_ua()) |>
    req_method("GET") |>
    req_timeout(max_time)

  req_perform(req, path = out_path)

}

#' Internal function to get Organizations
#'
#' @description Internal function to get Organizations
#'
#' @keywords internal

.get_org_id <- function(organization) {

  if (is.numeric(organization)) {
    return(organization)
  } else if (is.character(organization)) {
    orgs <- .wt_api_gr(path = "/bis/get-all-readable-organizations")
    og <- httr2::resp_body_json(orgs)

    # Create a lookup table
    og_table <- tibble(
      org_id = purrr::map_dbl(og, ~ ifelse(!is.null(.x$id), .x$id, NA)),
      org_code = purrr::map_chr(og, ~ ifelse(!is.null(.x$name), .x$name, NA))
    )

    # Retrieve and return the numeric org_id
    return(og_table |>
             filter(org_code == organization) |>
             pull(org_id))
  }
  stop("Organization must be either numeric or character")
}
