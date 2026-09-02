# HyperGAT: the layer is checked against an independent plain-R
# re-implementation of the official math (double precision), the verb
# end-to-end for shape, determinism, sentence-set invariance and fit.
# Forward parity with the official PyTorch layer lives in
# local_testing_and_equivalence/test-equiv-hypergat-official.R.

hypergat_docs <- c(
  cooking_1 = "Simmer the soup slowly. Add onions and carrots to the pot.",
  cooking_2 = "This soup recipe needs salt. Serve the dish on a cold night.",
  cooking_3 = "Chop onions for the stew. Salt the broth and simmer.",
  space_1 = "The telescope revealed a distant galaxy. Stars everywhere.",
  space_2 = "Astronomers aimed the telescope. The stars were sharp.",
  space_3 = "A comet passed the galaxy. Astronomers watched the stars."
)
hypergat_labels <- c(cooking_1 = "cooking", cooking_2 = "cooking",
                     space_1 = "space", space_2 = "space")

# Plain-R double-precision reference for one dual-attention layer
# (official math, B = 1): an oracle independent of torch.
.ref_hypergat_layer <- function(x, adj, w2, w3, a, a2, ctx, w = NULL,
                                alpha = 0.2, concat = TRUE) {
  lrelu <- \(z) ifelse(z > 0, z, alpha * z)
  elu <- \(z) ifelse(z > 0, z, exp(z) - 1)
  softmax_rows <- \(m) t(apply(m, 1, \(r) exp(r - max(r)) /
                                 sum(exp(r - max(r)))))
  out_f <- ncol(w2)
  x4 <- x %*% w2
  val <- if (is.null(w)) x else x %*% w
  a_top <- a[seq_len(out_f), , drop = FALSE]
  a_bot <- a[out_f + seq_len(out_f), , drop = FALSE]
  s_node <- lrelu(as.numeric(x4 %*% a_bot) + as.numeric(ctx %*% a_top))
  e_scores <- matrix(s_node, nrow = nrow(adj), ncol = nrow(x),
                     byrow = TRUE)
  att_edge <- softmax_rows(ifelse(adj > 0, e_scores, -9e15))
  edge <- att_edge %*% val
  e4 <- edge %*% w3
  a2_top <- a2[seq_len(out_f), , drop = FALSE]
  a2_bot <- a2[out_f + seq_len(out_f), , drop = FALSE]
  s_pair <- lrelu(outer(as.numeric(e4 %*% a2_bot),
                        rep(1, nrow(x))) +
                    outer(rep(1, nrow(adj)), as.numeric(x4 %*% a2_top)))
  att_node <- softmax_rows(t(ifelse(adj > 0, s_pair, -9e15)))
  node <- att_node %*% edge
  if (isTRUE(concat)) elu(node) else node
}

test_that("the torch layer matches the plain-R reference math", {
  skip_if_not_installed("torch")
  set.seed(3)
  n <- 5L; e <- 3L; in_f <- 4L; out_f <- 4L
  x <- matrix(rnorm(n * in_f), n)
  adj <- matrix(0, e, n)
  adj[1, c(1, 2, 3)] <- 1
  adj[2, c(3, 4)] <- 1
  adj[3, c(1, 5)] <- 1
  w2 <- matrix(rnorm(in_f * out_f), in_f)
  w3 <- matrix(rnorm(out_f * out_f), out_f)
  a <- matrix(rnorm(2 * out_f), ncol = 1)
  a2 <- matrix(rnorm(2 * out_f), ncol = 1)
  ctx <- matrix(rnorm(out_f), nrow = 1)
  ref <- .ref_hypergat_layer(x, adj, w2, w3, a, a2, ctx, concat = TRUE)

  layer <- .thg_hypergat_layer(in_f, out_f, dropout = 0, alpha = 0.2,
                               transfer = FALSE, concat = TRUE)
  tt <- \(m) torch::torch_tensor(m, dtype = torch::torch_float())
  torch::with_no_grad({
    layer$weight2$copy_(tt(w2))
    layer$weight3$copy_(tt(w3))
    layer$a$copy_(tt(a))
    layer$a2$copy_(tt(a2))
    layer$word_context$copy_(tt(ctx))
  })
  layer$eval()
  got <- torch::with_no_grad(
    as.array(layer(tt(array(x, c(1, n, in_f))),
                   tt(array(adj, c(1, e, n)))))
  )
  expect_equal(got[1, , ], ref, tolerance = 1e-5)
})

test_that("hg_hypergat trains, predicts every document, deterministic", {
  skip_if_not_installed("torch")
  fit <- hg_hypergat(hypergat_docs, labels = hypergat_labels,
                     embed_dim = 16, hidden = 8, epochs = 30, lr = 0.05,
                     validation = 0, seed = 1)
  expect_s3_class(fit, "data.frame")
  expect_identical(nrow(fit), 6L)
  expect_named(fit, c("node", "label", "predicted", "score", "margin"))
  # enough capacity and epochs to fit the four labeled documents
  labeled <- subset(fit, !is.na(label))
  expect_identical(labeled$predicted, unname(hypergat_labels[labeled$node]))
  history <- attr(fit, "history")
  expect_identical(nrow(history), 30L)
  expect_lt(history$loss[30L], history$loss[1L])
  refit <- hg_hypergat(hypergat_docs, labels = hypergat_labels,
                       embed_dim = 16, hidden = 8, epochs = 30, lr = 0.05,
                       validation = 0, seed = 1)
  expect_identical(fit$predicted, refit$predicted)
  expect_equal(fit$score, refit$score, tolerance = 1e-12)
})

test_that("predictions are invariant to word order within sentences", {
  skip_if_not_installed("torch")
  shuffled <- c(
    cooking_1 = "the Simmer slowly soup. carrots and onions Add pot to the.",
    cooking_2 = "salt needs recipe soup This. cold a on dish the Serve night.",
    cooking_3 = "the for stew onions Chop. simmer and broth the Salt.",
    space_1 = "galaxy distant a revealed telescope The. everywhere Stars.",
    space_2 = "telescope the aimed Astronomers. sharp were stars The.",
    space_3 = "galaxy the passed comet A. stars the watched Astronomers."
  )
  fit <- hg_hypergat(hypergat_docs, labels = hypergat_labels,
                     embed_dim = 16, hidden = 8, epochs = 10,
                     validation = 0, seed = 1)
  refit <- hg_hypergat(shuffled, labels = hypergat_labels,
                       embed_dim = 16, hidden = 8, epochs = 10,
                       validation = 0, seed = 1)
  expect_identical(fit$predicted, refit$predicted)
  expect_equal(fit$score, refit$score, tolerance = 1e-5)
})

test_that("hg_hypergat argument contracts are enforced", {
  skip_if_not_installed("torch")
  expect_error(
    hg_hypergat(hypergat_docs, labels = c(cooking_1 = "x")),
    class = "honets_bad_input"
  )
  expect_error(
    hg_hypergat(hypergat_docs, labels = c(zz = "x", cooking_1 = "y")),
    "Unknown or dropped"
  )
  expect_error(
    hg_hypergat(data.frame(txt = hypergat_docs),
                labels = hypergat_labels),
    "`column` must name"
  )
  expect_warning(
    hg_hypergat(c(hypergat_docs, empty_1 = "the and of"),
                labels = hypergat_labels, embed_dim = 8, hidden = 4,
                epochs = 2, validation = 0),
    class = "honets_dropped_documents"
  )
})
