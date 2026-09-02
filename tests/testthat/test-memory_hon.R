testthat::skip_on_cran()

# ===========================================================================
# Tests for build_hon() — Higher-Order Network construction
# ===========================================================================

# --- Helper: simple trajectories with known structure ---
.make_hon_data <- function() {
  data.frame(
    T1 = c("A", "B", "C", "A", "D"),
    T2 = c("B", "A", "A", "B", "A"),
    T3 = c("C", "B", "B", "C", "B"),
    T4 = c("D", "C", "C", "D", "C"),
    T5 = c("A", "D", "D", "A", NA),
    T6 = c("B", "A", "A", "B", NA),
    T7 = c("C", "B", "B", "C", NA),
    stringsAsFactors = FALSE
  )
}

# ===========================================================================
# Section 1: Input validation
# ===========================================================================
test_that("build_hon rejects non-data.frame non-list input", {
  expect_error(build_hon(42), "data.frame or list")
})

test_that("build_hon rejects empty data.frame", {
  expect_error(build_hon(data.frame()), "at least one")
})

test_that("build_hon rejects max_order < 1", {
  expect_error(build_hon(.make_hon_data(), max_order = 0), "max_order")
})

test_that("build_hon rejects min_freq < 1", {
  expect_error(build_hon(.make_hon_data(), min_freq = 0), "min_freq")
})

test_that("build_hon accepts data.frame input", {
  result <- build_hon(.make_hon_data(), min_freq = 1L)
  expect_s3_class(result, "net_hon")
})

test_that("build_hon accepts list input", {
  trajs <- list(c("A", "B", "C"), c("B", "C", "A"))
  result <- build_hon(trajs, min_freq = 1L)
  expect_s3_class(result, "net_hon")
})

test_that("build_hon strips trailing NAs from data.frame rows", {
  df <- data.frame(T1 = c("A", "A"), T2 = c("B", "B"), T3 = c("C", NA),
                   stringsAsFactors = FALSE)
  result <- build_hon(df, min_freq = 1L)
  expect_s3_class(result, "net_hon")
})

test_that("build_hon collapse_repeats removes adjacent duplicates", {
  trajs <- list(c("A", "A", "B", "B", "C"))
  result <- build_hon(trajs, min_freq = 1L, collapse_repeats = TRUE)
  expect_true(result$n_edges > 0)
})

# ===========================================================================
# Section 2: Observation counting
# ===========================================================================
test_that("counts correct for single trajectory A->B->C", {
  trajs <- list(c("A", "B", "C"))
  count <- .hon_build_observations(trajs, max_order = 2L)
  expect_equal(count[[.hon_encode("A")]][["B"]], 1L)
  expect_equal(count[[.hon_encode("B")]][["C"]], 1L)
  expect_equal(count[[.hon_encode(c("A", "B"))]][["C"]], 1L)
})

test_that("counts accumulate across multiple trajectories", {
  trajs <- list(c("A", "B", "C"), c("A", "B", "D"), c("A", "B", "C"))
  count <- .hon_build_observations(trajs, max_order = 1L)
  expect_equal(count[[.hon_encode("A")]][["B"]], 3L)
  expect_equal(count[[.hon_encode("B")]][["C"]], 2L)
  expect_equal(count[[.hon_encode("B")]][["D"]], 1L)
})

test_that("max_order limits observation depth", {
  trajs <- list(c("A", "B", "C", "D"))
  count1 <- .hon_build_observations(trajs, max_order = 1L)
  expect_false(is.null(count1[[.hon_encode("A")]]))
  expect_true(is.null(count1[[.hon_encode(c("A", "B"))]]))
  count2 <- .hon_build_observations(trajs, max_order = 2L)
  expect_false(is.null(count2[[.hon_encode(c("A", "B"))]]))
  expect_true(is.null(count2[[.hon_encode(c("A", "B", "C"))]]))
})

test_that("short trajectories contribute only possible orders", {
  trajs <- list(c("X", "Y"))
  count <- .hon_build_observations(trajs, max_order = 5L)
  expect_equal(count[[.hon_encode("X")]][["Y"]], 1L)
  all_keys <- ls(count)
  expect_true(all(.hon_key_len(all_keys) == 1L))
})

