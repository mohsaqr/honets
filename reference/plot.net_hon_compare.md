# Plot method for net_hon_compare

Difference plot of the per-edge probability differences, the largest
absolute differences first. Significance (BH-adjusted) is encoded by
both colour and point shape.

## Usage

``` r
# S3 method for class 'net_hon_compare'
plot(x, top = 20L, ...)
```

## Arguments

- x:

  A `net_hon_compare` object.

- top:

  Integer. Number of edges to show (by descending absolute difference).
  Default `20`.

- ...:

  Additional arguments (ignored).

## Value

A ggplot object, invisibly.
