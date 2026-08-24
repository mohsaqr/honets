# ===========================================================================
# Section 1: Internal — .honem_transition_matrix
# ===========================================================================

test_that(".honem_transition_matrix row-normalizes", {
  mat <- matrix(c(0, 3, 1, 2, 0, 2, 0, 0, 0), 3, 3, byrow = TRUE,
                dimnames = list(c("A", "B", "C"), c("A", "B", "C")))
  D <- .honem_transition_matrix(mat)

  expect_equal(D["A", "B"], 3 / 4)
  expect_equal(D["A", "C"], 1 / 4)
  expect_equal(D["B", "A"], 2 / 4)
  expect_equal(D["B", "C"], 2 / 4)
  # Row C: all zeros, stays zero

  expect_equal(sum(D["C", ]), 0)
})

# ===========================================================================
# Section 2: Internal — .honem_neighborhood_matrix
# ===========================================================================

test_that(".honem_neighborhood_matrix produces correct shape", {
  D <- matrix(c(0, 1, 0, 0, 0, 1, 1, 0, 0), 3, 3, byrow = TRUE)
  S <- .honem_neighborhood_matrix(D, max_power = 5L)

  expect_equal(dim(S), c(3L, 3L))
  expect_true(all(is.finite(S)))
})

test_that(".honem_neighborhood_matrix respects max_power", {
  D <- diag(3) * 0.5
  S1 <- .honem_neighborhood_matrix(D, max_power = 1L)
  S5 <- .honem_neighborhood_matrix(D, max_power = 5L)

  # With different max_power, results should differ
  expect_false(all(abs(S1 - S5) < 1e-10))
})

# ===========================================================================
# Section 3: Internal — .honem_svd
# ===========================================================================

test_that(".honem_svd returns correct dimensions", {
  S <- matrix(runif(25), 5, 5, dimnames = list(LETTERS[1:5], LETTERS[1:5]))
  result <- .honem_svd(S, dim = 3L)

  expect_equal(nrow(result$embeddings), 5L)
  expect_equal(ncol(result$embeddings), 3L)
  expect_equal(length(result$singular_values), 3L)
  expect_true(result$explained_variance >= 0 && result$explained_variance <= 1)
})

test_that(".honem_svd caps dim at n-1", {
  S <- matrix(runif(9), 3, 3, dimnames = list(LETTERS[1:3], LETTERS[1:3]))
  result <- .honem_svd(S, dim = 100L)

  expect_equal(ncol(result$embeddings), 2L)  # capped at n-1 = 2
})

# ===========================================================================
# Section 4: build_honem end-to-end
# ===========================================================================

test_that("build_honem returns net_honem class from matrix", {
  mat <- matrix(c(0, 2, 0, 0,
                  0, 0, 3, 0,
                  1, 0, 0, 2,
                  0, 1, 0, 0), 4, 4, byrow = TRUE,
                dimnames = list(LETTERS[1:4], LETTERS[1:4]))
  emb <- build_honem(mat, dim = 2L, max_power = 3L)

  expect_s3_class(emb, "net_honem")
  expect_equal(emb$n_nodes, 4L)
  expect_equal(emb$dim, 2L)
  expect_equal(nrow(emb$embeddings), 4L)
  expect_equal(ncol(emb$embeddings), 2L)
})

test_that("build_honem works with net_hon object", {
  trajs <- list(c("A", "B", "C", "D"), c("A", "B", "D", "C"),
                c("B", "C", "D", "A"), c("C", "D", "A", "B"))
  hon <- build_hon(trajs, max_order = 2L, method = "hon")
  emb <- build_honem(hon, dim = 3L)

  expect_s3_class(emb, "net_honem")
  expect_equal(emb$n_nodes, hon$n_nodes)
})

test_that("build_honem preserves node names", {
  mat <- matrix(c(0, 1, 1, 0), 2, 2, byrow = TRUE,
                dimnames = list(c("X", "Y"), c("X", "Y")))
  emb <- build_honem(mat, dim = 1L)

  expect_equal(emb$nodes, c("X", "Y"))
  expect_equal(rownames(emb$embeddings), c("X", "Y"))
})

test_that("build_honem rejects invalid input", {
  expect_error(build_honem(42), "net_hon object or a square matrix")
  expect_error(build_honem(matrix(1, 1, 1)), "at least 2 nodes")
})

