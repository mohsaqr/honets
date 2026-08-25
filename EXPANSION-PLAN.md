# Expansion Plan — higher-order networks + hypergraphs

Owner decisions taken 2026-08-25 (this session). This is the consolidated
roadmap reconciling `Nestimate/todo/COVERAGE-CATCHUP.md`,
`../texthypergraph/TODO.md`, and the HON-1..15 / EG-1..13 sections of
`Nestimate/TODO.md` into two tracks with clear package ownership.

## Decisions

1. **hypernets is the fourth delegation sibling**, scaffolded now (not "later"
   as `Nestimate/HONETS-DELEGATION-PLAN.md` §6b had it — that decision was
   revisited with the owner on 2026-08-25). Name verified free on CRAN
   (no active package, no archive). All new hypergraph work builds in
   `../hypernets/`; Nestimate keeps its copies untouched until a T2
   delegation release (same playbook as the honets split).
2. **honets stays sequence/path only** (k-grams, variable-order Markov,
   path statistics). No hypergraph code here — the two paradigms share no
   infrastructure (ordered k-grams vs unordered multi-way co-membership).
3. All four features on each track are approved; suggested order below.

## Family map after this session

| Package | Paradigm | Status |
|---|---|---|
| Nestimate | estimation hub; re-exports delegated verbs | 0.9.0, untouched |
| psychnets | cross-sectional psychometric networks | delegated |
| idiographic | person-specific temporal models | delegated |
| honets | variable-order Markov / path statistics | 0.1.0 (T0 done) |
| **hypernets** | **multi-way co-membership (hypergraphs)** | **T0 this session** |

## Track A — honets (higher-order / sequence paradigm)

New verbs stay in the existing one-file-per-method layout, each with shipped
tests + an entry in `local_testing_and_equivalence/` where an oracle exists.

| # | Feature | Verb sketch | Oracle / validation | Reference |
|---|---|---|---|---|
| A1 | Inference on rules: bootstrap CIs + group permutation comparison for HON rules and MOGen transitions | `bootstrap_hon(data, n_boot)`, `compare_hon(data, group)` | house paradigm — invariant + calibration tests (type-I error under null resampling); no external oracle | Nestimate bootstrap/permutation conventions |
| A2 | Higher-order centralities projected to first-order states | `hon_centrality(hon, type = c("pagerank", "betweenness", "closeness"))` | pathpy `HigherOrderNetwork` centralities via the existing reticulate equiv harness | Scholtes, Wider & Garas (2016) EPJ B 89:61 |
| A3 | Memory-network community detection (map equation on the HON state graph) | `hon_communities(hon, method = "map_equation")` | pathpy/Infomap on second-order state networks | Rosvall et al. (2014) Nat. Commun. 5:4630 |
| A4 | Simulation + prediction from fitted models | `simulate(net_mogen, n)`, `predict(net_mogen, newdata)` S3 methods | pathpy `MultiOrderModel` likelihood/prediction; RNG-seeded reproducibility tests | Gote & Scholtes (2023), Scholtes (2017) |

Suggested order: A1 first (pure house paradigm, no new theory, highest
research value), then A2 (small, oracle exists), A3, A4.

**CRAN sequencing:** hold the T1 CRAN submission until A1–A2 land, then
submit as honets 0.2.0 — one submission instead of two.

## Track B — hypernets (hypergraph paradigm)

