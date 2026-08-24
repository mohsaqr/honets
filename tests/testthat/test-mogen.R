testthat::skip_on_cran()

# ===========================================================================
# Section 1: Internal — .mogen_count_kgrams
# ===========================================================================

test_that(".mogen_count_kgrams counts 1-grams correctly", {
  trajs <- list(c("A", "B", "C"), c("A", "B", "D"))
  kg <- .mogen_count_kgrams(trajs, 1L)

  expect_true("A" %in% kg$nodes)
  expect_true("B" %in% kg$nodes)
  expect_true("C" %in% kg$nodes)
  expect_true("D" %in% kg$nodes)

  # Transitions: A->B(x2), B->C(x1), B->D(x1), C->D(0) etc
  ab <- kg$edges[kg$edges$from == "A" & kg$edges$to == "B", "weight"]
  expect_equal(ab, 2L)
  bc <- kg$edges[kg$edges$from == "B" & kg$edges$to == "C", "weight"]
  expect_equal(bc, 1L)
})

test_that(".mogen_count_kgrams counts 2-grams correctly", {
  trajs <- list(c("A", "B", "C", "D"), c("A", "B", "D", "C"))
  kg <- .mogen_count_kgrams(trajs, 2L)

  sep <- .HON_SEP
  # 2-grams from traj 1: A.B, B.C, C.D
  # 2-grams from traj 2: A.B, B.D, D.C
  ab <- paste("A", "B", sep = sep)
  bc <- paste("B", "C", sep = sep)
  bd <- paste("B", "D", sep = sep)

  expect_true(ab %in% kg$nodes)
  expect_true(bc %in% kg$nodes)
  expect_true(bd %in% kg$nodes)

  # A.B appears in both trajectories
  expect_equal(unname(kg$node_counts[ab]), 2L)

  # Transitions: A.B -> B.C (x1), A.B -> B.D (x1)
  ab_bc <- kg$edges[kg$edges$from == ab & kg$edges$to == bc, "weight"]
  expect_equal(ab_bc, 1L)
  ab_bd <- kg$edges[kg$edges$from == ab & kg$edges$to == bd, "weight"]
  expect_equal(ab_bd, 1L)
})

test_that(".mogen_count_kgrams handles short trajectories", {
  trajs <- list(c("A", "B"), c("A"))  # second has length 1 < k=2
  kg <- .mogen_count_kgrams(trajs, 2L)

  # Only first trajectory contributes
  expect_equal(length(kg$nodes), 1L)  # just A.B
  expect_equal(nrow(kg$edges), 0L)    # no transitions
})

# ===========================================================================
# Section 2: Internal — .mogen_transition_matrix
# ===========================================================================

test_that(".mogen_transition_matrix builds row-stochastic matrix", {
  nodes <- c("A", "B", "C")
  edges <- data.frame(
    from = c("A", "A", "B"), to = c("B", "C", "C"),
    weight = c(3L, 1L, 2L), stringsAsFactors = FALSE
  )
  tm <- .mogen_transition_matrix(nodes, edges)

  expect_equal(dim(tm), c(3L, 3L))
  expect_equal(rownames(tm), nodes)

  # Row A: 3 to B, 1 to C => 0.75, 0.25
  expect_equal(tm["A", "B"], 0.75)
  expect_equal(tm["A", "C"], 0.25)
  # Row B: 2 to C => 1.0
  expect_equal(tm["B", "C"], 1.0)
  # Row C: no outgoing => all zeros
  expect_equal(sum(tm["C", ]), 0)
})

# ===========================================================================
# Section 3: Internal — .mogen_marginal
# ===========================================================================

test_that(".mogen_marginal computes correct probabilities", {
  trajs <- list(c("A", "B", "A"), c("B", "B"))
  m <- .mogen_marginal(trajs)

  # Total: A=2, B=3 => P(A)=2/5, P(B)=3/5
  expect_equal(unname(m["A"]), 2 / 5)
  expect_equal(unname(m["B"]), 3 / 5)
})

# ===========================================================================
# Section 4: Internal — .mogen_log_likelihood
# ===========================================================================

