# BERTopic — Python native + CRAN wrapper

- **Python (canonical)**: Grootendorst's transformer topic modeling —
  SBERT-class embeddings -> UMAP -> HDBSCAN -> class-based TF-IDF topic
  descriptions; modular (each stage swappable), widely replicated as
  better-coherence-than-LDA. The de-facto LDA replacement (tier 1).
- **R wrapper — verified 2026-08-24 via CRAN_package_db**: CRAN package
  `BERTopic` 0.1.0 — reticulate interface to the Python package
  (fit/transform, update/reduce topics, topic- and document-level info,
  interactive visualizations). NOT a native implementation; Python managed
  through reticulate.
- **Role for us**: the practical baseline any hypergraph-clustering claim
  must beat or complement; usable from R today via the wrapper. Caveats per
  house rules: UMAP/HDBSCAN are stochastic — multi-seed stability reporting
  required; no generative model/likelihood.
- **Links**: https://maartengr.github.io/BERTopic ·
  https://cran.r-project.org/package=BERTopic