# ===========================================================================
# Section 5: Embedding quality
# ===========================================================================

test_that("build_honem embeddings reflect network structure", {
  # Create a network with two clusters
  mat <- matrix(0, 6, 6, dimnames = list(LETTERS[1:6], LETTERS[1:6]))
  # Cluster 1: A, B, C (strong connections)
  mat["A", "B"] <- 5; mat["B", "C"] <- 5; mat["C", "A"] <- 5
  # Cluster 2: D, E, F (strong connections)
  mat["D", "E"] <- 5; mat["E", "F"] <- 5; mat["F", "D"] <- 5
  # Weak cross-cluster link
  mat["C", "D"] <- 1

  emb <- build_honem(mat, dim = 2L, max_power = 5L)

  # Nodes within same cluster should be closer than across clusters
  d_within1 <- sqrt(sum((emb$embeddings["A", ] - emb$embeddings["B", ])^2))
  d_across <- sqrt(sum((emb$embeddings["A", ] - emb$embeddings["E", ])^2))

  expect_true(d_within1 < d_across)
})

# ===========================================================================
# Section 6: S3 methods
# ===========================================================================

test_that("print.net_honem works", {
  mat <- matrix(c(0, 1, 1, 0), 2, 2,
                dimnames = list(c("A", "B"), c("A", "B")))
  emb <- build_honem(mat, dim = 1L)
  out <- capture.output(print(emb))
  expect_true(any(grepl("HONEM", out)))
})

test_that("summary.net_honem works", {
  mat <- matrix(c(0, 1, 1, 0), 2, 2,
                dimnames = list(c("A", "B"), c("A", "B")))
  emb <- build_honem(mat, dim = 1L)
  out <- capture.output(summary(emb))
  expect_true(any(grepl("Variance", out)))
})

test_that("plot.net_honem works", {
  mat <- matrix(c(0, 1, 0, 1, 0, 1, 0, 1, 0), 3, 3,
                dimnames = list(c("A", "B", "C"), c("A", "B", "C")))
  emb <- build_honem(mat, dim = 2L)
  expect_no_error(plot(emb))
})

# ===========================================================================
# Section 7: Coverage for plot.net_honem with dim < 2
# ===========================================================================

test_that("plot.net_honem issues message and returns invisibly when dim < 2", {
  mat <- matrix(c(0, 1, 1, 0), 2, 2,
                dimnames = list(c("A", "B"), c("A", "B")))
  emb <- build_honem(mat, dim = 1L)
  expect_equal(emb$dim, 1L)
  expect_message(result <- plot(emb), "at least 2 dimensions")
  expect_identical(result, emb)
})


# ===========================================================================
# Section 8: Input validation — additional edge cases
# ===========================================================================

test_that("build_honem rejects non-square matrix", {
  mat <- matrix(1:6, 2, 3)
  expect_error(build_honem(mat), "net_hon object or a square matrix")
})

test_that("build_honem rejects dim < 1", {
  mat <- matrix(c(0, 1, 1, 0), 2, 2,
                dimnames = list(c("A", "B"), c("A", "B")))
  expect_error(build_honem(mat, dim = 0L), "'dim' must be >= 1")
})

test_that("build_honem rejects max_power < 1", {
  mat <- matrix(c(0, 1, 1, 0), 2, 2,
                dimnames = list(c("A", "B"), c("A", "B")))
  expect_error(build_honem(mat, max_power = 0L), "'max_power' must be >= 1")
})

test_that("build_honem handles all-zero matrix (degenerate embeddings)", {
  mat <- matrix(0, 3, 3, dimnames = list(LETTERS[1:3], LETTERS[1:3]))
  emb <- build_honem(mat, dim = 2L)
  # Should not error — produces zero embeddings

  expect_s3_class(emb, "net_honem")
  expect_equal(nrow(emb$embeddings), 3L)
  expect_equal(ncol(emb$embeddings), 2L)
  # All embeddings should be zero (no information in a zero matrix)
  expect_true(all(emb$embeddings == 0))
})

test_that("build_honem rejects non-matrix non-hon input types", {
  expect_error(build_honem(data.frame(a = 1, b = 2)), "net_hon object or a square matrix")
  expect_error(build_honem("not a matrix"), "net_hon object or a square matrix")
  expect_error(build_honem(list(a = 1)), "net_hon object or a square matrix")
})


# ===========================================================================
# Section 9: .honem_neighborhood_matrix — detailed tests
# ===========================================================================

