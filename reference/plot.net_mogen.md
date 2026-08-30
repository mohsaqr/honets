# Plot Method for net_mogen

Plot Method for net_mogen

## Usage

``` r
# S3 method for class 'net_mogen'
plot(x, type = c("ic", "likelihood"), ...)
```

## Arguments

- x:

  A `net_mogen` object.

- type:

  Character. Plot type: `"ic"` (default) or `"likelihood"`.

- ...:

  Additional arguments passed to
  [`plot`](https://rdrr.io/r/graphics/plot.default.html).

## Value

The input object, invisibly.

## Examples

``` r
seqs <- list(c("A","B","C","D"), c("A","B","C","A"), c("B","C","D","A"))
mg <- build_mogen(seqs, max_order = 2)
plot(mg)


# \donttest{
seqs <- data.frame(
  V1 = c("A","B","C","A","B"),
  V2 = c("B","C","A","B","C"),
  V3 = c("C","A","B","C","A")
)
mog <- build_mogen(seqs, max_order = 2L)
plot(mog, type = "ic")

# }
```
