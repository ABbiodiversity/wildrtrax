# =============================================================================
# Biodiversity Monitoring Class Assignment
# Classes: ARU (acoustic), BAT (ultrasonic), Camera, PointCount
# =============================================================================


# ── Valid class names (used in multiple roxygen @param tags) ──────────────────
.MONITORING_CLASSES <- c("ARU", "BAT", "Camera", "PointCount")


# =============================================================================
# assign_monitoring_class()
# =============================================================================

#' Assign a biodiversity monitoring class to an object
#'
#' Prepends one of four S3 monitoring classes — \code{"ARU"},
#' \code{"BAT"}, \code{"Camera"}, or \code{"PointCount"} — to any R
#' object (data frame, list, matrix, tibble, …).  Any pre-existing classes
#' are preserved so that generic functions such as \code{print()} and
#' \code{summary()} continue to dispatch correctly via \code{NextMethod()}.
#'
#' Optional metadata is stored as object attributes and is therefore
#' retained through \code{saveRDS()} / \code{readRDS()} round-trips.  A
#' \code{class_assigned_at} timestamp is stamped automatically.
#'
#' @param x        An R object to classify.  Typically a \code{data.frame}
#'   or \code{list}, but any object is accepted.
#' @param class    Character string.  The monitoring class to assign.
#'   Must be one of \code{"ARU"} (acoustic recording unit),
#'   \code{"BAT"} (ultrasonic bat detector), \code{"Camera"}
#'   (camera trap), or \code{"PointCount"} (avian/wildlife point count).
#'   Matched with \code{\link[base]{match.arg}}, so unambiguous
#'   abbreviations are accepted.
#' @param metadata Optional named \code{list} of ancillary information to
#'   attach as object attributes (e.g.
#'   \code{list(site = "Site_01", surveyor = "J. Smith")}).
#'   Every element must be named; unnamed elements raise an error.
#'   Pass \code{NULL} (default) to omit metadata.
#'
#' @return The input object \code{x}, invisibly, with:
#'   \itemize{
#'     \item its S3 class vector prepended with the chosen monitoring class;
#'     \item each \code{metadata} element stored as an attribute;
#'     \item a \code{class_assigned_at} \code{POSIXct} attribute recording
#'           the assignment time.
#'   }
#'
#' @seealso
#'   \code{\link{is_monitoring_class}} to test class membership. \cr
#'   \code{\link{print.ARU}}, \code{\link{print.BAT}},
#'   \code{\link{print.Camera}}, \code{\link{print.PointCount}} for
#'   formatted printing. \cr
#'   \code{\link{summary.ARU}}, \code{\link{summary.BAT}},
#'   \code{\link{summary.Camera}}, \code{\link{summary.PointCount}} for
#'   class-aware summaries.
#'
#' @export
#'
#' @examples
#' ## ARU — data.frame
#' aru_df <- data.frame(
#'   datetime  = as.POSIXct(c("2024-06-01 22:10", "2024-06-01 22:45")),
#'   species   = c("CONI", "BBCU"),
#'   amplitude = c(72.3, 65.1)
#' )
#' aru_obj <- assign_monitoring_class(
#'   aru_df, "ARU",
#'   metadata = list(site = "Site_A", recorder = "SongMeter4", gain_dB = 20)
#' )
#' print(aru_obj)
#' inherits(aru_obj, "ARU")        # TRUE
#' inherits(aru_obj, "data.frame") # TRUE — original class preserved
#'
#' ## BAT — list
#' bat_obj <- assign_monitoring_class(
#'   list(pulses = c(45200, 47800), duration_ms = c(3.2, 4.1)),
#'   "BAT",
#'   metadata = list(site = "Cave_Entrance", detector = "Anabat Swift")
#' )
#'
#' ## Camera — minimal, no metadata
#' cam_obj <- assign_monitoring_class(data.frame(), "Camera")
#'
#' ## PointCount — data.frame
#' pc_obj <- assign_monitoring_class(
#'   data.frame(
#'     observer = "J. Smith",
#'     species  = c("AMRO", "BCCH", "DOWO"),
#'     count    = c(3L, 1L, 2L)
#'   ),
#'   "PointCount",
#'   metadata = list(site = "Plot_07", duration_min = 10)
#' )
#' summary(pc_obj)
assign_monitoring_class <- function(x,
                                    class    = c("ARU", "BAT",
                                                 "Camera", "PointCount"),
                                    metadata = NULL) {

  # ── Validate class argument ────────────────────────────────────────────────
  class <- match.arg(class)

  # ── Validate metadata ──────────────────────────────────────────────────────
  if (!is.null(metadata)) {
    if (!is.list(metadata)) {
      stop("`metadata` must be a named list or NULL.")
    }
    if (is.null(names(metadata)) || any(names(metadata) == "")) {
      stop("All elements of `metadata` must be named.")
    }
  }

  # ── Assign class (prepend so existing classes are preserved) ───────────────
  # e.g. a data.frame becomes c("ARU", "data.frame")
  class(x) <- c(class, class(x))

  # ── Attach metadata as attributes ─────────────────────────────────────────
  if (!is.null(metadata)) {
    for (nm in names(metadata)) {
      attr(x, nm) <- metadata[[nm]]
    }
  }

  # ── Stamp assignment time ──────────────────────────────────────────────────
  attr(x, "class_assigned_at") <- Sys.time()

  invisible(x)
}


