
test_that("plot.net_path_dependence leaves room for the flip labels", {
  # Regression: the modal-flip labels are drawn to the right of each point,
  # so the highest-KL context -- the one a reader most wants to read -- had
  # its label clipped at the panel edge. The panel must extend past the
  # largest KL value, not merely reach it.
  skip_if_not_installed("ggplot2")
  wide <- as.data.frame(do.call(rbind, lapply(
    split(human_long$code, human_long$session_id),
    function(s) c(s, rep(NA, max(lengths(split(human_long$code,
                                               human_long$session_id))) -
                            length(s))))), stringsAsFactors = FALSE)
  pd <- path_dependence(wide, order = 2L, min_count = 20L)
  p <- plot(pd)
  expect_s3_class(p, "ggplot")
  rng <- ggplot2::ggplot_build(p)$layout$panel_params[[1L]]$x.range
  max_kl <- max(as.data.frame(pd, sort_by = "KL", top = 15L)$KL)
  expect_gt(rng[2L], max_kl * 1.15)
})