test_that(".mogen_log_likelihood computes correct value for order 1", {
  trajs <- list(c("A", "B", "C"))
  marginal <- c(A = 1 / 3, B = 1 / 3, C = 1 / 3)

  # Order-1 transition matrix: deterministic
  tm1 <- matrix(c(0, 1, 0, 0, 0, 1, 0, 0, 0), 3, 3, byrow = TRUE,
                dimnames = list(c("A", "B", "C"), c("A", "B", "C")))

  trans_mats <- list(marginal, tm1)

  ll <- .mogen_log_likelihood(trajs, 1L, trans_mats)

  # Expected: log(1/3) + log(T[A,B]) + log(T[B,C]) = log(1/3) + 0 + 0
  expect_equal(ll, log(1 / 3))
})

test_that(".mogen_log_likelihood uses hierarchy for order 2", {
  trajs <- list(c("A", "B", "C", "D"))
  marginal <- c(A = 0.25, B = 0.25, C = 0.25, D = 0.25)

  # Order-1: A->B(1), B->C(1), C->D(1)
  tm1 <- matrix(0, 4, 4, dimnames = list(LETTERS[1:4], LETTERS[1:4]))
  tm1["A", "B"] <- 1
  tm1["B", "C"] <- 1
  tm1["C", "D"] <- 1

  # Order-2
  sep <- .HON_SEP
  nodes2 <- c(paste("A", "B", sep = sep), paste("B", "C", sep = sep),
              paste("C", "D", sep = sep))
  tm2 <- matrix(0, 3, 3, dimnames = list(nodes2, nodes2))
  tm2[1, 2] <- 1  # A.B -> B.C
  tm2[2, 3] <- 1  # B.C -> C.D

  trans_mats <- list(marginal, tm1, tm2)

  ll <- .mogen_log_likelihood(trajs, 2L, trans_mats)

  # Step 1: log P(A) = log(0.25)
  # Step 2: order min(1,2)=1, log T^1[A,B] = log(1) = 0
  # Step 3: order min(2,2)=2, log T^2[A.B, B.C] = log(1) = 0
  # Step 4: order min(3,2)=2, log T^2[B.C, C.D] = log(1) = 0
  expect_equal(ll, log(0.25))
})

# ===========================================================================
# Section 5: Internal — .mogen_layer_dof
# ===========================================================================

test_that(".mogen_layer_dof computes correct DOF", {
  # 3x3 matrix with 2 non-zero per row
  tm <- matrix(c(0.5, 0.5, 0, 0, 0.3, 0.7, 0, 0, 0), 3, 3, byrow = TRUE)
  expect_equal(.mogen_layer_dof(tm), 2L)  # (2-1) + (2-1) + (0) = 2

  # Identity-like: 1 non-zero per row
  tm2 <- diag(3)
  expect_equal(.mogen_layer_dof(tm2), 0L)  # (1-1)*3 = 0

  # Full 2x2
  tm3 <- matrix(c(0.6, 0.4, 0.3, 0.7), 2, 2, byrow = TRUE)
  expect_equal(.mogen_layer_dof(tm3), 2L)  # (2-1)*2 = 2
})

# ===========================================================================
# Section 6: build_mogen end-to-end
# ===========================================================================

test_that("build_mogen returns net_mogen class", {
  trajs <- list(c("A", "B", "C", "D"), c("A", "B", "D", "C"),
                c("B", "C", "D", "A"), c("C", "D", "A", "B"))
  m <- build_mogen(trajs, max_order = 3L)

  expect_s3_class(m, "net_mogen")
  expect_true(m$optimal_order %in% 0L:3L)
  expect_equal(length(m$aic), 4L)  # orders 0-3
  expect_equal(length(m$transition_matrices), 4L)
  expect_equal(m$n_paths, 4L)
})

test_that("build_mogen selects order 1 for first-order Markov data", {
  # Generate data from a known order-1 model
  set.seed(42)
  states <- c("A", "B", "C")
  tm <- matrix(c(0.1, 0.7, 0.2,
                 0.3, 0.1, 0.6,
                 0.5, 0.3, 0.2), 3, 3, byrow = TRUE,
               dimnames = list(states, states))

  # Generate 200 paths of length 20
  trajs <- lapply(seq_len(200L), function(i) {
    path <- character(20L)
    path[1L] <- sample(states, 1)
    vapply(2L:20L, function(t) {
      path[t] <<- sample(states, 1, prob = tm[path[t - 1L], ])
      ""
    }, character(1L))
    path
  })

  m <- build_mogen(trajs, max_order = 3L, criterion = "bic")

  # BIC should select order 1 (data is first-order Markov)
  expect_equal(m$optimal_order, 1L)
})