# =============================================================================
# is_monitoring_class()
# =============================================================================

#' Test whether an object belongs to a monitoring class
#'
#' A thin wrapper around \code{\link[base]{inherits}} that restricts the
#' test to the four recognised monitoring classes.
#'
#' @param x     Any R object.
#' @param class Character string.  One of \code{"ARU"}, \code{"BAT"},
#'   \code{"Camera"}, or \code{"PointCount"}.  Matched with
#'   \code{\link[base]{match.arg}}.
#'
#' @return A single \code{logical}: \code{TRUE} if \code{x} inherits from
#'   \code{class}, \code{FALSE} otherwise.
#'
#' @seealso \code{\link{assign_monitoring_class}}
#'
#' @export
#'
#' @examples
#' obj <- assign_monitoring_class(list(), "ARU")
#' is_monitoring_class(obj, "ARU")  # TRUE
#' is_monitoring_class(obj, "BAT")  # FALSE
is_monitoring_class <- function(x,
                                class = c("ARU", "BAT",
                                          "Camera", "PointCount")) {
  class <- match.arg(class)
  inherits(x, class)
}


# =============================================================================
# Internal helper — shared print header
# =============================================================================

#' Print metadata attributes for a monitoring object
#'
#' Internal helper called by all \code{print.*} methods.  Displays any
#' user-supplied metadata attributes and the \code{class_assigned_at}
#' timestamp, then draws a separator line.
#'
#' @param x A monitoring object created by \code{\link{assign_monitoring_class}}.
#'
#' @return \code{NULL}, invisibly.  Called for its side-effect of printing
#'   to the console.
#'
#' @keywords internal
#' @noRd
.print_monitoring_header <- function(x) {
  reserved <- c("names", "class", "dim", "dimnames",
                "row.names", "class_assigned_at", "tsp")
  meta_nms  <- setdiff(names(attributes(x)), reserved)

  if (length(meta_nms) > 0) {
    cat("Metadata:\n")
    for (nm in meta_nms) {
      cat(sprintf("  %-22s %s\n", paste0(nm, ":"), attr(x, nm)))
    }
  }

  ts <- attr(x, "class_assigned_at")
  if (!is.null(ts)) {
    cat(sprintf("  %-22s %s\n", "class_assigned_at:", format(ts)))
  }
  cat(strrep("-", 62), "\n", sep = "")
}


# =============================================================================
# S3 print methods
# =============================================================================

#' Print an ARU object
#'
#' Displays a header identifying the object as an Acoustic Recording Unit
#' dataset, prints any attached metadata, and then delegates to the
#' \code{print} method of the underlying object class (e.g.
#' \code{data.frame}).
#'
#' @param x   An object of class \code{"ARU"}, typically created by
#'   \code{\link{assign_monitoring_class}}.
#' @param ... Additional arguments passed to \code{NextMethod()}.
#'
#' @return \code{x}, invisibly.
#'
#' @method print ARU
#' @export
#'
#' @examples
#' obj <- assign_monitoring_class(
#'   data.frame(species = "CONI", amplitude = 72.3),
#'   "ARU",
#'   metadata = list(site = "Site_A")
#' )
#' print(obj)
print.ARU <- function(x, ...) {
  cat("\u2500\u2500 ARU (Acoustic Recording Unit) object ",
      strrep("\u2500", 21), "\n", sep = "")
  .print_monitoring_header(x)
  NextMethod()
  invisible(x)
}


#' Print a BAT object
#'
#' Displays a header identifying the object as an ultrasonic bat-detector
#' dataset, prints any attached metadata, and then delegates to the
#' \code{print} method of the underlying object class.
#'
#' @param x   An object of class \code{"BAT"}, typically created by
#'   \code{\link{assign_monitoring_class}}.
#' @param ... Additional arguments passed to \code{NextMethod()}.
#'
#' @return \code{x}, invisibly.
#'
#' @method print BAT
#' @export
#'
#' @examples
#' obj <- assign_monitoring_class(
#'   list(pulses = c(45200, 47800), duration_ms = c(3.2, 4.1)),
#'   "BAT",
#'   metadata = list(site = "Cave_Entrance", detector = "Anabat Swift")
#' )
#' print(obj)
print.BAT <- function(x, ...) {
  cat("\u2500\u2500 BAT (Ultrasonic) object ",
      strrep("\u2500", 37), "\n", sep = "")
  .print_monitoring_header(x)
  NextMethod()
  invisible(x)
}


