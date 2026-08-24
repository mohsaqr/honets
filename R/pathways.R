# ---- Pathway Extraction for Higher-Order Visualization ----

#' Extract Pathways from Higher-Order Network Objects
#'
#' @description
#' Extracts higher-order pathway strings suitable for
#' \code{cograph::plot_simplicial()}. Each pathway represents a
#' multi-step dependency: source states lead to a target state.
#'
#' For \code{net_hon}: extracts edges where the source node is
#' higher-order (order > 1), i.e., the transitions that differ from
#' first-order Markov.
#'
#' For \code{net_hypa}: extracts anomalous paths (over- or
#' under-represented relative to the hypergeometric null model).
#'
#' For \code{net_mogen}: extracts all transitions at the optimal order
#' (or a specified order).
#'
#' @param x A higher-order network object (\code{net_hon},
#'   \code{net_hypa}, or \code{net_mogen}).
#' @param ... Additional arguments.
#'
#' @return A character vector of pathway strings in arrow notation
#'   (e.g. \code{"A B -> C"}), suitable for
#'   \code{cograph::plot_simplicial()}.
#'
#' @examples
#' \donttest{
#' seqs <- list(c("A","B","C","D"), c("A","B","C","A"))
#' hon <- build_hon(seqs, max_order = 3)
#' pw <- pathways(hon)
#' }
#'
#' @export
pathways <- function(x, ...) {
  UseMethod("pathways")
}


#' @describeIn pathways Extract higher-order pathways from HON
#'
#' @param min_count Integer. Minimum transition count to include
#'   (default: 1). Filters noise from rare observations.
#' @param min_prob Numeric. Minimum transition probability to include
#'   (default: 0). Useful for filtering weak transitions.
#' @param top Integer or NULL. Return only the top N pathways ranked
#'   by count (default: NULL = all).
#' @param order Integer or NULL. If specified, only include pathways
#'   at this source order. Default: all orders > 1.
#'
#' @return A character vector of pathway strings.
#'
#' @export
pathways.net_hon <- function(x, min_count = 1L, min_prob = 0,
                             top = NULL, order = NULL, ...) {
  edges <- x$ho_edges
  if (is.null(edges) || nrow(edges) == 0L) return(character(0)) # nocov

  # Higher-order edges: from_order > 1
  ho <- edges[edges$from_order > 1L, , drop = FALSE]
  if (!is.null(order)) {
    ho <- ho[ho$from_order == order, , drop = FALSE]
  }
  if (min_count > 1L) {
    ho <- ho[ho$count >= min_count, , drop = FALSE]
  }
  if (min_prob > 0) {
    ho <- ho[ho$probability >= min_prob, , drop = FALSE]
  }
  # Rank by count descending
  ho <- ho[order(-ho$count), , drop = FALSE]
  if (!is.null(top) && nrow(ho) > top) {
    ho <- ho[seq_len(top), , drop = FALSE]
  }
  if (nrow(ho) == 0L) return(character(0))

  # Convert "A -> B -> C" path format to "A B -> C" for plot_simplicial
  # path column is already "A -> B -> C" - split into states
  vapply(ho$path, function(p) {
    parts <- trimws(strsplit(p, "->", fixed = TRUE)[[1]])
    if (length(parts) < 2L) return(p) # nocov
    sources <- paste(parts[-length(parts)], collapse = " ")
    paste(sources, "->", parts[length(parts)])
  }, character(1), USE.NAMES = FALSE)
}


#' @describeIn pathways Extract anomalous pathways from HYPA
#'
#' @param type Character. Which anomalies to include: \code{"all"}
#'   (default), \code{"over"}, or \code{"under"}.
#'
#' @return A character vector of pathway strings.
#'
#' @export
pathways.net_hypa <- function(x, type = "all", ...) {
  type <- match.arg(type, c("all", "over", "under"))
  scores <- x$scores
  if (is.null(scores) || nrow(scores) == 0L) return(character(0)) # nocov

  if (type == "all") {
    anom <- rbind(x$over, x$under)
  } else if (type == "over") {
    anom <- x$over
  } else {
    anom <- x$under
  }
  if (nrow(anom) == 0L) return(character(0))

  vapply(anom$path, function(p) {
    parts <- trimws(strsplit(p, "->", fixed = TRUE)[[1]])
    if (length(parts) < 2L) return(p) # nocov
    sources <- paste(parts[-length(parts)], collapse = " ")
    paste(sources, "->", parts[length(parts)])
  }, character(1), USE.NAMES = FALSE)
}


#' @describeIn pathways Extract transition pathways from MOGen
#'
#' @param order Integer or NULL. Markov order to extract. Default:
#'   optimal order from model selection.
#' @param min_count Integer. Minimum transition count to include
#'   (default: 1).
#' @param min_prob Numeric. Minimum transition probability to include
#'   (default: 0).
#' @param top Integer or NULL. Return only the top N pathways ranked
#'   by count (default: NULL = all).
#'
#' @return A character vector of pathway strings.
#'
#' @export
pathways.net_mogen <- function(x, order = NULL, min_count = 1L,
                               min_prob = 0, top = NULL, ...) {
  if (is.null(order)) order <- x$optimal_order
  if (order < 1L) return(character(0))

  trans <- mogen_transitions(x, order = order)
  if (is.null(trans) || nrow(trans) == 0L) return(character(0)) # nocov

  if (min_count > 1L) {
    trans <- trans[trans$count >= min_count, , drop = FALSE] # nocov
  }
  if (min_prob > 0) {
    trans <- trans[trans$probability >= min_prob, , drop = FALSE]
  }
  trans <- trans[order(-trans$count), , drop = FALSE]
  if (!is.null(top) && nrow(trans) > top) {
    trans <- trans[seq_len(top), , drop = FALSE] # nocov
  }
  if (nrow(trans) == 0L) return(character(0)) # nocov

  vapply(trans$path, function(p) {
    parts <- trimws(strsplit(p, "->", fixed = TRUE)[[1]])
    if (length(parts) < 2L) return(p) # nocov
    sources <- paste(parts[-length(parts)], collapse = " ")
    paste(sources, "->", parts[length(parts)])
  }, character(1), USE.NAMES = FALSE)
}
