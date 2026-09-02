# Delegating verbs: parity with the hypergraph-family engines, tidy shapes, conditions.

verb_corpus <- c(
  cooking_1 = "simmer the soup with onions and carrots",
  cooking_2 = "this soup recipe needs salt on a cold night",
  space_1 = "the telescope revealed a distant galaxy and stars",
  space_2 = "astronomers aimed the telescope at the stars all night"
)
verb_stop <- c("the", "with", "and", "a", "this", "at", "on", "all")

test_that("hg_measures matches the engine and returns tidy tables", {
  hg <- text_hypergraph(verb_corpus, stop_words = verb_stop)
  m <- hypergraph_measures(hg)

  nodes <- hg_measures(hg, what = "nodes")
  expect_identical(nodes$node, names(m$hyperdegree))
  expect_identical(nodes$hyperdegree, unname(as.integer(m$hyperdegree)))
  expect_identical(nodes$strength, unname(as.numeric(m$node_strength)))
  expect_identical(nrow(nodes), hg$n_nodes)

  edges <- hg_measures(hg, what = "edges")
  expect_identical(edges$edge, colnames(hg$incidence))
  expect_identical(edges$size, unname(as.integer(m$edge_sizes)))

  overlap <- hg_measures(hg, what = "overlap")
  expect_identical(
    nrow(overlap),
    (hg$n_hyperedges * (hg$n_hyperedges - 1L)) %/% 2L
  )
  expect_true(all(overlap$jaccard >= 0 & overlap$jaccard <= 1))

  summary_tab <- hg_measures(hg, what = "summary")
  expect_identical(names(summary_tab), c("measure", "value"))
  expect_identical(
    summary_tab$value[summary_tab$measure == "n_nodes"],
    as.numeric(hg$n_nodes)
  )
})

test_that("hg_centrality matches the engine value for value", {
  hg <- text_hypergraph(verb_corpus, stop_words = verb_stop)
  direct <- hypergraph_centrality(hg, type = c("clique", "Z", "H"))

  tab <- hg_centrality(hg)
  expect_identical(names(tab), c("node", "clique", "Z", "H"))
  expect_identical(tab$node, direct$node)
  expect_identical(tab$clique, direct$clique)
  expect_identical(tab$Z, direct$Z)
  expect_identical(tab$H, direct$H)

  one <- hg_centrality(hg, type = "clique")
  expect_identical(names(one), c("node", "clique"))
})

test_that("hg_cluster matches the seeded engine partition and is reproducible", {
  hg <- text_hypergraph(verb_corpus, stop_words = verb_stop)
  direct <- hypergraph_cluster(hg, k = 2, type = "random_walk",
                                          seed = 7)
  expected <- direct$clusters
  rownames(expected) <- NULL

  tab <- hg_cluster(hg, k = 2, type = "random_walk", seed = 7)
  expect_identical(tab, expected)
  expect_identical(tab, hg_cluster(hg, k = 2, type = "random_walk", seed = 7))
  expect_identical(nrow(tab), hg$n_nodes)
  expect_identical(length(unique(tab$cluster)), 2L)
})

test_that("hg_classify matches the engine and preserves given labels", {
  hg <- text_hypergraph(verb_corpus, stop_words = verb_stop)
  labels <- c(cooking_1 = "cooking", space_1 = "space")
  direct <- hypergraph_transduction(hg, labels = labels)
  expected <- direct$predictions
  rownames(expected) <- NULL

  tab <- hg_classify(hg, labels = labels)
  expect_identical(tab, expected)
  expect_identical(names(tab),
                   c("node", "label", "predicted", "score", "margin"))
  expect_identical(
    tab$label[tab$node == "cooking_1"],
    "cooking"
  )
  expect_true(is.na(tab$label[tab$node == "cooking_2"]))
})

test_that("every verb rejects a non-hypergraph with a classed error", {
  expect_error(hg_measures(42), class = "honets_bad_input")
  expect_error(hg_centrality(list()), class = "honets_bad_input")
  expect_error(hg_cluster("x", k = 2), class = "honets_bad_input")
  expect_error(hg_classify(NULL, labels = c(a = "x")),
               class = "honets_bad_input")
})