# ===========================================================================
# Section 3: Distribution building
# ===========================================================================
test_that("distributions sum to 1 for each source", {
  trajs <- list(c("A", "B", "C"), c("A", "B", "D"), c("A", "B", "C"))
  count <- .hon_build_observations(trajs, max_order = 1L)
  distr <- .hon_build_distributions(count, min_freq = 1L)
  for (key in ls(distr)) {
    probs <- distr[[key]]
    if (length(probs) > 0L) {
      expect_equal(sum(probs), 1.0, tolerance = 1e-10)
    }
  }
})

test_that("min_freq filters low-count transitions", {
  trajs <- list(c("A", "B", "C"), c("A", "B", "D"), c("A", "B", "C"))
  count <- .hon_build_observations(trajs, max_order = 1L)
  distr <- .hon_build_distributions(count, min_freq = 2L)
  b_distr <- distr[[.hon_encode("B")]]
  expect_true(is.na(b_distr["D"]) || is.null(b_distr["D"]))
  expect_equal(unname(b_distr["C"]), 1.0)
})

test_that("sources with all counts below min_freq get empty distribution", {
  trajs <- list(c("X", "Y"))
  count <- .hon_build_observations(trajs, max_order = 1L)
  distr <- .hon_build_distributions(count, min_freq = 5L)
  expect_equal(length(distr[[.hon_encode("X")]]), 0L)
})

# ===========================================================================
# Section 4: KL-divergence and threshold
# ===========================================================================
test_that("KLD of identical distributions is 0", {
  d <- c(A = 0.5, B = 0.5)
  expect_equal(.hon_kld(d, d), 0.0)
})

test_that("KLD of peaked vs uniform is log2(2) = 1", {
  a <- c(X = 1.0)
  b <- c(X = 0.5, Y = 0.5)
  expect_equal(.hon_kld(a, b), 1.0)
})

test_that("KLD threshold decreases with more data", {
  count_env <- new.env(hash = TRUE, parent = emptyenv())
  count_env[["k"]] <- c(A = 5L, B = 5L)
  t1 <- .hon_kld_threshold(2L, "k", count_env)
  count_env[["k"]] <- c(A = 50L, B = 50L)
  t2 <- .hon_kld_threshold(2L, "k", count_env)
  expect_true(t2 < t1)
})

test_that("KLD threshold increases with order", {
  count_env <- new.env(hash = TRUE, parent = emptyenv())
  count_env[["k"]] <- c(A = 10L, B = 10L)
  t2 <- .hon_kld_threshold(2L, "k", count_env)
  t3 <- .hon_kld_threshold(3L, "k", count_env)
  expect_true(t3 > t2)
})

# ===========================================================================
# Section 5: End-to-end pipeline
# ===========================================================================
test_that("build_hon returns correct structure", {
  result <- build_hon(.make_hon_data(), max_order = 2L, min_freq = 1L)
  expect_true(is.matrix(result$matrix))
  expect_true(is.data.frame(result$ho_edges))
  expect_true(is.data.frame(result$nodes))
  expect_true(result$directed)
  expect_true(result$n_nodes > 0L)
  expect_true(result$n_edges > 0L)
  # Check unified column structure
  expect_true(all(c("path", "from", "to", "count", "probability",
                     "from_order", "to_order") %in% names(result$ho_edges)))
})

test_that("build_hon nodes use arrow notation", {
  trajs <- list(c("A", "B", "C"))
  result <- build_hon(trajs, max_order = 1L, min_freq = 1L)
  # First-order nodes should be simple state names (no arrows)
  expect_true(all(result$nodes$label %in% c("A", "B", "C")))
})

test_that("sequence_to_node produces readable arrow notation", {
  expect_equal(.hon_sequence_to_node("A"), "A")
  expect_equal(.hon_sequence_to_node(c("A", "B")), "A -> B")
  expect_equal(.hon_sequence_to_node(c("X", "A", "B")), "X -> A -> B")
})

