# Bundled example data, shared with Nestimate (same .rda files, same
# provenance); bundled here so higher-order examples, inference, and
# tutorials run on real coded sequences.

#' Human-AI Vibe Coding Interaction Data (Long Format)
#'
#' Coded turns from 429 human-AI pair programming sessions across 34
#' projects, in long format: `human_long` holds the human turns (10,796
#' rows), `ai_long` the AI turns (8,551 rows). Each session's ordered
#' codes form one categorical sequence, which makes the pair a natural
#' two-cohort input for the higher-order verbs -- e.g.
#' `bootstrap_hon(human_long, action = "code", actor = "session_id",
#' time = "timestamp")` or `compare_hon(human_long, ai_long, ...)`.
#'
#' The same data feed all three structure families: the ordered codes are
#' sequences for the memory family, a session is a natural hyperedge over
#' the codes that co-occur in it ([group_hypergraph()]), and a fitted
#' memory network becomes a pathway complex for the simplicial family
#' ([build_simplicial()] with `type = "pathway"`).
#'
#' @format Data frames in long format with 9 columns:
#' \describe{
#'   \item{message_id}{Integer. Turn index.}
#'   \item{project}{Character. Project identifier (Project_1 .. Project_34).}
#'   \item{session_id}{Character. Unique session hash.}
#'   \item{timestamp}{Integer. Unix timestamp for ordering.}
#'   \item{session_date}{Character. Date of the session (YYYY-MM-DD).}
#'   \item{code}{Character. Interaction code.}
#'   \item{cluster}{Character. High-level cluster: Directive, Evaluative,
#'     or Metacognitive (human codes); AI turns carry their own scheme.}
#'   \item{code_order}{Integer. Order of the code within the session.}
#'   \item{order_in_session}{Integer. Absolute turn order within the session.}
#' }
#'
#' @source Saqr, M. (2026). Human-AI vibe coding interaction study.
#'   \url{https://saqr.me/blog/2026/human-ai-interaction-cograph/}
#'
#' @examples
#' bs <- bootstrap_hon(human_long, action = "code", actor = "session_id",
#'                     time = "timestamp", n_boot = 20, max_order = 2,
#'                     seed = 1)
#' head(as.data.frame(bs, order_min = 2))
#'
#' @name long-data
#' @aliases ai_long
NULL

#' @rdname long-data
"human_long"

#' @rdname long-data
"ai_long"