#' Print a Camera object
#'
#' Displays a header identifying the object as a camera-trap dataset,
#' prints any attached metadata, and then delegates to the \code{print}
#' method of the underlying object class.
#'
#' @param x   An object of class \code{"Camera"}, typically created by
#'   \code{\link{assign_monitoring_class}}.
#' @param ... Additional arguments passed to \code{NextMethod()}.
#'
#' @return \code{x}, invisibly.
#'
#' @method print Camera
#' @export
#'
#' @examples
#' obj <- assign_monitoring_class(
#'   data.frame(species = "Black Bear", count = 1L),
#'   "Camera",
#'   metadata = list(site = "Ridge_Cam2", trap_model = "Reconyx HP2X")
#' )
#' print(obj)
print.Camera <- function(x, ...) {
  cat("\u2500\u2500 Camera Trap object ",
      strrep("\u2500", 42), "\n", sep = "")
  .print_monitoring_header(x)
  NextMethod()
  invisible(x)
}


#' Print a PointCount object
#'
#' Displays a header identifying the object as a point-count survey
#' dataset, prints any attached metadata, and then delegates to the
#' \code{print} method of the underlying object class.
#'
#' @param x   An object of class \code{"PointCount"}, typically created by
#'   \code{\link{assign_monitoring_class}}.
#' @param ... Additional arguments passed to \code{NextMethod()}.
#'
#' @return \code{x}, invisibly.
#'
#' @method print PointCount
#' @export
#'
#' @examples
#' obj <- assign_monitoring_class(
#'   data.frame(species = c("AMRO", "BCCH"), count = c(3L, 1L)),
#'   "PointCount",
#'   metadata = list(site = "Plot_07", duration_min = 10)
#' )
#' print(obj)
print.PointCount <- function(x, ...) {
  cat("\u2500\u2500 Point Count object ",
      strrep("\u2500", 42), "\n", sep = "")
  .print_monitoring_header(x)
  NextMethod()
  invisible(x)
}


# =============================================================================
# S3 summary methods
# =============================================================================

#' Summarise an ARU object
#'
#' Prints a class-identifying banner and then delegates to the
#' \code{summary} method of the underlying object (e.g.
#' \code{\link[base]{summary.data.frame}}).
#'
#' @param object An object of class \code{"ARU"}.
#' @param ...    Additional arguments passed to \code{NextMethod()}.
#'
#' @return Whatever \code{NextMethod()} returns (typically a
#'   \code{table} or named vector), invisibly.
#'
#' @method summary ARU
#' @export
#'
#' @examples
#' obj <- assign_monitoring_class(
#'   data.frame(species = c("CONI", "BBCU"), amplitude = c(72.3, 65.1)),
#'   "ARU"
#' )
#' summary(obj)
summary.ARU <- function(object, ...) {
  cat("ARU summary \u2014 acoustic detections\n")
  NextMethod()
}


#' Summarise a BAT object
#'
#' Prints a class-identifying banner and then delegates to the
#' \code{summary} method of the underlying object.
#'
#' @param object An object of class \code{"BAT"}.
#' @param ...    Additional arguments passed to \code{NextMethod()}.
#'
#' @return Whatever \code{NextMethod()} returns, invisibly.
#'
#' @method summary BAT
#' @export
#'
#' @examples
#' obj <- assign_monitoring_class(
#'   data.frame(freq_khz = c(45.2, 47.8), duration_ms = c(3.2, 4.1)),
#'   "BAT"
#' )
#' summary(obj)
summary.BAT <- function(object, ...) {
  cat("BAT summary \u2014 ultrasonic detections\n")
  NextMethod()
}


#' Summarise a Camera object
#'
#' Prints a class-identifying banner and then delegates to the
#' \code{summary} method of the underlying object.
#'
#' @param object An object of class \code{"Camera"}.
#' @param ...    Additional arguments passed to \code{NextMethod()}.
#'
#' @return Whatever \code{NextMethod()} returns, invisibly.
#'
#' @method summary Camera
#' @export
#'
#' @examples
#' obj <- assign_monitoring_class(
#'   data.frame(species = "Black Bear", count = 1L),
#'   "Camera"
#' )
#' summary(obj)
summary.Camera <- function(object, ...) {
  cat("Camera summary \u2014 camera trap records\n")
  NextMethod()
}


#' Summarise a PointCount object
#'
#' Prints a class-identifying banner and then delegates to the
#' \code{summary} method of the underlying object.
#'
#' @param object An object of class \code{"PointCount"}.
#' @param ...    Additional arguments passed to \code{NextMethod()}.
#'
#' @return Whatever \code{NextMethod()} returns, invisibly.
#'
#' @method summary PointCount
#' @export
#'
#' @examples
#' obj <- assign_monitoring_class(
#'   data.frame(
#'     species  = c("AMRO", "BCCH", "DOWO"),
#'     count    = c(3L, 1L, 2L),
#'     distance = c("< 50m", "> 50m", "< 50m")
#'   ),
#'   "PointCount"
#' )
#' summary(obj)
summary.PointCount <- function(object, ...) {
  cat("PointCount summary \u2014 point count records\n")
  NextMethod()
}