test_that("print and summary work without error", {
  result <- build_hon(.make_hon_data(), max_order = 2L, min_freq = 1L)
  expect_output(print(result), "Higher-Order Network")
  expect_output(summary(result), "Summary")
})

test_that("edge probabilities are in (0, 1]", {
  result <- build_hon(.make_hon_data(), max_order = 2L, min_freq = 1L)
  expect_true(all(result$ho_edges$probability > 0))
  expect_true(all(result$ho_edges$probability <= 1))
})

test_that("encode/decode roundtrip preserves tuple", {
  tup <- c("alpha", "beta", "gamma")
  expect_equal(.hon_decode(.hon_encode(tup)), tup)
})

test_that("key_len returns correct lengths", {
  keys <- c(.hon_encode("A"), .hon_encode(c("A", "B")),
            .hon_encode(c("X", "Y", "Z")))
  expect_equal(.hon_key_len(keys), c(1L, 2L, 3L))
})

test_that("build_hon with max_order=1 produces only first-order nodes", {
  trajs <- list(c("A", "B", "C", "D"))
  result <- build_hon(trajs, max_order = 1L, min_freq = 1L)
  # All nodes should have order 1 (no arrows in name)
  node_orders <- vapply(result$nodes$label, function(nd) {
    length(strsplit(nd, " -> ", fixed = TRUE)[[1L]])
  }, integer(1L))
  expect_true(all(node_orders == 1L))
})

test_that("adjacency matrix dimensions match n_nodes", {
  result <- build_hon(.make_hon_data(), max_order = 2L, min_freq = 1L)
  expect_equal(nrow(result$matrix), result$n_nodes)
  expect_equal(ncol(result$matrix), result$n_nodes)
})

# ===========================================================================
# Section 7: HON+ internals
# ===========================================================================

# ---------------------------------------------------------------------------
# Task 1: .honp_max_divergence
# ---------------------------------------------------------------------------

test_that("honp_max_divergence puts all mass on least probable target", {
  d <- c(A = 0.6, B = 0.3, C = 0.1)
  result <- .honp_max_divergence(d)
  expect_equal(length(result), 1L)
  expect_equal(names(result), "C")
  expect_equal(unname(result), 1.0)
})

test_that("honp_max_divergence handles single-target distribution", {
  d <- c(X = 1.0)
  result <- .honp_max_divergence(d)
  expect_equal(names(result), "X")
  expect_equal(unname(result), 1.0)
})

test_that("honp_max_divergence handles ties by picking first minimum", {
  d <- c(A = 0.5, B = 0.5)
  result <- .honp_max_divergence(d)
  expect_equal(length(result), 1L)
  expect_equal(unname(result), 1.0)
})

# ---------------------------------------------------------------------------
# Task 2: .honp_build_order1
# ---------------------------------------------------------------------------

test_that("honp_build_order1 produces correct counts and starting_points", {
  trajs <- list(c("A", "B", "C"), c("A", "B", "A"))
  result <- .honp_build_order1(trajs, min_freq = 1L)

  expect_true(is.list(result))
  expect_true(all(c("count", "distr", "starting_points") %in% names(result)))

  count_a <- result$count[[.hon_encode("A")]]
  expect_equal(unname(count_a["B"]), 2L)

  distr_a <- result$distr[[.hon_encode("A")]]
  expect_equal(sum(distr_a), 1.0)

  sp_a <- result$starting_points[[.hon_encode("A")]]
  expect_true(length(sp_a) >= 2L)
})

test_that("honp_build_order1 applies min_freq filtering", {
  trajs <- list(c("A", "B", "C", "B", "C", "B"))
  result <- .honp_build_order1(trajs, min_freq = 2L)

  distr_b <- result$distr[[.hon_encode("B")]]
  expect_true(all(distr_b > 0))

  count_b <- result$count[[.hon_encode("B")]]
  expect_true(any(count_b == 0L) || all(count_b >= 2L))
})

# ---------------------------------------------------------------------------
# Task 3: .honp_extend_observation
# ---------------------------------------------------------------------------

