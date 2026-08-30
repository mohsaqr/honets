# Changelog

## honets 0.1.4

- New inference verbs for higher-order rules (roadmap item A1):
  [`bootstrap_hon()`](https://mohsaqr.github.io/honets/reference/bootstrap_hon.md)
  — sequence bootstrap with percentile CIs for rule probabilities and
  per-rule extraction *support*;
  [`compare_hon()`](https://mohsaqr.github.io/honets/reference/compare_hon.md)
  — two-sample permutation comparison with per-edge BH adjustment and a
  pooled-count-weighted global test. Both precompute per-sequence counts
  once and rebuild replicates from reweighted counts (proven identical
  to re-counting the resampled multiset), draw all randomness serially
  (parallel runs reproduce serial results under a seed), accept long
  format (`action`/`actor`/`time`), and ship with `print`/`summary`/
  `plot`/`as.data.frame` methods (accessor filters `min_support`,
  `order_min`, `significant`, `sort_by`).
- Bundled example data `human_long` and `ai_long` (coded human-AI pair
  programming sessions, long format).
- New tutorial `Tutorial_docs/hon_inference.html`: rule stability by
  order, support-filtered reporting, and a diffuse early-vs-late shift
  (significant global test, no significant single edge).
- Internal: `.hon_extract_rules()` split into a counts-based core
  (`.hon_extract_rules_count()`); behavior unchanged (full equivalence
  suite re-verified).

## honets 0.1.3

- Roadmap: hypernets B2 (EDVW hypergraph PageRank) marked done in
  `EXPANSION-PLAN.md`. No package code changed.

## honets 0.1.2

- Roadmap: hypernets B1 (windowed sequence hyperedges) marked done in
  `EXPANSION-PLAN.md` with the shipped design recorded. No package code
  changed.

## honets 0.1.1

- Added the consolidated family expansion roadmap (`EXPANSION-PLAN.md`,
  build-ignored): honets higher-order features A1–A4 and the hypernets
  hypergraph sibling (scaffolded 2026-08-25). No package code changed.

## honets 0.1.0

- Initial release. Code moved from Nestimate 0.9.0 (delegation T0):
  [`build_hon()`](https://mohsaqr.github.io/honets/reference/build_hon.md),
  [`build_honem()`](https://mohsaqr.github.io/honets/reference/build_honem.md),
  [`build_hypa()`](https://mohsaqr.github.io/honets/reference/build_hypa.md),
  [`build_mogen()`](https://mohsaqr.github.io/honets/reference/build_mogen.md),
  [`mogen_transitions()`](https://mohsaqr.github.io/honets/reference/mogen_transitions.md),
  [`path_counts()`](https://mohsaqr.github.io/honets/reference/path_counts.md),
  [`markov_order_test()`](https://mohsaqr.github.io/honets/reference/markov_order_test.md),
  [`path_dependence()`](https://mohsaqr.github.io/honets/reference/path_dependence.md),
  and the
  [`pathways()`](https://mohsaqr.github.io/honets/reference/pathways.md)
  generic with methods for `net_hon`, `net_hypa`, and `net_mogen`.
  Numbers are identical to the Nestimate implementations (same code,
  same RNG streams).
- Corrected the HONEM reference (Saebi, Ciampaglia, Kaplan & Chawla
  2020, ); the author list previously cited was wrong.
