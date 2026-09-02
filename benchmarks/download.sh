#!/bin/sh
# Fetch the five benchmark datasets (TextGCN cleaned corpora + splits) into
# benchmarks/data/. These are the exact files HyperGAT's preprocessing
# reads, so accuracies are comparable with the published tables.
set -eu
cd "$(dirname "$0")"
mkdir -p data/corpus
base=https://raw.githubusercontent.com/yao8839836/text_gcn/master/data
for d in R8 R52 mr ohsumed 20ng; do
  [ -f "data/$d.txt" ] || curl -sfL -o "data/$d.txt" "$base/$d.txt"
  [ -f "data/corpus/$d.clean.txt" ] || \
    curl -sfL -o "data/corpus/$d.clean.txt" "$base/corpus/$d.clean.txt"
  echo "$d ready"
done
