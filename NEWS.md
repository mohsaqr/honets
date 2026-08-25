# honets 0.1.1

* Added the consolidated family expansion roadmap (`EXPANSION-PLAN.md`,
  build-ignored): honets higher-order features A1–A4 and the hypernets
  hypergraph sibling (scaffolded 2026-08-25). No package code changed.

# honets 0.1.0

* Initial release. Code moved from Nestimate 0.9.0 (delegation T0): `build_hon()`,
  `build_honem()`, `build_hypa()`, `build_mogen()`, `mogen_transitions()`,
  `path_counts()`, `markov_order_test()`, `path_dependence()`, and the
  `pathways()` generic with methods for `net_hon`, `net_hypa`, and `net_mogen`.
  Numbers are identical to the Nestimate implementations (same code, same RNG
  streams).
* Corrected the HONEM reference (Saebi, Ciampaglia, Kaplan & Chawla 2020,
  \doi{10.1089/big.2019.0169}); the author list previously cited was wrong.
