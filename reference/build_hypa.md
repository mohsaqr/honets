# Detect Path Anomalies via HYPA

Constructs a k-th order De Bruijn graph from sequential trajectory data
and uses a hypergeometric null model to detect paths with anomalous
frequencies. Paths occurring more or less often than expected under the
null model are flagged as over- or under-represented.

## Usage

``` r
build_hypa(
  data,
  order = 2L,
  alpha = 0.05,
  min_count = 5L,
  p_adjust = "BH",
  k = NULL
)
```

## Arguments

- data:

  A data.frame (rows = trajectories), list of character vectors, `tna`
  object, or `netobject` with sequence data. For `tna`/`netobject`,
  numeric state IDs are automatically converted to label names.

- order:

  Integer scalar or integer vector. Order(s) of the De Bruijn graph
  (default `2L`). An order of `k` detects anomalies in paths of length
  `k`. When a vector is supplied, one De Bruijn layer is built per order
  and the per-order results are stored in `$by_order` (named by order).
  The orders are sorted ascending internally, so the `cograph_network`
  slots (`$weights`, `$edges`, `$adjacency`, `$xi`, `$nodes`, `$meta`)
  always describe the network of the *lowest order that produced a
  layer* (a requested order with no edges is dropped from `$by_order`,
  `$order` and `$k`), regardless of the order in which the vector is
  given; `$scores` aggregates every built order.

- alpha:

  Numeric. Significance threshold for anomaly classification (default
  0.05). Paths with HYPA score \< alpha are under-represented; paths
  with score \> 1-alpha are over-represented.

- min_count:

  Integer. Minimum observed count for a path to be classified as
  anomalous (default 5). Paths with fewer observations are always
  classified as `"normal"` regardless of their HYPA score, since rare
  occurrences are unreliable.

- p_adjust:

  Character. Method for multiple testing correction of p-values. Default
  `"BH"` (Benjamini-Hochberg FDR control). Accepts any method from
  [`p.adjust.methods`](https://rdrr.io/r/stats/p.adjust.html) or
  `"none"` to skip correction. Under- and over-representation p-values
  are adjusted separately (two-sided testing).

- k:

  Deprecated. Former name of `order`; if supplied it overrides `order`
  and emits a deprecation message. Use `order` instead.

## Value

An object of class `c("net_hypa", "cograph_network")` with components:

- scores:

  Data frame with path, from, to, observed, expected, ratio, p_value,
  p_under, p_over, p_adjusted_under, p_adjusted_over, anomaly, order
  columns (one block of rows per requested order). The `path` column
  shows the full state sequence (e.g., "A -\> B -\> C"); `from` is the
  context (conditioning states); `to` is the next state; `ratio` is
  observed / expected; `p_value` is retained as an alias for `p_under`,
  the raw lower-tail hypergeometric CDF value; `p_over` is the inclusive
  upper-tail probability `P(X >= observed)`; `p_adjusted_under` and
  `p_adjusted_over` are the corrected p-values for under- and
  over-representation tests respectively.

- ho_edges:

  Alias for `scores` (all orders, arrow notation).

- over:

  Subset of `scores` classified as over-represented.

- under:

  Subset of `scores` classified as under-represented.

- adjacency:

  Weighted adjacency matrix of the lowest-order De Bruijn graph.

- weights:

  cograph weight matrix of the lowest-order graph.

- xi:

  Fitted propensity matrix of the lowest-order graph.

- edges:

  cograph edge data.frame of the lowest-order graph.

- by_order:

  Named list of per-order result lists.

- order:

  Integer vector of orders actually built (sorted ascending).

- k:

  Back-compatibility alias for `order`.

- alpha:

  Significance threshold used.

- p_adjust:

  Multiple testing correction method used.

- n_anomalous:

  Number of anomalous paths detected (all orders).

- n_over:

  Number of over-represented paths (all orders).

- n_under:

  Number of under-represented paths (all orders).

- n_edges:

  Total number of edges (all orders).

- nodes:

  data.frame (`id`, `label`, `name`) of the lowest-order De Bruijn graph
  nodes (arrow notation).

- directed:

  Logical. Always `TRUE`.

- meta:

  cograph meta list of the lowest-order graph.

- node_groups:

  Always `NULL`.

## References

LaRock, T., Nanumyan, V., Scholtes, I., Casiraghi, G., Eliassi-Rad, T.,
& Schweitzer, F. (2020). HYPA: Efficient Detection of Path Anomalies in
Time Series Data on Networks. *SDM 2020*, 460-468.

## Examples

``` r
seqs <- list(c("A","B","C"), c("B","C","A"), c("A","C","B"), c("A","B","C"))
hyp <- build_hypa(seqs, order = 2)

# \donttest{
trajs <- list(c("A","B","C"), c("A","B","C"), c("A","B","C"),
              c("A","B","D"), c("C","B","D"), c("C","B","A"))
h <- build_hypa(trajs, order = 2)
print(h)
#> HYPA: Path Anomaly Detection
#>   Order(s):     2
#>   Edges:        4
#>   Anomalous:    0 (alpha=0.05, p_adjust=BH)
#>     Over-repr:  0
#>     Under-repr: 0
# }
```