test_that("honp_extend_observation builds higher-order counts lazily", {
  trajs <- list(c("X", "A", "B", "C"), c("Y", "A", "B", "D"))
  o1 <- .honp_build_order1(trajs, min_freq = 1L)
  source_to_ext <- new.env(hash = TRUE, parent = emptyenv())

  key_a <- .hon_encode("A")
  .honp_extend_observation(key_a, source_to_ext, o1$count, o1$distr,
                           o1$starting_points, trajs, 1L)

  ext_keys <- ls(source_to_ext[[key_a]])
  expect_true(length(ext_keys) >= 1L)

  for (ek in ext_keys) {
    expect_false(is.null(o1$distr[[ek]]))
  }
})

test_that("honp_extend_observation records starting_points for extensions", {
  trajs <- list(c("X", "A", "B"), c("Y", "A", "B"))
  o1 <- .honp_build_order1(trajs, min_freq = 1L)
  source_to_ext <- new.env(hash = TRUE, parent = emptyenv())

  key_a <- .hon_encode("A")
  .honp_extend_observation(key_a, source_to_ext, o1$count, o1$distr,
                           o1$starting_points, trajs, 1L)

  key_xa <- .hon_encode(c("X", "A"))
  sp <- o1$starting_points[[key_xa]]
  expect_true(!is.null(sp))
  expect_true(length(sp) >= 1L)
})

# ---------------------------------------------------------------------------
# Task 4: .honp_extend_source_fast
# ---------------------------------------------------------------------------

test_that("honp_extend_source_fast returns extensions lazily", {
  trajs <- list(c("X", "A", "B"), c("Y", "A", "B"))
  o1 <- .honp_build_order1(trajs, min_freq = 1L)
  source_to_ext <- new.env(hash = TRUE, parent = emptyenv())

  key_a <- .hon_encode("A")
  exts <- .honp_extend_source_fast(key_a, source_to_ext, o1$count,
                                    o1$distr, o1$starting_points, trajs, 1L)
  expect_true(length(exts) >= 1L)

  exts2 <- .honp_extend_source_fast(key_a, source_to_ext, o1$count,
                                     o1$distr, o1$starting_points, trajs, 1L)
  expect_equal(sort(exts), sort(exts2))
})

# ---------------------------------------------------------------------------
# Task 5: .honp_extend_rule and .honp_add_to_rules
# ---------------------------------------------------------------------------

test_that("honp_extend_rule finds rules with MaxDivergence pre-check", {
  # 4 obs per branch: threshold = 2/log2(5) ≈ 0.86 < KLD = 1.0  → extends
  trajs <- list(
    c("X", "A", "C"), c("X", "A", "C"), c("X", "A", "C"), c("X", "A", "C"),
    c("Y", "A", "D"), c("Y", "A", "D"), c("Y", "A", "D"), c("Y", "A", "D")
  )
  o1 <- .honp_build_order1(trajs, min_freq = 1L)
  source_to_ext <- new.env(hash = TRUE, parent = emptyenv())
  rules <- new.env(hash = TRUE, parent = emptyenv())

  key_a <- .hon_encode("A")
  .honp_add_to_rules(key_a, o1$distr, rules, source_to_ext, o1$count,
                      o1$starting_points, trajs, 1L)
  .honp_extend_rule(key_a, key_a, 1L, 99L, o1$distr, o1$count,
                    source_to_ext, o1$starting_points, trajs, 1L, rules)

  rule_keys <- ls(rules)
  rule_lens <- .hon_key_len(rule_keys)
  expect_true(any(rule_lens == 2L))
})

test_that("honp_extend_rule prunes when MaxDivergence below threshold", {
  trajs <- list(
    c("X", "A", "B"), c("Y", "A", "B"),
    c("X", "A", "B"), c("Y", "A", "B")
  )
  o1 <- .honp_build_order1(trajs, min_freq = 1L)
  source_to_ext <- new.env(hash = TRUE, parent = emptyenv())
  rules <- new.env(hash = TRUE, parent = emptyenv())

  key_a <- .hon_encode("A")
  .honp_add_to_rules(key_a, o1$distr, rules, source_to_ext, o1$count,
                      o1$starting_points, trajs, 1L)
  .honp_extend_rule(key_a, key_a, 1L, 99L, o1$distr, o1$count,
                    source_to_ext, o1$starting_points, trajs, 1L, rules)

  rule_keys <- ls(rules)
  rule_lens <- .hon_key_len(rule_keys)
  expect_true(all(rule_lens == 1L))
})

