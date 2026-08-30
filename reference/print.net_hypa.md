# Print Method for net_hypa

Print Method for net_hypa

## Usage

``` r
# S3 method for class 'net_hypa'
print(x, ...)
```

## Arguments

- x:

  A `net_hypa` object.

- ...:

  Additional arguments (ignored).

## Value

The input object, invisibly.

## Examples

``` r
seqs <- list(c("A","B","C"), c("B","C","A"), c("A","C","B"), c("A","B","C"))
hyp <- build_hypa(seqs, k = 2)
#> Warning: 'k' is deprecated; use 'order' instead.
print(hyp)
#> HYPA: Path Anomaly Detection
#>   Order(s):     2
#>   Edges:        3
#>   Anomalous:    0 (alpha=0.05, p_adjust=BH)
#>     Over-repr:  0
#>     Under-repr: 0

# \donttest{
seqs <- data.frame(
  V1 = c("A","B","C","A","B","C","A","B","C","A"),
  V2 = c("B","C","A","B","C","A","B","C","A","B"),
  V3 = c("C","A","B","C","A","B","C","A","B","C"),
  V4 = c("A","B","C","A","B","C","A","B","C","A")
)
hypa <- build_hypa(seqs, k = 2L)
#> Warning: 'k' is deprecated; use 'order' instead.
print(hypa)
#> HYPA: Path Anomaly Detection
#>   Order(s):     2
#>   Edges:        3
#>   Anomalous:    0 (alpha=0.05, p_adjust=BH)
#>     Over-repr:  0
#>     Under-repr: 0
# }
```