test_that("hg_centrality sort_by and n select without user-side subsetting", {
  hg <- text_hypergraph(verb_corpus, stop_words = verb_stop)
  full <- hg_centrality(hg, type = "clique")
  top <- hg_centrality(hg, type = "clique", sort_by = "clique", n = 3)
  expect_identical(nrow(top), 3L)
  expect_identical(top$clique, sort(full$clique, decreasing = TRUE)[1:3])
  expect_true(all(diff(top$clique) <= 0))
  expect_error(
    hg_centrality(hg, type = "clique", sort_by = "Z"),
    "clique"
  )
})

# ---- hg_cluster what= and hg_keywords ----------------------------------

test_that("hg_cluster returns embedding and eigenvalues via `what`", {
  hg <- text_hypergraph(c(
    cooking_1 = "simmer the soup with onions and carrots",
    cooking_2 = "this soup recipe needs salt on a cold night",
    space_1 = "the telescope revealed a distant galaxy and stars",
    space_2 = "astronomers aimed the telescope at the stars all night"
  ), stop_words = c("the", "with", "and", "a", "this", "at", "on", "all"))
  parts <- hg_cluster(hg, k = 2, seed = 1)
  emb <- hg_cluster(hg, k = 2, seed = 1, what = "embedding")
  expect_named(emb, c("node", "cluster", "pi", "dim1", "dim2"))
  expect_identical(emb$cluster, parts$cluster)
  expect_identical(emb$node, parts$node)
  eig <- hg_cluster(hg, k = 2, seed = 1, what = "eigenvalues")
  expect_named(eig, c("index", "value", "gap"))
  expect_identical(nrow(eig), hg$n_nodes)
  expect_true(all(diff(eig$value) >= -1e-12))  # ascending spectrum
})

test_that("hg_keywords matches a hand-computed fixture", {
  hg <- text_hypergraph(c(
    cooking_1 = "simmer the soup with onions and carrots",
    cooking_2 = "this soup recipe needs salt on a cold night",
    space_1 = "the telescope revealed a distant galaxy and stars",
    space_2 = "astronomers aimed the telescope at the stars all night"
  ), stop_words = c("the", "with", "and", "a", "this", "at", "on", "all"),
  weight = "n")
  clusters <- data.frame(node = c("cooking_1", "cooking_2",
                                  "space_1", "space_2"),
                         cluster = c("food", "food", "sky", "sky"))
  kw <- hg_keywords(hg, clusters, n = Inf)
  # hand: "soup" count 1+1 in food, 0 in sky -> score 2, share 1
  food_soup <- subset(kw, cluster == "food" & word == "soup")
  expect_identical(food_soup$rank, 1L)
  expect_identical(food_soup$score, 2)
  expect_identical(food_soup$share, 1)
  # hand: "night" once in each cluster -> share 0.5 both sides
  expect_identical(subset(kw, cluster == "food" & word == "night")$share, 0.5)
  expect_identical(subset(kw, cluster == "sky" & word == "night")$share, 0.5)
  # "telescope" is sky-only, count 2
  sky_tel <- subset(kw, cluster == "sky" & word == "telescope")
  expect_identical(sky_tel$score, 2)
  expect_identical(sky_tel$share, 1)
  # invariant: with every node assigned and n = Inf, per-word scores sum
  # to the word's total corpus mass
  total_by_word <- tapply(kw$score, kw$word, sum)
  expect_equal(as.numeric(total_by_word[colnames(hg$incidence)]),
               as.numeric(colSums(hg$incidence)), tolerance = 1e-12)
  expect_true(all(kw$share > 0 & kw$share <= 1))
})

test_that("hg_keywords works on sparse hypergraphs and vector input", {
  hg <- text_hypergraph(c(
    cooking_1 = "simmer the soup with onions and carrots",
    cooking_2 = "this soup recipe needs salt on a cold night",
    space_1 = "the telescope revealed a distant galaxy and stars",
    space_2 = "astronomers aimed the telescope at the stars all night"
  ), stop_words = c("the", "with", "and", "a", "this", "at", "on", "all"),
  weight = "n", sparse = TRUE)
  labels <- c(cooking_1 = "food", cooking_2 = "food",
              space_1 = "sky", space_2 = "sky")
  kw <- hg_keywords(hg, labels, n = 2)
  expect_identical(nrow(kw), 4L)
  expect_true(all(kw$rank %in% c(1L, 2L)))
  expect_error(hg_keywords(hg, c(zz = "a", cooking_1 = "b")),
               class = "honets_bad_input")
  expect_error(hg_keywords(hg, labels, n = 0), "positive")
})
