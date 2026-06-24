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


wt_extract_folder_level <- function(
    paths,
    level,
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

    if (!is.numeric(level)|| level < 1 || length(level) != 1){
      stop(
        "`level` must be a numeric scalar of length 1.",
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

    folder_level <- strsplit(
      dirname(paths),
      path_split,
      fixed = TRUE
    )
    folder_lengths <- lengths(
      folder_level
    )
    if(!all(folder_lengths > level)){
      stop(
        "Some paths have less sub-folders than the level specified.",
        call. = FALSE
      )
    }
    folder_level <- sapply(
      folder_level,
      "[[",
      level
    )

    return(folder_level)
}



#' Extract image datetimes from EXIF metadata
#'
#' Uses \pkg{exifr} to extract the `DateTimeOriginal` field from image EXIF
#' metadata. Images can either be processed exactly or sampled to provide a
#' faster estimate of the date range represented within a dataset.
#'
#' @param paths A character vector of image file paths, typically produced by
#'   [wt_image_paths()].
#' @param method Character string specifying the extraction method. `"exact"`
#'   extracts EXIF metadata from every image. `"fast"` extracts metadata from
#'   the first and last `n` images, optionally within groups.
#' @param group An optional vector used to group images (e.g., site), typically
#'   produced by [wt_extract_folder_level()]. Must have the same length as
#'   `paths`. When provided, the `"fast"` method extracts metadata from the
#'   first and last `n` images within each group.
#' @param n Number of images to sample from the beginning and end of each
#'   group when `method = "fast"`. Defaults to 5.
#'
#' @details
#' The `"fast"` method is intended for quickly assessing the datetimes
#' of a large image dataset without reading EXIF metadata from every file.
#' Images that are not sampled will have `NA` values for their extracted
#' datetime. This is a fast way to quickly check if there are any datetime
#' errors in your image set.
#'
#' The `"fast"` method assumes that `paths` are ordered chronologically within
#' groups. Users should ensure that file paths are sorted appropriately before
#' running this function.
#'
#' @return
#' A data frame with one row per input image containing:
#' \itemize{
#'   \item `path`: image file path
#'   \item `group`: grouping variable, if supplied
#'   \item `DateTimeOriginal`: datetime extracted from EXIF metadata
#' }
#'
#' @examples
#' \dontrun{
#'
#' imgs <- wt_image_paths("my_sample")
#'
#' # Extract metadata from all images
#' wt_image_datetime(
#'   imgs,
#'   method = "exact"
#' )
#'
#' # Quickly estimate date range by site
#' wt_image_datetime(
#'   imgs,
#'   method = "fast",
#'   group = site
#' )
#'
#' }
#'
#' @export
wt_image_datetime <- function(
    paths,
    method = c("fast", "exact"),
    group = NULL,
    n = 5
){

  if(!is.character(paths)){
    stop(
      "`paths` must be a character vector.",
      call. = FALSE
    )
  }

  if(length(paths) == 0){
    stop(
      "`paths` contains no file paths.",
      call. = FALSE
    )
  }

  if(anyNA(paths)){
    stop(
      "`paths` cannot contain missing values.",
      call. = FALSE
    )
  }

  method <- match.arg(
    method
  )

  if(!is.null(group)){
    if(length(group) != length(paths)){
      stop(
        "`group` must have the same length as `paths`.",
        call. = FALSE
      )
    }

    if(!is.character(group) && !is.factor(group)){
      stop(
        "`group` must be either a character vector or factor.",
        call. = FALSE
      )
    }

    group <- as.factor(group)

  }

  if(!is.numeric(n) || length(n) != 1 || n < 1 || n %% 1 != 0){
    stop(
      "`n` must be a single positive integer.",
      call. = FALSE
    )
  }


  # The output to return,
  #  creating because if method = "fast"
  #  then  we want to have the NA
  #  values for DateTimeOriginal
  out <- data.frame(
    path = paths,
    DateTimeOriginal = NA_character_
  )

  if(!is.null(group)){
    out$group <- group
  }

  # determine images to query
  if(method == "exact"){

    idx <- seq_along(paths)

  } else {
    if(is.null(group)){
      idx <- unique(
        c(
          seq_len(min(n, length(paths))),
          tail(seq_along(paths), n)
        )
      )
    } else {
      idx <- unlist(
        lapply(
          split(seq_along(paths), group),
          function(x) {
            unique(
              c(
                head(x, n),
                tail(x, n)
              )
            )
          }
        )
      )
    }
  }

  # extract EXIF information
  exif <- exifr::read_exif(
    paths[idx],
    tags = "DateTimeOriginal"
  )

  match_idx <- match(paths[idx], exif$SourceFile)

  out$DateTimeOriginal[idx] <-
    exif$DateTimeOriginal[match_idx]


  return(out)

}