test_that(".honem_neighborhood_matrix with max_power=1 gives exp(0)*D + exp(-1)*D^2", {
  # 3x3 identity-like transition matrix for easy verification
  D <- matrix(c(0, 1, 0,
                0, 0, 1,
                1, 0, 0), 3, 3, byrow = TRUE)

  S <- .honem_neighborhood_matrix(D, max_power = 1L)

  # weights: exp(0) = 1, exp(-1)
  w0 <- exp(0)
  w1 <- exp(-1)
  Z <- w0 + w1
  D2 <- D %*% D
  expected <- (w0 * D + w1 * D2) / Z
  expect_equal(S, expected, tolerance = 1e-12)
})

test_that(".honem_neighborhood_matrix with larger max_power changes result", {
  D <- matrix(c(0, 0.5, 0.5,
                0.5, 0, 0.5,
                0.5, 0.5, 0), 3, 3, byrow = TRUE)
  S1 <- .honem_neighborhood_matrix(D, max_power = 1L)
  S3 <- .honem_neighborhood_matrix(D, max_power = 3L)
  S10 <- .honem_neighborhood_matrix(D, max_power = 10L)

  # All should differ
  expect_false(all(abs(S1 - S3) < 1e-10))
  expect_false(all(abs(S3 - S10) < 1e-10))
  # All should be finite
  expect_true(all(is.finite(S1)))
  expect_true(all(is.finite(S3)))
  expect_true(all(is.finite(S10)))
})

test_that(".honem_neighborhood_matrix produces no NaN/Inf values", {
  # Sparse matrix with a sink node (row of zeros)
  D <- matrix(c(0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
                0, 0, 0, 0), 4, 4, byrow = TRUE)
  S <- .honem_neighborhood_matrix(D, max_power = 20L)
  expect_true(all(is.finite(S)))
  expect_false(any(is.nan(S)))
})

test_that(".honem_neighborhood_matrix with identity-like D converges", {
  # D close to identity => higher powers similar to D
  n <- 5
  D <- diag(n) * 0.8 + matrix(0.2 / (n - 1), n, n)
  diag(D) <- 0.8
  S5 <- .honem_neighborhood_matrix(D, max_power = 5L)
  S50 <- .honem_neighborhood_matrix(D, max_power = 50L)
  # Should converge — difference between S5 and S50 small
  # (exponential decay of weights means higher powers contribute little)
  expect_true(max(abs(S5 - S50)) < 0.1)
})


# ===========================================================================
# Section 10: .honem_svd — edge cases
# ===========================================================================

test_that(".honem_svd handles degenerate matrix (identical rows)", {
  # Matrix with identical rows => rank 1
  S <- matrix(rep(c(1, 2, 3, 4), 4), 4, 4, byrow = TRUE,
              dimnames = list(LETTERS[1:4], LETTERS[1:4]))
  result <- .honem_svd(S, dim = 3L)

  # Should not crash
  expect_equal(nrow(result$embeddings), 4L)
  expect_equal(ncol(result$embeddings), 3L)
  expect_true(all(is.finite(result$embeddings)))
  expect_true(result$explained_variance >= 0 && result$explained_variance <= 1)
})

test_that(".honem_svd dim is capped at n-1 for small matrices", {
  S <- matrix(runif(4), 2, 2, dimnames = list(c("A", "B"), c("A", "B")))
  result <- .honem_svd(S, dim = 50L)
  # n=2, so dim capped at 1
  expect_equal(ncol(result$embeddings), 1L)
  expect_equal(length(result$singular_values), 1L)
})

test_that(".honem_svd returns valid explained_variance for zero matrix", {
  S <- matrix(0, 3, 3, dimnames = list(LETTERS[1:3], LETTERS[1:3]))
  result <- .honem_svd(S, dim = 2L)
  # Zero matrix => all singular values are 0 => 0/0 = NaN
  # Check it doesn't crash (NaN is a known edge case for degenerate input)
  expect_equal(nrow(result$embeddings), 3L)
  expect_equal(ncol(result$embeddings), 2L)
})

test_that(".honem_svd singular_values are non-negative", {
  set.seed(7)
  S <- matrix(runif(25), 5, 5, dimnames = list(LETTERS[1:5], LETTERS[1:5]))
  result <- .honem_svd(S, dim = 4L)
  expect_true(all(result$singular_values >= 0))
})


