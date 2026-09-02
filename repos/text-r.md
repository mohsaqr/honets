# text — CRAN (R, Python wrapper)

- **What**: R interface to Hugging Face transformers via reticulate
  (Kjell et al.) — `textEmbed()` for contextual embeddings by HF model id
  (SimCSE/E5/BGE-class included), plus downstream analysis/prediction
  helpers.
- **Verified 2026-08-24**: on CRAN (presence checked); capability description
  from package documentation background — exact function surface not audited
  this session.
- **Role for us**: the embedding step of every tier-3 pipeline in R — feeds
  `uwot`(UMAP) + `dbscan`(HDBSCAN) natively, and the parked kNN-embedding-
  hypergraph bridge (`textEmbed()` -> weighted kNN hyperedges -> Nestimate
  spectral/measures). Also the only R route to XLNet-class models (no native
  R transformer implementations exist).
- **Links**: https://cran.r-project.org/package=text · https://r-text.org