test_that("build_mogen selects higher order for second-order data", {
  # Data with strong second-order dependency
  set.seed(123)
  trajs <- lapply(seq_len(300L), function(i) {
    path <- character(15L)
    path[1L] <- sample(c("A", "B", "C"), 1)
    path[2L] <- sample(c("A", "B", "C"), 1)
    vapply(3L:15L, function(t) {
      # After A->B: always go to C
      # After C->B: always go to A
      # Otherwise: uniform
      prev2 <- path[t - 2L]
      prev1 <- path[t - 1L]
      if (prev2 == "A" && prev1 == "B") {
        path[t] <<- "C"
      } else if (prev2 == "C" && prev1 == "B") {
        path[t] <<- "A"
      } else {
        path[t] <<- sample(c("A", "B", "C"), 1)
      }
      ""
    }, character(1L))
    path
  })

  m <- build_mogen(trajs, max_order = 4L, criterion = "aic")

  # Should detect order >= 2 due to second-order dependency

  expect_true(m$optimal_order >= 2L)
})

test_that("build_mogen handles data.frame input", {
  df <- data.frame(T1 = c("A", "B"), T2 = c("B", "C"),
                   T3 = c("C", "A"), T4 = c("D", "B"))
  m <- build_mogen(df, max_order = 2L)
  expect_s3_class(m, "net_mogen")
})

test_that("build_mogen caps max_order at path length", {
  trajs <- list(c("A", "B", "C"))  # length 3
  expect_message(build_mogen(trajs, max_order = 10L), "capped")
})

test_that("build_mogen LRT criterion works", {
  trajs <- list(c("A", "B", "C", "D"), c("A", "B", "D", "C"),
                c("B", "C", "D", "A"), c("C", "D", "A", "B"))
  m <- build_mogen(trajs, max_order = 2L, criterion = "lrt")

  expect_s3_class(m, "net_mogen")
  expect_true(m$optimal_order %in% 0L:2L)
  expect_equal(m$criterion, "lrt")
})

test_that("build_mogen log_likelihoods increase with order", {
  set.seed(42)
  trajs <- lapply(seq_len(50L), function(i) {
    sample(LETTERS[1:5], 10, replace = TRUE)
  })
  m <- build_mogen(trajs, max_order = 3L)

  # Log-likelihood should generally increase with order
  # (more parameters = better fit)
  ll <- m$log_likelihood
  expect_true(ll[2] >= ll[1])  # order 1 >= order 0
})

# ===========================================================================
# Section 7: S3 methods
# ===========================================================================

test_that("print.net_mogen works", {
  trajs <- list(c("A", "B", "C"), c("B", "C", "A"))
  m <- build_mogen(trajs, max_order = 2L)
  out <- capture.output(print(m))
  expect_true(any(grepl("MOGen", out)))
})

test_that("summary.net_mogen works", {
  trajs <- list(c("A", "B", "C"), c("B", "C", "A"))
  m <- build_mogen(trajs, max_order = 2L)
  out <- capture.output(summary(m))
  expect_true(any(grepl("order", out)))
})

test_that("plot.net_mogen works", {
  trajs <- list(c("A", "B", "C", "D"), c("B", "C", "D", "A"))
  m <- build_mogen(trajs, max_order = 2L)
  expect_no_error(plot(m))
  expect_no_error(plot(m, type = "likelihood"))
})

# ===========================================================================
# Section 8: Input validation
# ===========================================================================

test_that("build_mogen rejects invalid input", {
  expect_error(build_mogen(42), "data.frame or list")
  expect_error(build_mogen(list(c("A", "B")), max_order = 0L), "max_order")
})

test_that("build_mogen AIC decreases then increases", {
  # With enough data, AIC should show U-shape: decrease then increase
  set.seed(42)
  states <- c("A", "B", "C", "D")
  trajs <- lapply(seq_len(100L), function(i) {
    sample(states, 8, replace = TRUE)
  })
  m <- build_mogen(trajs, max_order = 5L)

  # DOF should increase with order
  expect_true(all(diff(m$dof) >= 0))
})

# ===========================================================================
# Section 9: Coverage for previously uncovered paths
# ===========================================================================