| # | Feature | Verb sketch | Oracle / validation | Reference |
|---|---|---|---|---|
| B0 | **T0 scaffold — DONE this session:** moved `hypergraph.R`, `hypergraph_centrality.R`, `hypergraph_laplacian.R`, `hypergraph_measures.R`, `bipartite_groups.R`, `clique_expansion.R` (+ helpers `.wrap_netobject`, `.validate_mcml_matrix`, `.extract_edges_from_matrix`, and the simplicial-clique closure behind an internal `build_simplicial()` shim) verbatim from Nestimate 0.9.0 | 8 exports, 11 S3 methods | exact `identical()` identity vs Nestimate proven (61 assertions, incl. RNG paths); 281 shipped tests + 682 equiv assertions green; quick check 0 errors / 0 warnings | — |
| B1 | **DONE 2026-08-25.** Windowed sequence hyperedges (tumbling/sliding window w, hyperedge = distinct states in window, weight = window count; incidence cells = occurrence totals, i.e. EDVW). Shipped as a dedicated constructor `window_hypergraph(data, window, step, action, actor, time, min_size)` rather than an input mode of `build_hypergraph()` (whose adjacency-typed first argument and clique args don't transfer); Laplacian family defaults `edge_weights` to the window counts; new tidy `as.data.frame.net_hypergraph()` accessor. | `window_hypergraph(data, window = w)` | wtna co-occurrence oracle (w = 2 tumbling, off-diagonals), bipartite_groups whole-sequence reduction, conservation invariants — all green; identity vs Nestimate re-verified after the edge-weight default change | Ding et al. (2020) EMNLP (HyperGAT construction) |
| B2 | EDVW random-walk centrality / hypergraph PageRank with edge-dependent vertex weights | `hypergraph_centrality(hg, type = "pagerank", vertex_weights = )` | HyperNetX / XGI via reticulate; edge-independent case must collapse to graph PageRank (their theorem — a free invariant test) | Chitra & Raphael (2019) ICML |
| B3 | Bayesian hypergraph reconstruction suite (Nestimate TODO HON-11..15): `reconstruct_hypergraph`, `hyperedge_significance`, `hypergraph_order_select`, `compare_hypergraphs`, soft clustering | as named in `Nestimate/TODO.md` | per-item oracles listed there | Young, Petri & Peixoto (2021) lineage per TODO |
| B4 | kNN embedding hypergraph + NLP bridge vignette (quanteda/tidytext → `bipartite_groups()` → Laplacian machinery) | `knn_hypergraph(embeddings, k, weight = "cosine")` | `HyperG::knn_hypergraph` for unweighted construction; vignette-first before freezing the API | texthypergraph/TODO.md |

Small carried-over items, ownership per the original files: `dual_hypergraph()`
(hypernets, when a use-case appears), XGI second oracle for shipped
centralities (hypernets equiv suite), `wasserstein_distance()` (STAYS in
Nestimate — TDA surface, not hypergraphs), random hypergraph samplers
(Saqrlab, per the simulation/computation split).

Suggested order: B0 (this session) → B1 (bridges sequence data in — the
natural honets↔hypernets connection) → B2 → B3 → B4.

## hypernets delegation tiers (mirrors HONETS-DELEGATION-PLAN.md)

1. **T0 — DONE 2026-08-25:** scaffolded `../hypernets/` 0.1.0 — code moved
   in, tests green, quick check clean, `identical()` identity vs Nestimate
   proven. Nestimate untouched. Deliberate deviations from verbatim, all
   documented in hypernets NEWS.md: (a) internal clique-only
   `build_simplicial()` shim replaces the Nestimate cross-module call
   (byte-identical code path, identity-tested); (b)
   `as.data.frame.net_hypergraph_transduction()` gained
   `row.names`/`optional` formals for S3 generic consistency (`what` moved
   after `...`, keyword-only); (c) `human_long` (34K) bundled so tests and
   examples are self-contained; (d) foreign roxygen links de-linked.
2. **T1:** hypernets hardening + B1/B2 land → CRAN submission. Include:
   rename the `nestimate_hypergraph_disconnected` condition class to
   `hypernets_hypergraph_disconnected` (coordinated — catchers in tests and
   any Nestimate callers must move with it).
3. **T2 (Nestimate delegation release):** delete the six R files + moved
   helpers where unused elsewhere; `Imports: hypernets`; thin forwarders
   (gimme pattern); move equivalence suites; htna gate + `--as-cran`.

## Bookkeeping done / to do

- [x] `Nestimate/HONETS-DELEGATION-PLAN.md` §6b — annotate: revisited
      2026-08-25, hypernets scaffolded (T0), pointer here.
- [ ] `Nestimate/todo/COVERAGE-CATCHUP.md` + `../texthypergraph/TODO.md` —
      retarget the hypergraph items' repo labels Nestimate → hypernets at T2
      (not before; until T2 the shipping copies are Nestimate's).
- [ ] Add honets + hypernets to the `saqr_AR` skill family list
      (`../Writing/saqr_Coding conventions.md`).
