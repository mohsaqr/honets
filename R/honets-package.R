#' honets: Higher-Order Network Analysis from Sequence Data
#'
#' Build and analyze higher-order networks from categorical sequence data:
#' higher-order networks with rule extraction (HON), higher-order network
#' embedding (HONEM), hypergeometric path anomaly detection (HYPA), the
#' multi-order generative model (MOGen), a permutation-based Markov order
#' test, and a per-context path-dependence diagnostic.
#'
#' honets is the home package for the variable-order Markov / path-statistics
#' paradigm in the Nestimate family: Nestimate delegates its higher-order
#' verbs here and re-exports them, so the two surfaces stay identical.
#'
#' @keywords internal
#' @importFrom stats setNames
#' @importFrom utils head
#' @importFrom ggplot2 .data
"_PACKAGE"

## ggplot2 non-standard-evaluation column names used in plot methods
utils::globalVariables(c(
  "KL", "context", "label", "x", "xend", "y", "yend",
  "top_o1", "top_ok"
))