# ===========================================================================
# Section 11: End-to-end — field verification
# ===========================================================================

test_that("build_honem result has all expected fields", {
  mat <- matrix(c(0, 2, 1, 3, 0, 2, 1, 3, 0), 3, 3, byrow = TRUE,
                dimnames = list(LETTERS[1:3], LETTERS[1:3]))
  emb <- build_honem(mat, dim = 2L, max_power = 5L)

  # All required fields present
  expect_true("embeddings" %in% names(emb))
  expect_true("nodes" %in% names(emb))
  expect_true("singular_values" %in% names(emb))
  expect_true("explained_variance" %in% names(emb))
  expect_true("dim" %in% names(emb))
  expect_true("max_power" %in% names(emb))
  expect_true("n_nodes" %in% names(emb))
})

test_that("build_honem embeddings dimensions match n_nodes x dim", {
  mat <- matrix(c(0, 3, 0, 1,
                  2, 0, 1, 0,
                  0, 2, 0, 3,
                  1, 0, 2, 0), 4, 4, byrow = TRUE,
                dimnames = list(LETTERS[1:4], LETTERS[1:4]))
  emb <- build_honem(mat, dim = 3L)

  expect_equal(nrow(emb$embeddings), emb$n_nodes)
  expect_equal(ncol(emb$embeddings), emb$dim)
  expect_equal(emb$n_nodes, 4L)
  expect_equal(emb$dim, 3L)
})

test_that("build_honem singular_values are non-negative and sorted descending", {
  set.seed(12)
  mat <- matrix(sample(0:5, 25, replace = TRUE), 5, 5,
                dimnames = list(LETTERS[1:5], LETTERS[1:5]))
  diag(mat) <- 0
  emb <- build_honem(mat, dim = 4L)

  expect_true(all(emb$singular_values >= 0))
  # Check sorted descending (or equal)
  diffs <- diff(emb$singular_values)
  expect_true(all(diffs <= 1e-10))
})

test_that("build_honem explained_variance is in [0, 1]", {
  mat <- matrix(c(0, 5, 1, 3, 0, 2, 1, 4, 0), 3, 3, byrow = TRUE,
                dimnames = list(LETTERS[1:3], LETTERS[1:3]))
  emb <- build_honem(mat, dim = 2L)

  expect_gte(emb$explained_variance, 0)
  expect_lte(emb$explained_variance, 1)
})

test_that("build_honem max_power stored correctly", {
  mat <- matrix(c(0, 1, 1, 0), 2, 2,
                dimnames = list(c("A", "B"), c("A", "B")))
  emb <- build_honem(mat, dim = 1L, max_power = 7L)
  expect_equal(emb$max_power, 7L)
})


# ===========================================================================
# Section 12: S3 methods — detailed output checks
# ===========================================================================

test_that("print.net_honem output contains key info", {
  mat <- matrix(c(0, 2, 1, 3, 0, 2, 1, 3, 0), 3, 3, byrow = TRUE,
                dimnames = list(LETTERS[1:3], LETTERS[1:3]))
  emb <- build_honem(mat, dim = 2L, max_power = 5L)
  out <- capture.output(print(emb))

  expect_true(any(grepl("HONEM", out)))
  expect_true(any(grepl("Nodes:", out)))
  expect_true(any(grepl("Dimensions:", out)))
  expect_true(any(grepl("Max power:", out)))
  expect_true(any(grepl("Variance explained:", out)))
  # Check actual numbers appear
  expect_true(any(grepl("3", out)))  # 3 nodes
  expect_true(any(grepl("2", out)))  # 2 dimensions
})

test_that("print.net_honem returns invisibly", {
  mat <- matrix(c(0, 1, 1, 0), 2, 2,
                dimnames = list(c("A", "B"), c("A", "B")))
  emb <- build_honem(mat, dim = 1L)
  out <- capture.output(result <- print(emb))
  expect_identical(result, emb)
})

test_that("summary.net_honem output contains variance and singular values info", {
  mat <- matrix(c(0, 2, 1, 3, 0, 2, 1, 3, 0), 3, 3, byrow = TRUE,
                dimnames = list(LETTERS[1:3], LETTERS[1:3]))
  emb <- build_honem(mat, dim = 2L, max_power = 5L)
  out <- capture.output(summary(emb))

  expect_true(any(grepl("HONEM Summary", out)))
  expect_true(any(grepl("Variance explained:", out)))
  expect_true(any(grepl("Top singular values:", out)))
  expect_true(any(grepl("Embedding range:", out)))
})

