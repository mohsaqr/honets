# honets

Higher-order network analysis from categorical sequence data.

honets is the home package for the variable-order Markov / path-statistics
paradigm in the [Nestimate](https://github.com/mohsaqr/Nestimate) family —
the third delegation sibling after
[psychnets](https://github.com/mohsaqr/psychnets) (cross-sectional
psychometric networks) and
[idiographic](https://github.com/mohsaqr/idiographic) (person-specific
temporal models).

## Methods

| Verb | Method | Reference |
|---|---|---|
| `build_hon()` | Higher-order network with rule extraction (BuildHON+) | Xu, Wickramarathne & Chawla (2016) |
| `build_honem()` | Higher-order network embedding | Saebi, Ciampaglia, Kaplan & Chawla (2020) |
| `build_hypa()` | Hypergeometric path anomaly detection | LaRock et al. (2020) |
| `build_mogen()` | Multi-order generative model | Scholtes (2017) |
| `markov_order_test()` | Permutation-based Markov order test | — |
| `path_dependence()` | Per-context order-k vs order-1 KL diagnostic | Cover & Thomas (2006) |
| `pathways()` | Pathway strings for simplicial visualization | — |

Accessors: `mogen_transitions()`, `path_counts()`.

## Provenance

Code moved verbatim from Nestimate 0.9.0 (delegation T0, 2026-08-24).
Cross-package identity is proven by Nestimate's
`local_testing_and_equivalence/test-equiv-honets.R` (exact `identical()`
match on every verb, seeded permutation paths included). The inherited
Python-parity equivalence suite (pyHON, pathpy multi-order models,
Wallenius/Monte-Carlo HYPA references) lives in
`local_testing_and_equivalence/` (build-ignored):

```sh
NOT_CRAN=true HONETS_EQUIV_TESTS=true Rscript -e \
  'library(honets); testthat::test_dir("local_testing_and_equivalence")'
```

## Installation

```r
# development version
devtools::install(".")
```
