# The projection tier: hypergraph -> weighted graph, and hypergraph ->
# s-line graph. Both are pure incidence algebra; the resulting graphs are
# what a graph engine such as cograph consumes for paths, betweenness/closeness and community detection.

# Membership pattern of an incidence matrix, sparse or dense, weights dropped.
.thg_binary <- function(x) (x != 0) * 1

# Scale columns of an incidence matrix by `coef`, sparse or dense. diag() with
# a length-one `coef` would build an identity of that size, hence `nrow=`.
.thg_scale_cols <- function(x, coef) {
  if (methods::is(x, "sparseMatrix")) {
    x %*% Matrix::Diagonal(x = coef)
  } else {
    x %*% diag(x = coef, nrow = length(coef))
  }
}

# Upper triangle of a symmetric weight matrix as a tidy edge list, sorted by
# (from, to) so the row order never depends on storage or input order.
.thg_tidy_pairs <- function(w, labels) {
  if (methods::is(w, "sparseMatrix")) {
    triplet <- methods::as(w, "TsparseMatrix")
    keep <- triplet@i < triplet@j & triplet@x != 0
    from <- labels[triplet@i[keep] + 1L]
    to <- labels[triplet@j[keep] + 1L]
    weight <- triplet@x[keep]
  } else {
    nz <- which(w != 0 & upper.tri(w), arr.ind = TRUE)
    from <- labels[nz[, "row"]]
    to <- labels[nz[, "col"]]
    weight <- as.numeric(w[nz])
  }
  out <- data.frame(from = from, to = to, weight = as.numeric(weight),
                    row.names = NULL)
  out <- out[order(out$from, out$to), , drop = FALSE]
  row.names(out) <- NULL
  out
}

#' Project a hypergraph onto a weighted graph
#'
#' Collapses every hyperedge into pairwise vertex relations, giving the
#' weighted graph that a graph engine (paths, betweenness, communities) can
#' consume. Two weightings are available. `"clique"` is plain co-occurrence,
#' the clique expansion: a hyperedge of size \eqn{|e|} contributes the same
#' amount to each of its \eqn{|e|(|e|-1)/2} pairs, so a single large hyperedge
#' can dominate every downstream measure. `"association"` divides each
#' hyperedge's contribution by \eqn{|e|-1}, following Coupette et al. (2024):
#'
#' \deqn{w(\{u,v\}) = \sum_{e \supseteq \{u,v\}} \frac{1}{|e| - 1}}
#'
#' so the total weight a hyperedge adds around any one of its members is
#' exactly 1, and each vertex's weighted degree in the projection equals the
#' number of hyperedges of size at least two that contain it. That
#' normalisation is what makes the projection a legitimate random-walk
#' operator rather than an arbitrary co-occurrence count.
#'
#' A hyperedge of size one has no pairs, so it contributes nothing and is
#' skipped rather than dividing by zero. Such hyperedges are common in text:
#' a word used in exactly one document is a singleton hyperedge in the
#' document orientation, which is why the degree identity above counts only
#' hyperedges of size at least two.
#'
#' @param hg A [text_hypergraph()], [knn_hypergraph()], or any honets
#'   `net_hypergraph`.
#' @param method Weighting. `"clique"` (default) sums incidence products;
#'   `"association"` applies the \eqn{1/(|e|-1)} normalisation above.
#' @param weighted `method = "clique"` only. `TRUE` (default) uses the
#'   incidence weights, `FALSE` their membership pattern. Setting it together
#'   with `method = "association"` is an error, because the association
#'   weighting is defined on hyperedge cardinality and never on the incidence
#'   weights.
#' @param what `"edges"` (default) for the tidy edge list, or `"matrix"` for
#'   the symmetric weight matrix to hand to a graph engine.
#' @return With `what = "edges"`, a base data.frame with one row per
#'   unordered vertex pair of non-zero weight, sorted by `from` then `to`,
#'   with columns `from`, `to` (vertex names) and `weight` (numeric). Vertices
#'   sharing no hyperedge do not appear, so an edgeless hypergraph yields a
#'   zero-row data.frame with those columns. With `what = "matrix"`, the
#'   symmetric `n_nodes` x `n_nodes` weight matrix with zero diagonal and
#'   vertex names as dimnames, sparse if `hg`'s incidence is sparse.
#' @references
#' Coupette, C., Hartung, D., & Katz, D. M. (2024). Legal hypergraphs.
#' *Philosophical Transactions of the Royal Society A*, 382(2270), 20230141.
#' \doi{10.1098/rsta.2023.0141}
#'
#' Zhou, D., Huang, J., & Schoelkopf, B. (2006). Learning with hypergraphs:
#' clustering, classification, and embedding. *NeurIPS 19*, 1601-1608.
#' @seealso [hg_line_graph()] for the dual projection, onto hyperedges.
#' @examples
#' hg <- text_hypergraph(c(a = "salt and soup", b = "soup and stars",
#'                         c = "stars and salt"))
#' hg_project(hg)
#' hg_project(hg, method = "association")
#' @export
hg_project <- function(hg, method = c("clique", "association"),
                       weighted = TRUE, what = c("edges", "matrix")) {
  .thg_check_hg(hg)
  method <- match.arg(method)
  what <- match.arg(what)
  stopifnot("`weighted` must be TRUE or FALSE" =
              length(weighted) == 1L && is.logical(weighted) &&
              !is.na(weighted))
  if (identical(method, "association") && !missing(weighted)) {
    stop(errorCondition(
      "`weighted` applies to `method = \"clique\"` only; the association weighting is defined on hyperedge cardinality, not on incidence weights",
      class = "honets_bad_input", call = NULL
    ))
  }
  incidence <- hg$incidence
  w <- if (identical(method, "clique")) {
    tcrossprod(if (weighted) incidence else .thg_binary(incidence))
  } else {
    b <- .thg_binary(incidence)
    cardinality <- Matrix::colSums(b)
    # A singleton hyperedge has no pairs: contribute 0 rather than divide by 0.
    coef <- ifelse(cardinality > 1, 1 / (cardinality - 1), 0)
    tcrossprod(.thg_scale_cols(b, coef), b)
  }
  diag(w) <- 0
  nodes <- rownames(incidence)
  dimnames(w) <- list(nodes, nodes)
  if (identical(what, "matrix")) return(w)
  .thg_tidy_pairs(w, nodes)
}

