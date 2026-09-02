# texthypergraph — consolidated todos

Each item names its target repo. The Nestimate-side items also live in
`Nestimate/todo/COVERAGE-CATCHUP.md`; this file is the superset with the
text/NLP framing. Checked 2026-08-24: none of these exist anywhere on CRAN.

## Nestimate (statistical R core)

- [x] DONE 2026-08-25 in Nestimate `R/hypergraph_laplacian.R` (all three
      verbs; HyperNetX parity < 1e-12, brute-force formula tests, 64 shipped
      assertions). **Weighted hypergraph Laplacian + spectral clustering +
      transductive classification** (Zhou, Huang & Schölkopf 2006 — `papers/2006-NeurIPS-
      LearningWithHypergraphs-Zhou.pdf`). One Laplacian unlocks three verbs:
      clustering (fits `cluster_data()` family), transductive label spreading
      (THE non-neural text classifier — no R implementation exists), and
      spectral embedding. Oracles: `HyperG::hypergraph_laplacian_matrix` /
      `cluster_spectral` for the unweighted case; **HyperNetX
      `norm_lap`/`spec_clus` (verified: implements Hayashi EDVW exactly) via
      reticulate for the weighted case**; hand-computed small cases.
- [ ] **Windowed sequence hyperedges** for `build_hypergraph()` (HyperGAT
      construction, our weighted/windowed extension — no upstream oracle;
      invariants: window-count conservation, w = 2 reduces to
      `wtna_cooccurrence`). Details in Nestimate COVERAGE-CATCHUP §3.
- [ ] **Hypergraph random-walk centrality / PageRank with edge-dependent
      vertex weights** (Chitra & Raphael 2019 — `papers/2019-ICML-
      HypergraphRW-Chitra.pdf`). Sibling to the shipped Z/H tensor
      centralities in `hypergraph_centrality()`; their Thm-level result:
      edge-INdependent weights collapse to a graph random walk, so the
      edge-dependent case is where hypergraphs genuinely add information.
- [x] DONE 2026-08-25 (covered by the same implementation:
      `hypergraph_cluster(hg, type = "random_walk")` on a weighted incidence
      IS EDVW clustering; oracle parity verified). **EDVW spectral clustering
      — the UNSUPERVISED tier-2 method** (Hayashi,
      Aksoy, Park & Park 2020 — `papers/2020-CIKM-HypergraphClustering-
      Hayashi.pdf`, verified). Edge-dependent vertex weights (e.g. tf-idf of
      word-in-document) give a weighted incidence matrix -> random-walk
      Laplacians -> spectral / NMF clustering; demonstrated on term-document
      data, beats plain spectral baselines. Builds on the Chitra & Raphael
      theory; shares ALL machinery with the Zhou Laplacian item above (one
      extra weighting argument, e.g. `vertex_weights=` on the incidence).
      No R implementation exists. This is the better-than-LDA unsupervised
      route that stays fully statistical/interpretable. Oracle: HyperNetX
      `laplacians_clustering` (author-adjacent implementation, verified
      2026-08-25).
- [ ] **kNN embedding hypergraph (tier-3 -> tier-2 bridge)**: each document +
      its k nearest neighbors in a contrastive-embedding space (SimCSE / E5 /
      BGE class) = one hyperedge, weights from cosine similarity; then the
      Zhou/Hayashi spectral machinery clusters it with an explicit Laplacian
      instead of black-box UMAP+HDBSCAN, and `hypergraph_measures()` /
      `hypergraph_centrality()` describe the result. Unweighted precedent:
      `HyperG::knn_hypergraph()` (usable as a construction oracle). R
      pipeline: `text::textEmbed()` (reticulate/HF) -> Nestimate. Candidate
      shape: a `knn_hypergraph(embeddings, k, weight = "cosine")` builder or
      an input mode of `build_hypergraph()`. Vignette-first: prove the
      pipeline on a real corpus before deciding the API. Doesn't exist in R.
      Caveats to encode: multi-seed stability (stochastic embedders are not,
      but k choice is a sensitivity axis) and encoder-dependence reported per
      the house statistical rules.
- [ ] `wasserstein_distance()` + `dual_hypergraph()` — see Nestimate
      COVERAGE-CATCHUP §1/§2.
- [ ] **NLP bridge vignette**: `quanteda` dfm / `tidytext` long table →
      `bipartite_groups(long, player = "word", group = "doc", weight = "n")`
      → measures / centrality / (once landed) Laplacian classification.
      No new code — documentation of an existing path.

- [ ] **XGI as second oracle for shipped `hypergraph_centrality()`**: XGI has
      `h_eigenvector_`/`z_eigenvector_`/`clique_eigenvector_centrality`
      (verified in docs 2026-08-25) — add a reticulate cross-check to
      Nestimate's `local_testing_and_equivalence/test-equiv-hypergraph.R`
      alongside the existing igraph/clean-room references.

## texthypergraph (this package)

