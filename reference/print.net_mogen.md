# Print Method for net_mogen

Print Method for net_mogen

## Usage

``` r
# S3 method for class 'net_mogen'
print(x, ...)
```

## Arguments

- x:

  A `net_mogen` object.

- ...:

  Additional arguments (ignored).

## Value

The input object, invisibly.

## Examples

``` r
seqs <- list(c("A","B","C","D"), c("A","B","C","A"), c("B","C","D","A"))
mg <- build_mogen(seqs, max_order = 2)
print(mg)
#> Multi-Order Generative Model (MOGen)
#>   Optimal order:  1 (by aic)
#>   Orders tested:  0 to 2
#>   States:         4
#>   Paths:          3 (12 observations)
#>   AIC:            38.6 | 19.0* | 21.0
#>   BIC:            40.0 | 20.9* | 23.4
#>   (* = minimum;  AIC and BIC agree on order 1)

# \donttest{
seqs <- data.frame(
  V1 = c("A","B","C","A","B"),
  V2 = c("B","C","A","B","C"),
  V3 = c("C","A","B","C","A")
)
mog <- build_mogen(seqs, max_order = 2L)
print(mog)
#> Multi-Order Generative Model (MOGen)
#>   Optimal order:  1 (by aic)
#>   Orders tested:  0 to 2
#>   States:         3
#>   Paths:          5 (15 observations)
#>   AIC:            37.0 | 15.0* | 15.0
#>   BIC:            38.4 | 16.4* | 16.4
#>   (* = minimum;  AIC and BIC agree on order 1)
# }
```
