#' Locate image files within a directory
#'
#' Recursively searches a directory for image files and returns their file
#' paths. By default, the function searches for JPEG images and returns
#' full file paths.
#'
#' @param path A character string specifying the root directory containing
#'   image files.
#' @param pattern A regular expression used to identify image files. The
#'   default searches for files containing `"jpg"` or `"JPEG"` in their
#'   names.
#' @param ignore.case Logical. Should pattern matching ignore letter case?
#'   Defaults to `TRUE`.
#'
#' @details
#' This function is intended as the first step in preparing image data for
#' WildTrax workflows. The returned file paths can be supplied to functions
#' that read image metadata or modify EXIF information.
#'
#' @return
#' A character vector containing the file paths of all images matching
#' `pattern`.
#'
#' @examples
#' \dontrun{
#'
#' # Locate all JPEG images beneath a project directory
#' imgs <- wt_image_paths(
#'   path = "my_sample"
#' )
#'
#'
#' }
#'
#' @export

wt_image_paths <- function(
    path,
    pattern = "jpg|JPEG",
    ignore.case = TRUE
){
  # checks for the various arguments
  if (!is.character(path) || length(path) != 1) {
    stop(
      "`path` must be a single character string.",
      call. = FALSE
    )
  }

  if (!dir.exists(path)) {
    stop(
      "`path` does not exist.",
      call. = FALSE
    )
  }

  if (!is.character(pattern) || length(pattern) != 1) {
    stop(
      "`pattern` must be a single character string.",
      call. = FALSE
    )
  }

  if (!is.logical(ignore.case) || length(ignore.case) != 1) {
    stop(
      "`ignore.case` must be TRUE or FALSE.",
      call. = FALSE
    )
  }
  to_return <- list.files(
    path = path,
    pattern = pattern,
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = ignore.case
  )
  return(to_return)
}

#' Summarize the folder hierarchy of file paths
#'
#' Parses file paths and summarizes the folder hierarchy. The function
#' checks whether all files occur at the same folder depth and, when they do,
#' prints the folder hierarchy for the first file path.
#'
#' @param paths A character vector of file paths, typically produced by
#'   [wt_image_paths()].
#' @param path_split Character string used to split file paths into their
#'   component folders. If `NULL`, defaults to the operating system's file separator.
#'
#' @details
#' This function is intended to help users understand the structure of image
#' directories prior to grouping images by site for downstream processing in
#' `wildrtrax`.
#'
#' The function first checks whether all file paths occur at the same folder
#' depth (i.e., the number of sub-folders in each file path).
#' If folder depths differ, a warning is issued reporting the observed
#' depths. If all paths have the same depth, the folder hierarchy for the
#' first file path is printed, allowing users to identify which directory
#' levels correspond to grouping variables of interest.
#'
#' @return
#' No value is returned.
#'
#' @examples
#' \dontrun{
#'
#' imgs <- wt_image_paths("my_sample")
#'
#' wt_path_summary(imgs)
#'
#' }
#'
#' @export
wt_path_summary <- function(
    paths,
    path_split = NULL
){

  if (!is.character(paths)) {
    stop(
      "`paths` must be a character vector.",
      call. = FALSE
    )
  }
  if(anyNA(paths)){
    stop(
      "`paths` cannot contain missing values.",
      call. = FALSE
    )
  }
  if (length(paths) == 0) {
    stop(
      "`paths` contains no file paths.",
      call. = FALSE
    )
  }
  if(is.null(path_split)){
    path_split <- .Platform$file.sep
  } else {
    if ( (!is.character(path_split) || length(path_split) != 1)) {
      stop(
        "`path_split` must be NULL or a single character string.",
        call. = FALSE
      )
    }
  }

  path_summary <- strsplit(
    dirname(paths),
    path_split,
    fixed = TRUE
  )

  path_lengths <- lengths(path_summary)

  if(length(unique(path_lengths)) != 1){

    warning(
      "Not all files have the same folder depth.\n",
      "Depths observed: ",
      paste(
        sort(unique(path_lengths)),
        collapse = ", "
      ),
      call. = FALSE
    )

  } else {

    cat(
      sprintf(
        "All files occur at the same depth (%i levels).\n\n",
        unique(path_lengths)
      )
    )
    cat("\n")
    cat("\nFolder hierarchy (example path):\n\n")

    for(i in seq_along(path_summary[[1]])){
      cat(
        sprintf(
          "Level %i: %s\n",
          i,
          path_summary[[1]][i]
        )
      )
    }

  }

  invisible(NULL)

}

