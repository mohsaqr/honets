# HyperG — CRAN (R)

- **What**: the only general hypergraph toolkit on CRAN. v1.0.0, David J.
  Marchette, single release 2021-03-04, dormant since. Deps: igraph, mclust,
  proxy, RSpectra, gtools, Matrix.
- **Verified 2026-08-24** (refman): ~50 functions — constructors/converters
  (incidence, edgelist, literal, membership, dual, line graph, complement,
  add/delete), structure predicates (Helly, conformal, linear, hypertree),
  spectral (`hypergraph_laplacian_matrix`, ASE/LSE embeddings, spectrum,
  entropy), `cluster_spectral` (mclust on the embedding), `kCores`, seven
  random samplers (gnp, SBM, k-uniform/regular, geometric, epsilon, knn),
  plotting. **Undirected, UNWEIGHTED only** (stated in its own docs); no
  tensor centralities; no sequence/text input.
- **Role for us**: oracle for the UNWEIGHTED cases of the parked Nestimate
  items — `hypergraph_laplacian_matrix`/`cluster_spectral` for the Laplacian
  item, `knn_hypergraph` for the kNN-embedding construction, `sample_*` for
  the Saqrlab samplers, `dual_hypergraph` for the dual accessor. Local-only
  use (never a declared dependency).
- **Comparison**: full coverage comparison in Nestimate
  `todo/COVERAGE-CATCHUP.md` §2 (2026-08-24) — Nestimate wins on everything
  weighted, estimation-connected, and tensor-spectral; HyperG wins on
  combinatorial breadth we don't want.
- **Links**: https://cran.r-project.org/package=HyperG