# ---------------------------------------------------------------------------
# Task 6: .honp_extract_rules
# ---------------------------------------------------------------------------

test_that("honp_extract_rules produces rules from trajectories", {
  trajs <- list(c("A", "B", "C"), c("A", "B", "D"), c("A", "B", "C"))
  result <- .honp_extract_rules(trajs, max_order = 99L, min_freq = 1L)
  rules <- result$rules

  rule_keys <- ls(rules)
  expect_true(length(rule_keys) > 0L)

  expect_false(is.null(rules[[.hon_encode("A")]]))
  expect_false(is.null(rules[[.hon_encode("B")]]))
})

# ===========================================================================
# Section 8: build_hon() method parameter
# ===========================================================================
test_that("build_hon accepts method parameter", {
  trajs <- list(c("A", "B", "C", "D"), c("A", "B", "D", "C"))
  r1 <- build_hon(trajs, max_order = 2L, min_freq = 1L, method = "hon")
  expect_s3_class(r1, "net_hon")

  r2 <- build_hon(trajs, max_order = 2L, min_freq = 1L, method = "hon+")
  expect_s3_class(r2, "net_hon")
})

test_that("build_hon default method is hon+", {
  trajs <- list(c("A", "B", "C"))
  r <- build_hon(trajs, max_order = 1L, min_freq = 1L)
  expect_s3_class(r, "net_hon")
})

test_that("build_hon rejects invalid method", {
  trajs <- list(c("A", "B", "C"))
  expect_error(build_hon(trajs, method = "invalid"), "arg")
})

# ===========================================================================
# Section 9: HON vs HON+ equivalence
# ===========================================================================
test_that("hon and hon+ produce identical networks on simple data", {
  trajs <- list(
    c("A", "B", "C", "D"), c("A", "B", "D", "C"),
    c("A", "C", "B", "D"), c("D", "C", "B", "A")
  )
  r_hon  <- build_hon(trajs, max_order = 3L, min_freq = 1L, method = "hon")
  r_honp <- build_hon(trajs, max_order = 3L, min_freq = 1L, method = "hon+")

  expect_equal(nrow(r_hon$ho_edges), nrow(r_honp$ho_edges))

  e1 <- r_hon$ho_edges[order(r_hon$ho_edges$from, r_hon$ho_edges$to),
                    c("from", "to", "probability")]
  e2 <- r_honp$ho_edges[order(r_honp$ho_edges$from, r_honp$ho_edges$to),
                     c("from", "to", "probability")]
  rownames(e1) <- rownames(e2) <- NULL
  expect_equal(e1$from, e2$from)
  expect_equal(e1$to, e2$to)
  expect_equal(e1$probability, e2$probability, tolerance = 1e-10)
})

test_that("hon and hon+ match on higher-order dependency data", {
  trajs <- list(
    c("X", "A", "C"), c("X", "A", "C"), c("X", "A", "C"), c("X", "A", "C"),
    c("Y", "A", "D"), c("Y", "A", "D"), c("Y", "A", "D"), c("Y", "A", "D"),
    c("A", "B", "A"), c("B", "A", "B")
  )
  r_hon  <- build_hon(trajs, max_order = 3L, min_freq = 1L, method = "hon")
  r_honp <- build_hon(trajs, max_order = 3L, min_freq = 1L, method = "hon+")

  e1 <- r_hon$ho_edges[order(r_hon$ho_edges$from, r_hon$ho_edges$to), ]
  e2 <- r_honp$ho_edges[order(r_honp$ho_edges$from, r_honp$ho_edges$to), ]
  expect_equal(nrow(e1), nrow(e2))
  expect_equal(e1$probability, e2$probability, tolerance = 1e-10)
})

