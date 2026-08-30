# honets

Higher-order network analysis from categorical sequence data.

honets is the home package for the variable-order Markov /
path-statistics paradigm in the
[Nestimate](https://github.com/mohsaqr/Nestimate) family — the third
delegation sibling after
[psychnets](https://github.com/mohsaqr/psychnets) (cross-sectional
psychometric networks) and
[idiographic](https://github.com/mohsaqr/idiographic) (person-specific
temporal models).

## Methods

| Verb | Method | Reference |
|----|----|----|
| [`build_hon()`](https://mohsaqr.github.io/honets/reference/build_hon.md) | Higher-order network with rule extraction (BuildHON+) | Xu, Wickramarathne & Chawla (2016) |
| [`build_honem()`](https://mohsaqr.github.io/honets/reference/build_honem.md) | Higher-order network embedding | Saebi, Ciampaglia, Kaplan & Chawla (2020) |
| [`build_hypa()`](https://mohsaqr.github.io/honets/reference/build_hypa.md) | Hypergeometric path anomaly detection | LaRock et al. (2020) |
| [`build_mogen()`](https://mohsaqr.github.io/honets/reference/build_mogen.md) | Multi-order generative model | Scholtes (2017) |
| [`markov_order_test()`](https://mohsaqr.github.io/honets/reference/markov_order_test.md) | Permutation-based Markov order test | — |
| [`path_dependence()`](https://mohsaqr.github.io/honets/reference/path_dependence.md) | Per-context order-k vs order-1 KL diagnostic | Cover & Thomas (2006) |
| [`pathways()`](https://mohsaqr.github.io/honets/reference/pathways.md) | Pathway strings for simplicial visualization | — |
| [`bootstrap_hon()`](https://mohsaqr.github.io/honets/reference/bootstrap_hon.md) | Bootstrap CIs + rule support for HON rules | Efron & Tibshirani (1993) |
| [`compare_hon()`](https://mohsaqr.github.io/honets/reference/compare_hon.md) | Two-sample permutation comparison of HON rules | Good (2005) |

Accessors:
[`mogen_transitions()`](https://mohsaqr.github.io/honets/reference/mogen_transitions.md),
[`path_counts()`](https://mohsaqr.github.io/honets/reference/path_counts.md).
Bundled data: `human_long`, `ai_long` (coded human-AI pair-programming
sessions). Tutorials: `Tutorial_docs/` (Rmd + rendered HTML).

## Provenance

Code moved verbatim from Nestimate 0.9.0 (delegation T0, 2026-08-24).
Cross-package identity is proven by Nestimate’s
`local_testing_and_equivalence/test-equiv-honets.R` (exact
[`identical()`](https://rdrr.io/r/base/identical.html) match on every
verb, seeded permutation paths included). The inherited Python-parity
equivalence suite (pyHON, pathpy multi-order models,
Wallenius/Monte-Carlo HYPA references) lives in
`local_testing_and_equivalence/` (build-ignored):

``` sh
NOT_CRAN=true HONETS_EQUIV_TESTS=true Rscript -e \
  'library(honets); testthat::test_dir("local_testing_and_equivalence")'
```

## Installation

``` r

# development version
devtools::install(".")
```
