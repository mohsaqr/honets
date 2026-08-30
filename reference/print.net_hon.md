# Print Method for net_hon

Print Method for net_hon

## Usage

``` r
# S3 method for class 'net_hon'
print(x, ...)
```

## Arguments

- x:

  A `net_hon` object.

- ...:

  Additional arguments (ignored).

## Value

The input object, invisibly.

## Examples

``` r
seqs <- list(c("A","B","C","D"), c("A","B","C","A"), c("B","C","D","A"))
hon <- build_hon(seqs, max_order = 2)
print(hon)
#> Higher-Order Network (HON)
#>   Nodes:        4 (4 first-order states)
#>   Edges:        5
#>   Max order:    1 (requested 2)
#>   Min freq:     1
#>   Trajectories: 3

# \donttest{
seqs <- data.frame(
  V1 = c("A","B","C","A","B"),
  V2 = c("B","C","A","B","C"),
  V3 = c("C","A","B","C","A")
)
hon <- build_hon(seqs, max_order = 2L)
print(hon)
#> Higher-Order Network (HON)
#>   Nodes:        3 (3 first-order states)
#>   Edges:        3
#>   Max order:    1 (requested 2)
#>   Min freq:     1
#>   Trajectories: 5
# }
```