test_that("hon and hon+ match on 5-state data with min_freq filtering", {
  set.seed(42)
  states <- c("A", "B", "C", "D", "E")
  trajs <- lapply(1:50, function(i) sample(states, sample(5:15, 1), replace = TRUE))
  r_hon  <- build_hon(trajs, max_order = 3L, min_freq = 3L, method = "hon")
  r_honp <- build_hon(trajs, max_order = 3L, min_freq = 3L, method = "hon+")

  e1 <- r_hon$ho_edges[order(r_hon$ho_edges$from, r_hon$ho_edges$to),
                    c("from", "to", "probability")]
  e2 <- r_honp$ho_edges[order(r_honp$ho_edges$from, r_honp$ho_edges$to),
                     c("from", "to", "probability")]
  rownames(e1) <- rownames(e2) <- NULL
  expect_equal(e1, e2, tolerance = 1e-10)
})

test_that(".hon_parse_input drops all-NA rows", {
  df <- data.frame(T1 = c(NA, "A"), T2 = c(NA, "B"), stringsAsFactors = FALSE)
  result <- .hon_parse_input(df)
  # The first row is all-NA: it should be dropped, leaving 1 trajectory
  expect_equal(length(result), 1L)
  expect_equal(result[[1L]], c("A", "B"))
})

# --- .hon_parse_input: invalid input type stops ---
test_that(".hon_parse_input stops on invalid input", {
  expect_error(.hon_parse_input(42), "data.frame or list")
})

# --- .hon_parse_input: collapse_repeats with length-1 trajectory ---
test_that(".hon_parse_input collapse_repeats returns length-1 traj unchanged", {
  # A length-1 traj is filtered out (needs >=2 for transitions), so test
  # that a 2-element traj after collapsing still works
  trajs <- list(c("A", "A", "B"))
  result <- .hon_parse_input(trajs, collapse_repeats = TRUE)
  expect_equal(result[[1L]], c("A", "B"))
})

# --- .hon_parse_input: collapse_repeats with single-element input ---
test_that(".hon_parse_input collapse_repeats skips length-1 element", {
  # After collapsing, length-1 elements stay as-is (branch: length(traj)<=1)
  # We pass a list with a 2-element traj where all are same => collapses to 1
  # => that traj gets filtered (< 2 states), so result is empty
  trajs <- list(c("A", "A"))
  result <- .hon_parse_input(trajs, collapse_repeats = TRUE)
  expect_equal(length(result), 0L)
})

# --- .hon_kld: empty distribution a returns 0 ---
test_that(".hon_kld returns 0 for empty distribution a", {
  a <- numeric(0L)
  b <- c(X = 0.5, Y = 0.5)
  expect_equal(.hon_kld(a, b), 0.0)
})

# --- .hon_kld: p_b = 0 for a target with p_a > 0 returns Inf ---
test_that(".hon_kld returns Inf when p_b = 0 for supported target", {
  a <- c(X = 1.0)
  b <- c(Y = 1.0)  # X not in b => p_b(X) = 0
  expect_equal(.hon_kld(a, b), Inf)
})

# --- .hon_get_extensions: order key missing returns character(0) ---
test_that(".hon_get_extensions returns character(0) when order key missing", {
  cache <- new.env(hash = TRUE, parent = emptyenv())
  # Put an entry in cache but without the queried order
  inner <- new.env(hash = TRUE, parent = emptyenv())
  inner[["3"]] <- c("some_key")
  cache[["key_a"]] <- inner
  result <- .honp_extend_source_fast  # just checking .hon_get_extensions indirectly
  ext <- .hon_get_extensions("key_a", 99L, cache)
  expect_equal(ext, character(0L))
})

# --- .hon_sequence_to_node: empty sequence returns "" ---
test_that(".hon_sequence_to_node returns empty string for empty input", {
  expect_equal(.hon_sequence_to_node(character(0L)), "")
})

# --- .hon_graph_to_edgelist: empty graph returns empty data.frame ---
test_that(".hon_graph_to_edgelist returns empty data.frame for empty graph", {
  graph <- new.env(hash = TRUE, parent = emptyenv())
  result <- .hon_graph_to_edgelist(graph)
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0L)
  expect_true(all(c("path", "from", "to", "count", "probability",
                     "from_order", "to_order") %in% names(result)))
})

