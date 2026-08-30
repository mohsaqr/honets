# Plot method for net_hon_boot

Forest plot of the rule-edge probabilities with their bootstrap
percentile intervals, the most frequent edges first. Order is encoded by
both colour (Okabe-Ito) and point shape.

## Usage

``` r
# S3 method for class 'net_hon_boot'
plot(x, top = 20L, ...)
```

## Arguments

- x:

  A `net_hon_boot` object.

- top:

  Integer. Number of edges to show (by descending count). Default `20`.

- ...:

  Additional arguments (ignored).

## Value

A ggplot object, invisibly.
