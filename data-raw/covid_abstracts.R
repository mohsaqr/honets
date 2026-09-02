# Build the bundled `covid_abstracts` dataset: a deterministic stratified
# sample of the COVID-19 education-research Scopus export also used by the
# sbert package (source file: ../SBERT/covid.csv, 4,187 records, 2020-2024).
# Run from the package root: Rscript data-raw/covid_abstracts.R

set.seed(20260825)

raw <- read.csv(file.path("..", "SBERT", "covid.csv"))

usable <- subset(
  raw,
  !is.na(Abstract) & nchar(Abstract) >= 400 &
    Abstract != "[No abstract available]" & !is.na(Year),
  select = c("EID", "Title", "Abstract", "Year")
)

# 40 abstracts per year, alphabetical EID order within year for determinism.
usable <- usable[order(usable$Year, usable$EID), ]
picked <- do.call(rbind, lapply(split(usable, usable$Year), \(chunk) {
  chunk[sort(sample(nrow(chunk), size = min(40L, nrow(chunk)))), ]
}))

covid_abstracts <- data.frame(
  doc = picked$EID,
  title = picked$Title,
  abstract = picked$Abstract,
  year = as.integer(picked$Year),
  row.names = NULL
)

stopifnot(
  "no duplicate document IDs" = anyDuplicated(covid_abstracts$doc) == 0L,
  "no missing abstracts" = !anyNA(covid_abstracts$abstract),
  "every year represented" = length(unique(covid_abstracts$year)) >= 4L
)

usethis_save <- function(obj, name) {
  dir.create("data", showWarnings = FALSE)
  save(list = name, file = file.path("data", paste0(name, ".rda")),
       compress = "xz")
}
usethis_save(covid_abstracts, "covid_abstracts")
cat("rows:", nrow(covid_abstracts),
    "| years:", paste(sort(unique(covid_abstracts$year)), collapse = ", "),
    "| size:", file.size(file.path("data", "covid_abstracts.rda")), "bytes\n")
