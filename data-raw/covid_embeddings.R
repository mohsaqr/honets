# Build the bundled `covid_embeddings` dataset: sentence embeddings of the
# `covid_abstracts` abstracts, computed with the sbert package (pinned
# all-MiniLM-L6-v2, sbert's default model), L2-normalized, rownames = doc.
# Deterministic given the pinned model revision. Requires the model in the
# local sbert cache. Run from the package root:
#   Rscript data-raw/covid_embeddings.R

load(file.path("data", "covid_abstracts.rda"))

emb <- sbert::encode(covid_abstracts$abstract)
rownames(emb) <- covid_abstracts$doc

stopifnot(
  "one embedding row per abstract" = nrow(emb) == nrow(covid_abstracts),
  "no missing values" = !anyNA(emb),
  "unit rows (sbert normalize = TRUE)" =
    max(abs(sqrt(rowSums(emb^2)) - 1)) < 1e-6
)

covid_embeddings <- emb
save(covid_embeddings, file = file.path("data", "covid_embeddings.rda"),
     compress = "xz")
cat("dim:", dim(covid_embeddings),
    "| size:", file.size(file.path("data", "covid_embeddings.rda")), "bytes\n")