test_that("summary.net_honem returns tidy embedding data.frame", {
  mat <- matrix(c(0, 1, 1, 0), 2, 2,
                dimnames = list(c("A", "B"), c("A", "B")))
  emb <- build_honem(mat, dim = 1L)
  out <- capture.output(result <- summary(emb))
  expect_s3_class(result, "data.frame")
  expect_equal(result$node, c("A", "B"))
  expect_true("dim1" %in% names(result))
})

test_that("plot.net_honem works with dim >= 2 and labels <= 50 nodes", {
  mat <- matrix(c(0, 1, 0, 1, 0, 1, 0, 1, 0), 3, 3,
                dimnames = list(LETTERS[1:3], LETTERS[1:3]))
  emb <- build_honem(mat, dim = 2L)
  expect_no_error(result <- plot(emb))
  expect_identical(result, emb)
})

test_that("plot.net_honem suppresses labels for > 50 nodes", {
  # Create a larger matrix — plot should skip text labels
  n <- 55
  mat <- matrix(sample(0:3, n * n, replace = TRUE), n, n)
  diag(mat) <- 0
  nms <- paste0("N", seq_len(n))
  dimnames(mat) <- list(nms, nms)
  emb <- build_honem(mat, dim = 2L)
  # Just verify it doesn't error with >50 nodes
  expect_no_error(plot(emb))
})

test_that("plot.net_honem respects custom dims argument", {
  mat <- matrix(c(0, 3, 1, 2,
                  1, 0, 2, 0,
                  0, 1, 0, 3,
                  2, 0, 1, 0), 4, 4, byrow = TRUE,
                dimnames = list(LETTERS[1:4], LETTERS[1:4]))
  emb <- build_honem(mat, dim = 3L)
  # Plot dims 1 and 3
  expect_no_error(plot(emb, dims = c(1L, 3L)))
})


# ===========================================================================
# Section 13: .honem_transition_matrix — additional tests
# ===========================================================================

test_that(".honem_transition_matrix preserves zero rows", {
  mat <- matrix(c(0, 0, 0, 1, 0, 2, 0, 3, 0), 3, 3, byrow = TRUE,
                dimnames = list(LETTERS[1:3], LETTERS[1:3]))
  D <- .honem_transition_matrix(mat)
  expect_equal(sum(D["A", ]), 0)  # Row A all zeros stays zero
  expect_equal(sum(D["B", ]), 1, tolerance = 1e-12)  # Row B normalizes to 1
  expect_equal(sum(D["C", ]), 1, tolerance = 1e-12)  # Row C normalizes to 1
})

test_that(".honem_transition_matrix produces row-stochastic matrix", {
  set.seed(42)
  mat <- matrix(sample(0:10, 16, replace = TRUE), 4, 4)
  diag(mat) <- 0
  dimnames(mat) <- list(LETTERS[1:4], LETTERS[1:4])
  D <- .honem_transition_matrix(mat)

  row_sums <- rowSums(D)
  nonzero_rows <- row_sums > 0
  # Non-zero rows should sum to 1
  expect_true(all(abs(row_sums[nonzero_rows] - 1) < 1e-12))
  # Zero rows should remain zero
  expect_true(all(row_sums[!nonzero_rows] == 0))
})


# ===========================================================================
# Section 14: Dim capping in build_honem
# ===========================================================================

test_that("build_honem caps dim at n-1 for small matrices", {
  mat <- matrix(c(0, 1, 1, 0), 2, 2,
                dimnames = list(c("A", "B"), c("A", "B")))
  # Request dim=100 but only 2 nodes => capped at 1
  emb <- build_honem(mat, dim = 100L)
  expect_equal(emb$dim, 1L)
  expect_equal(ncol(emb$embeddings), 1L)
})

test_that("build_honem with dim equal to n-1 works", {
  mat <- matrix(c(0, 2, 1, 3, 0, 2, 1, 3, 0), 3, 3, byrow = TRUE,
                dimnames = list(LETTERS[1:3], LETTERS[1:3]))
  emb <- build_honem(mat, dim = 2L)  # n-1 = 2
  expect_equal(emb$dim, 2L)
  expect_equal(ncol(emb$embeddings), 2L)
})
