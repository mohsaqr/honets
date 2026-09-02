# Run the v0.5 benchmark grid and write one tidy results table.
# Usage: /usr/local/bin/Rscript benchmarks/run_benchmarks.R
# Requires benchmarks/download.sh to have been run first.

suppressMessages(devtools::load_all(".", quiet = TRUE))
source("benchmarks/harness.R")

datasets <- c("R8", "R52", "mr", "ohsumed", "20ng")

run_one <- function(name) {
  message("== ", name, " ==")
  rbind(
    bench_transduction(name, type = "zhou", normalization = "class_mass"),
    bench_transduction(name, type = "random_walk",
                       normalization = "class_mass"),
    bench_transduction(name, type = "zhou", normalization = "none"),
    bench_centroid(name)
  )
}

dir.create(file.path("benchmarks", "results"), showWarnings = FALSE)
results <- do.call(rbind, lapply(datasets, \(name) {
  out <- run_one(name)
  utils::write.csv(out, file.path("benchmarks", "results",
                                  paste0(name, ".csv")),
                   row.names = FALSE)
  out
}))
utils::write.csv(results, file.path("benchmarks", "results", "results.csv"),
                 row.names = FALSE)
print(results, digits = 4)