- [x] DONE 2026-08-25 v0.5: benchmark harness (R8/R52/MR/Ohsumed/20NG,
      TextGCN splits) + `normalization = "class_mass"` on the transduction
      verbs (Zhu et al. 2003; raw Zhou argmax collapses onto the majority
      class under imbalanced seeds). Results: `benchmarks/RESULTS.md` and
      the pkgdown benchmarks article.
- [x] DONE 2026-08-26 v0.6 stage 1: **HGNN natively in {torch}**
      (`hg_neural()`, Feng et al. 2019). Oracles: in-package Zhou operator
      identity (1e-12) + official DHG `HGNNConv` forward parity (2.4e-7).
      Package-best R8/R52/MR; 20NG/Ohsumed stay with transduction.
- [x] DONE 2026-08-26 v0.6 stage 2: **HyperGAT** (`hg_hypergat()`,
      sentence hyperedges — the official default; LDA hyperedges still
      open). Oracle: official layers.py forward parity 2.4e-7 + plain-R
      layer-math test. Benchmarks: R8 0.9665, R52 0.9433 (above published
      transductive TextGCN) — package-best on both.
- [x] DONE 2026-09-01 v0.7 stage 1: **the projection tier**
      (`hg_project()`, `hg_line_graph()`). Association weighting
      w({u,v}) = sum_e 1/(|e|-1) of Coupette, Hartung & Katz (2024,
      Phil. Trans. R. Soc. A 382:20230141) -- absent from the stack until
      now, since `Nestimate::clique_expansion()` is unnormalised
      tcrossprod. Oracles/gates: engine parity with `clique_expansion()`,
      the degree invariant (each hyperedge of size >= 2 adds weight
      exactly 1 around each member), the identity
      `hg_line_graph(s = 1)` == `hg_project(dual_hypergraph(hg),
      weighted = FALSE)`, and two mutation checks. 450/450 tests,
      check 0/0/0. cograph hand-off verified end-to-end.
- [ ] HyperGAT LDA topic hyperedges (the official --use_LDA path) and a
      20NG/MR/Ohsumed run on the official corpus files (needs their
      upstream data download; repo ships only R8/R52).

## Saqrlab (simulation)

- [ ] Random hypergraph samplers (gnp, SBM, k-uniform/regular) — oracle
      `HyperG::sample_*` for unweighted; needed for calibration studies of
      the Nestimate verbs above.

## carm-text / carm-ml (JS side, if ever)

- [ ] Hypergraph layer for carm-text: incidence structure from its existing
      tokenizer/topic-model outputs + the Zhou Laplacian in JS. Neural
      variants (HGNN → AllSet, `papers/`) only if a GNN story ever lands in
      carm-ml. PLMs (XLNet etc.) stay out of scope everywhere — R/JS access
      is wrapper-only (HF `transformers` via reticulate / `text` pkg).

## Reading order (papers/)

0. `2022-TIST-TextClassificationSurvey-Li.pdf` — umbrella background (supervised, through GCN; stops before hypergraphs).
1. `2006-NeurIPS-LearningWithHypergraphs-Zhou.pdf` — the Laplacian everything
   else builds on; directly implementable.
2. `2019-ICML-HypergraphRW-Chitra.pdf` — random-walk spectral theory,
   edge-dependent vertex weights.
2b. `2020-CIKM-HypergraphClustering-Hayashi.pdf` — EDVW clustering built on
   (2); the unsupervised method to implement.
3. `2020-EMNLP-HyperGAT-Ding.pdf` — text hypergraph construction + dual
   attention (construction verified in their repo, see README).
4. `2019-EMNLP-HGAT-Linmei.pdf` — topic/entity heterogeneous predecessor.
5. `2019-AAAI-HGNN-Feng.pdf`, `2019-NeurIPS-HyperGCN-Yadati.pdf`,
   `2020-HNHN-Dong.pdf`, `2022-ICLR-AllSet-Chien.pdf` — the neural lineage,
   in order.
6. `2019-NeurIPS-XLNet-Yang.pdf` — PLM baseline context only.

## Links

- HyperGAT code: https://github.com/kaize0409/HyperGAT_TextClassification
- AllSet code: https://github.com/jianhao2016/AllSet
- CRAN HyperG: https://cran.r-project.org/package=HyperG
- CRAN SimplicialComplex: https://cran.r-project.org/package=SimplicialComplex
- XLNet official: https://github.com/zihangdai/xlnet
- HF transformers XLNet docs: https://huggingface.co/docs/transformers/model_doc/xlnet
- R `text` package (HF wrapper): https://cran.r-project.org/package=text
- XGI (Python): https://xgi.readthedocs.io
- HyperNetX (Python, PNNL): https://github.com/pnnl/HyperNetX
- HypergraphX: https://github.com/HGX-Team/hypergraphx
- DHG / DeepHypergraph: https://github.com/iMoonLab/DeepHypergraph
