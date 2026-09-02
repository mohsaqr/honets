# TDA in Python — gudhi / ripser.py / giotto-tda

- **What** (one note for the family): GUDHI (INRIA; the reference C++/Python
  TDA library — complexes, persistence, bottleneck/Wasserstein), ripser.py
  (fast VR persistence), giotto-tda (scikit-learn-compatible TDA pipelines).
- **Verified**: NOT independently verified this session — standing background
  knowledge; all three are long-established. Nestimate's equivalence suite
  already uses `TDAstats` (R ripser binding) as an oracle.
- **Role for us**: candidate oracles for the parked `wasserstein_distance()`
  (gudhi's implementation is the field reference) alongside R's
  `SimplicialComplex`; nothing else needed from them — Nestimate's TDA scope
  (clique/pathway complexes, q-analysis) is relational, not point-cloud.
- **Links**: https://gudhi.inria.fr · https://github.com/scikit-tda/ripser.py ·
  https://github.com/giotto-ai/giotto-tda