# --- .mogen_log_likelihood: empty trajectory returns 0 ---
test_that(".mogen_log_likelihood handles empty trajectory", {
  trajs <- list(character(0L))
  marginal <- c(A = 0.5, B = 0.5)
  tm1 <- matrix(c(0, 1, 1, 0), 2, 2, byrow = TRUE,
                dimnames = list(c("A", "B"), c("A", "B")))
  trans_mats <- list(marginal, tm1)
  ll <- .mogen_log_likelihood(trajs, 1L, trans_mats)
  expect_equal(ll, 0)
})

# --- .mogen_log_likelihood: single-state trajectory returns just log(p0) ---
test_that(".mogen_log_likelihood handles single-state trajectory", {
  trajs <- list(c("A"))
  marginal <- c(A = 0.6, B = 0.4)
  tm1 <- matrix(c(0, 1, 1, 0), 2, 2, byrow = TRUE,
                dimnames = list(c("A", "B"), c("A", "B")))
  trans_mats <- list(marginal, tm1)
  ll <- .mogen_log_likelihood(trajs, 1L, trans_mats)
  expect_equal(ll, log(0.6))
})

# --- .mogen_log_likelihood: order_used == 0 branch (k=0, step >= 2) ---
test_that(".mogen_log_likelihood uses marginal at order 0 for all steps", {
  trajs <- list(c("A", "B", "A"))
  marginal <- c(A = 0.6, B = 0.4)
  trans_mats <- list(marginal)  # only order 0
  ll <- .mogen_log_likelihood(trajs, 0L, trans_mats)
  expected <- log(0.6) + log(0.4) + log(0.6)
  expect_equal(ll, expected, tolerance = 1e-10)
})

# --- .mogen_log_likelihood: key not in trans_mat uses log_eps ---
test_that(".mogen_log_likelihood uses log_eps for missing key", {
  trajs <- list(c("A", "B", "C"))
  marginal <- c(A = 1 / 3, B = 1 / 3, C = 1 / 3)
  # Empty tm1: no transitions recorded
  tm1 <- matrix(0, 3, 3, dimnames = list(c("A", "B", "C"), c("A", "B", "C")))
  trans_mats <- list(marginal, tm1)
  ll <- .mogen_log_likelihood(trajs, 1L, trans_mats)
  log_eps <- log(.Machine$double.eps)
  # Step 1: log(1/3), steps 2-3: log_eps each (missing keys → zero probs)
  expected <- log(1 / 3) + log_eps + log_eps
  expect_equal(ll, expected, tolerance = 1e-10)
})

# --- build_mogen: no valid trajectories ---
test_that("build_mogen stops when no valid trajectories", {
  df <- data.frame(T1 = c("A", "B"), stringsAsFactors = FALSE)
  expect_error(build_mogen(df, max_order = 2L), "No valid trajectories")
})

# --- mogen_transitions: default order (NULL) uses optimal_order ---
test_that("mogen_transitions defaults to optimal_order when order=NULL", {
  trajs <- list(c("A", "B", "C", "D"), c("A", "B", "D", "C"),
                c("B", "C", "D", "A"), c("C", "D", "A", "B"))
  m <- build_mogen(trajs, max_order = 2L)
  tr_default <- mogen_transitions(m)
  tr_explicit <- mogen_transitions(m, order = m$optimal_order)
  expect_equal(nrow(tr_default), nrow(tr_explicit))
})

# --- mogen_transitions: empty return when min_count filters all ---
test_that("mogen_transitions returns empty data.frame when all filtered", {
  trajs <- list(c("A", "B", "C"), c("B", "C", "A"))
  m <- build_mogen(trajs, max_order = 1L)
  tr <- mogen_transitions(m, order = 1L, min_count = 9999L)
  expect_true(is.data.frame(tr))
  expect_equal(nrow(tr), 0L)
  expect_true(all(c("path", "count", "probability", "from", "to") %in%
                    names(tr)))
})

# --- path_counts: data.frame input branch ---
test_that("path_counts works with data.frame input", {
  df <- data.frame(T1 = c("A", "B"), T2 = c("B", "C"),
                   T3 = c("C", "A"), stringsAsFactors = FALSE)
  result <- path_counts(df, k = 2L)
  expect_true(is.data.frame(result))
  expect_true(all(c("path", "count", "proportion") %in% names(result)))
  expect_true(nrow(result) > 0L)
})

