# Summary Method for net_mogen

Summary Method for net_mogen

## Usage

``` r
# S3 method for class 'net_mogen'
summary(object, ...)
```

## Arguments

- object:

  A `net_mogen` object.

- ...:

  Additional arguments (ignored).

## Value

A per-order model-selection data.frame with columns `order`,
`layer_dof`, `cum_dof`, `loglik`, `aic`, `bic`, `best`
(`"AIC"`/`"BIC"`/`"AIC+BIC"` marker) and `selected` (`"<--"` on the
chosen order), returned visibly; the summary text is printed as a side
effect.

## Examples

``` r
seqs <- list(c("A","B","C","D"), c("A","B","C","A"), c("B","C","D","A"))
mg <- build_mogen(seqs, max_order = 2)
summary(mg)
#> Multi-Order Generative Model (MOGen) Summary
#> 
#>   States: A, B, C, D
#>   Paths: 3 | Observations: 12
#>   Best by AIC: order 1  |  Best by BIC: order 1
#>   Selected:    order 1 (by aic)
#> 
#>         order layer_dof cum_dof loglik   aic   bic    best selected
#> order_0     0         3       3 -16.30 38.59 40.05                 
#> order_1     1         1       4  -5.49 18.99 20.93 AIC+BIC      <--
#> order_2     2         1       5  -5.49 20.99 23.41                 

# \donttest{
seqs <- data.frame(
  V1 = c("A","B","C","A","B"),
  V2 = c("B","C","A","B","C"),
  V3 = c("C","A","B","C","A")
)
mog <- build_mogen(seqs, max_order = 2L)
summary(mog)
#> Multi-Order Generative Model (MOGen) Summary
#> 
#>   States: A, B, C
#>   Paths: 5 | Observations: 15
#>   Best by AIC: order 1  |  Best by BIC: order 1
#>   Selected:    order 1 (by aic)
#> 
#>         order layer_dof cum_dof loglik   aic   bic    best selected
#> order_0     0         2       2 -16.48 36.96 38.37                 
#> order_1     1         0       2  -5.49 14.99 16.40 AIC+BIC      <--
#> order_2     2         0       2  -5.49 14.99 16.40                 
# }
```
