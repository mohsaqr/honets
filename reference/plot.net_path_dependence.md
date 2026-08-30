# Plot method for `net_path_dependence`

Lollipop chart of per-context KL divergence, sorted descending. Point
size is proportional to context count; points where the modal next state
flips between orders are marked with an X to highlight substantively
meaningful order-2 effects.

## Usage

``` r
# S3 method for class 'net_path_dependence'
plot(x, top = 15L, title = NULL, ...)
```

## Arguments

- x:

  A `net_path_dependence` object.

- top:

  Integer. Number of contexts to show (top by KL). Default 15.

- title:

  Character. Plot title.

- ...:

  Ignored.

## Value

A ggplot object.