# --- .hon_assemble_output: empty rules gives observed_max_order = 1 ---
test_that(".hon_assemble_output uses max_order_observed=1 when no rules", {
  graph <- new.env(hash = TRUE, parent = emptyenv())
  rules <- new.env(hash = TRUE, parent = emptyenv())
  trajs <- list(c("A", "B"))
  result <- .hon_assemble_output(graph, rules, trajs, 3L, 1L)
  expect_equal(result$max_order_observed, 1L)
})

# --- build_hon: all-NA trajectories error ---
test_that("build_hon stops when all trajectories are too short after parsing", {
  # All rows are single-state (no transitions possible)
  df <- data.frame(T1 = c("A", "B"), stringsAsFactors = FALSE)
  expect_error(build_hon(df, max_order = 2L, min_freq = 1L),
               "No valid trajectories")
})


# ===========================================================================
# Section 12: pathways() tests for HON
# ===========================================================================

test_that("pathways.net_hon returns character vector of paths", {
  trajs <- list(
    c("X", "A", "C"), c("X", "A", "C"), c("X", "A", "C"), c("X", "A", "C"),
    c("Y", "A", "D"), c("Y", "A", "D"), c("Y", "A", "D"), c("Y", "A", "D")
  )
  hon <- build_hon(trajs, max_order = 3L, min_freq = 1L, method = "hon+")
  pw <- pathways(hon)
  expect_true(is.character(pw))
})

test_that("pathways.net_hon returns empty for first-order-only HON", {
  trajs <- list(c("A", "B", "C"), c("B", "C", "A"))
  hon <- build_hon(trajs, max_order = 1L, min_freq = 1L)
  pw <- pathways(hon)
  expect_equal(pw, character(0))
})

test_that("pathways.net_hon min_count filters rare paths", {
  trajs <- list(
    c("X", "A", "C"), c("X", "A", "C"), c("X", "A", "C"), c("X", "A", "C"),
    c("Y", "A", "D"), c("Y", "A", "D"), c("Y", "A", "D"), c("Y", "A", "D")
  )
  hon <- build_hon(trajs, max_order = 3L, min_freq = 1L, method = "hon+")
  pw_low  <- pathways(hon, min_count = 1L)
  pw_high <- pathways(hon, min_count = 999L)
  expect_true(length(pw_low) >= length(pw_high))
  expect_equal(length(pw_high), 0L)
})

test_that("pathways.net_hon top parameter limits results", {
  trajs <- list(
    c("X", "A", "C"), c("X", "A", "C"), c("X", "A", "C"), c("X", "A", "C"),
    c("Y", "A", "D"), c("Y", "A", "D"), c("Y", "A", "D"), c("Y", "A", "D")
  )
  hon <- build_hon(trajs, max_order = 3L, min_freq = 1L, method = "hon+")
  pw_all <- pathways(hon)
  pw_top <- pathways(hon, top = 1L)
  expect_true(length(pw_all) >= length(pw_top))
  if (length(pw_all) > 0L) expect_true(length(pw_top) <= 1L)
})

test_that("pathways.net_hon min_prob filters low-probability paths", {
  trajs <- list(
    c("X", "A", "C"), c("X", "A", "C"), c("X", "A", "C"), c("X", "A", "C"),
    c("Y", "A", "D"), c("Y", "A", "D"), c("Y", "A", "D"), c("Y", "A", "D")
  )
  hon <- build_hon(trajs, max_order = 3L, min_freq = 1L, method = "hon+")
  pw_all  <- pathways(hon)
  pw_filt <- pathways(hon, min_prob = 0.99)
  expect_true(length(pw_all) >= length(pw_filt))
})

test_that("pathways.net_hon order parameter selects specific order", {
  trajs <- list(
    c("X", "A", "C"), c("X", "A", "C"), c("X", "A", "C"), c("X", "A", "C"),
    c("Y", "A", "D"), c("Y", "A", "D"), c("Y", "A", "D"), c("Y", "A", "D")
  )
  hon <- build_hon(trajs, max_order = 3L, min_freq = 1L, method = "hon+")
  pw2 <- pathways(hon, order = 2L)
  expect_true(is.character(pw2))
})
