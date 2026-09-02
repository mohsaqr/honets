# DHG — DeepHypergraph (Python, PyTorch)

- **What**: the packaged home of hypergraph neural networks (iMoonLab):
  HGNN, HGNN+, HyperGCN, UniGNN-family and more as ready PyTorch models,
  plus hypergraph data structures and spectral utilities.
- **Verified**: NOT independently verified this session — model list from
  background knowledge; confirm the exact zoo in the repo before citing.
- **Relatives**: PyTorch Geometric ships a `HypergraphConv` layer;
  TopoNetX / TopoModelX (pyt-team) cover topological deep learning
  (simplicial/cell/hypergraph message passing).
- **Role for us**: reference-only. The neural tier is out of scope for
  Nestimate (no neural nets); if a JS/Python hypergraph-GNN story ever
  happens (carm-ml), DHG is the implementation to study, with the papers in
  `../papers/` (HGNN, HyperGCN, HNHN, AllSet) as the theory.
- **Links**: https://github.com/iMoonLab/DeepHypergraph ·
  https://deephypergraph.readthedocs.io · `pip install dhg`