#' The s-line graph of a hypergraph
#'
#' Turns the hyperedges into vertices: two hyperedges are adjacent when they
#' share at least `s` vertices, and the edge weight is how many they share.
#' `s = 1` is the ordinary line graph (any overlap connects); raising `s`
#' keeps only substantial overlaps, which is how walk-based measures on
#' hyperedges are parametrised (Aksoy et al. 2020).
#'
#' This is the projection of the dual: `hg_line_graph(hg, s = 1)` returns the
#' same graph as `hg_project(dual_hypergraph(hg), weighted = FALSE)`, which
#' the tests assert.
#'
#' @param hg A [text_hypergraph()], [knn_hypergraph()], or any honets
#'   `net_hypergraph`.
#' @param s Minimum number of shared vertices for two hyperedges to be
#'   adjacent. A single integer of at least 1; `1` (default) is the ordinary
#'   line graph.
#' @param what `"edges"` (default) for the tidy edge list, or `"matrix"` for
#'   the symmetric overlap matrix to hand to a graph engine.
#' @return With `what = "edges"`, a base data.frame with one row per
#'   unordered hyperedge pair sharing at least `s` vertices, sorted by `from`
#'   then `to`, with columns `from`, `to` (hyperedge names) and `weight` (the
#'   number of shared vertices). A zero-row data.frame with those columns when
#'   no pair reaches `s`. With `what = "matrix"`, the symmetric
#'   `n_hyperedges` x `n_hyperedges` overlap matrix, zero on the diagonal and
#'   wherever the overlap is below `s`, sparse if `hg`'s incidence is sparse.
#' @references
#' Aksoy, S. G., Joslyn, C., Ortiz Marrero, C., Praggastis, B., & Purvine, E.
#' (2020). Hypernetwork science via high-order hypergraph walks.
#' *EPJ Data Science*, 9(1), 16. \doi{10.1140/epjds/s13688-020-00231-0}
#' @seealso [hg_project()] for the projection onto vertices,
#'   [dual_hypergraph()] for the role swap itself.
#' @examples
#' hg <- text_hypergraph(c(a = "salt and soup", b = "soup and stars",
#'                         c = "stars and salt"))
#' hg_line_graph(hg)
#' hg_line_graph(hg, s = 2)
#' @export
hg_line_graph <- function(hg, s = 1, what = c("edges", "matrix")) {
  .thg_check_hg(hg)
  what <- match.arg(what)
  stopifnot(
    "`s` must be a single whole number of at least 1" =
      length(s) == 1L && is.numeric(s) && is.finite(s) && s >= 1 &&
      isTRUE(all.equal(s, round(s)))
  )
  s <- as.integer(round(s))
  b <- .thg_binary(hg$incidence)
  overlap <- crossprod(b)
  diag(overlap) <- 0
  # Multiply by the threshold mask rather than index-assigning, which would
  # densify a sparse overlap matrix.
  overlap <- overlap * (overlap >= s)
  if (methods::is(overlap, "sparseMatrix")) overlap <- Matrix::drop0(overlap)
  edges <- colnames(hg$incidence)
  dimnames(overlap) <- list(edges, edges)
  if (identical(what, "matrix")) return(overlap)
  .thg_tidy_pairs(overlap, edges)
}