# --- path_counts: list input branch ---
test_that("path_counts works with list input", {
  trajs <- list(c("A", "B", "C"), c("A", "B", "D"))
  result <- path_counts(trajs, k = 2L)
  expect_true(is.data.frame(result))
  expect_true(nrow(result) > 0L)
})

# --- path_counts: trajectories shorter than k contribute nothing ---
test_that("path_counts handles trajectories shorter than k", {
  trajs <- list(c("A"), c("B"), c("A", "B", "C"))
  result <- path_counts(trajs, k = 3L)
  # Only the third trajectory contributes 1 path: A -> B -> C
  expect_equal(nrow(result), 1L)
  expect_equal(result$count[1L], 1L)
})

# --- path_counts: top parameter limits output ---
test_that("path_counts top parameter limits rows returned", {
  trajs <- list(c("A", "B", "C", "D"), c("A", "B", "D", "C"))
  result_all <- path_counts(trajs, k = 2L)
  result_top <- path_counts(trajs, k = 2L, top = 1L)
  expect_equal(nrow(result_top), 1L)
  expect_true(nrow(result_all) >= nrow(result_top))
})

# --- path_counts: k must be >= 2 ---
test_that("path_counts rejects k < 2", {
  trajs <- list(c("A", "B", "C"))
  expect_error(path_counts(trajs, k = 1L), "k.*must be >= 2")
})

# --- path_counts: NA handling ---
test_that("path_counts handles NAs in trajectories", {
  trajs <- list(c("A", "B", NA, "C", "D"), c("A", NA, "B"))
  result <- path_counts(trajs, k = 2L)
  expect_true(is.data.frame(result))
  # NAs stripped: first traj becomes c("A","B","C","D") → 3 bigrams
  # second becomes c("A","B") → 1 bigram
  expect_true(nrow(result) > 0L)
  # No NA in path column
  expect_false(any(grepl("NA", result$path, fixed = TRUE)))
})

# --- print.net_mogen: LRT criterion branch uses AIC label ---
test_that("print.net_mogen displays AIC when criterion is 'lrt'", {
  trajs <- list(c("A", "B", "C", "D"), c("A", "B", "D", "C"),
                c("B", "C", "D", "A"), c("C", "D", "A", "B"))
  m <- build_mogen(trajs, max_order = 2L, criterion = "lrt")
  out <- capture.output(print(m))
  expect_true(any(grepl("AIC|lrt", out)))
})


# ===========================================================================
# Section 10: pathways() tests for MOGen
# ===========================================================================

test_that("pathways.net_mogen returns character vector", {
  set.seed(42)
  trajs <- lapply(seq_len(30L), function(i) sample(LETTERS[1:4], 6, replace = TRUE))
  m <- build_mogen(trajs, max_order = 2L)
  pw <- pathways(m)
  expect_true(is.character(pw))
})

test_that("pathways.net_mogen order=0 returns empty character", {
  trajs <- list(c("A", "B", "C"), c("B", "C", "A"))
  m <- build_mogen(trajs, max_order = 1L)
  pw <- pathways(m, order = 0L)
  expect_equal(pw, character(0))
})

test_that("pathways.net_mogen min_count filters paths", {
  set.seed(42)
  trajs <- lapply(seq_len(30L), function(i) sample(LETTERS[1:4], 6, replace = TRUE))
  m <- build_mogen(trajs, max_order = 2L)
  pw_all  <- pathways(m, min_count = 1L)
  pw_filt <- pathways(m, min_count = 9999L)
  expect_equal(length(pw_filt), 0L)
  expect_true(length(pw_all) >= length(pw_filt))
})

test_that("pathways.net_mogen top limits output", {
  set.seed(42)
  trajs <- lapply(seq_len(30L), function(i) sample(LETTERS[1:4], 6, replace = TRUE))
  m <- build_mogen(trajs, max_order = 2L)
  pw_top <- pathways(m, top = 2L)
  expect_true(length(pw_top) <= 2L)
})

test_that("pathways.net_mogen min_prob filters by probability", {
  set.seed(42)
  trajs <- lapply(seq_len(30L), function(i) sample(LETTERS[1:4], 6, replace = TRUE))
  m <- build_mogen(trajs, max_order = 2L)
  pw_all  <- pathways(m, min_prob = 0)
  pw_filt <- pathways(m, min_prob = 0.99)
  expect_true(length(pw_all) >= length(pw_filt))
})
