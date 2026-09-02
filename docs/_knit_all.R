# Knit every document in docs/ to self-contained HTML.
#
# docs/ holds four combined documents (one per structure family, plus an
# overview) and the index. The per-verb sources they were built from are
# archived under docs/_sections/ -- list.files() below is NOT recursive, so
# they are deliberately not rebuilt. Edit the combined documents.
#   Rscript docs/_knit_all.R              # all of them
#   Rscript docs/_knit_all.R memory-networks   # one or more, by basename
#
# Run from the package root. Vignettes call library(honets), so install
# first: Rscript -e 'devtools::install(".")'
args <- commandArgs(trailingOnly = TRUE)
rmd <- sort(list.files("docs", pattern = "[.]Rmd$", full.names = TRUE))
if (length(args)) {
  rmd <- rmd[tools::file_path_sans_ext(basename(rmd)) %in% args]
  if (!length(rmd)) stop("no vignette matched: ", paste(args, collapse = ", "))
}
for (f in rmd) {
  cat(sprintf("%-28s ", basename(f)))
  t0 <- proc.time()[["elapsed"]]
  rmarkdown::render(f, quiet = TRUE)
  cat(sprintf("ok  (%.1fs)\n", proc.time()[["elapsed"]] - t0))
}
cat(sprintf("\n%d vignette(s) knitted into docs/\n", length(rmd)))
