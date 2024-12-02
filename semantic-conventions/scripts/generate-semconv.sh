#!/usr/bin/env bash

set -eo pipefail

PACKAGE_DIR='semantic-conventions'

# use the package directory as the default destination directory
DESTINATION_DIR="$(git rev-parse --show-toplevel)/$PACKAGE_DIR"
cd "$DESTINATION_DIR"

REPOSITORY_TAG=$(cat SEMCONV_VERSION)

if [ -z "$REPOSITORY_TAG" ]; then
  printf '%s\n' 'Missing Semantic Conventions git tag version as first argument.'
  exit 1
fi

# clone the opentelemetry-proto repository
REPOSITORY='https://github.com/open-telemetry/semantic-conventions.git'
REPOSITORY_DIR='semantic-conventions.git'
rm -fr "$REPOSITORY_DIR"
git clone -q "$REPOSITORY" "$REPOSITORY_DIR"

# check if the version exist
SEMANTIC_GIT_TAG=$(git -C "$REPOSITORY_DIR" tag -l "$REPOSITORY_TAG" | head -n1)
if [ "$SEMANTIC_GIT_TAG" != "$REPOSITORY_TAG" ]; then
  printf '%s\n' "The following git tag does not exist: $REPOSITORY_TAG"
  exit 1
fi

# switch to the right release
git -C "$REPOSITORY_DIR" switch --detach "tags/$REPOSITORY_TAG" >/dev/null 2>&1

# make the output dir
OUTPUT_DIR='model'
rm -fr "$OUTPUT_DIR"
mkdir "$OUTPUT_DIR"

REPOSITORY_SUBDIR='model'

# copy all the protobuf file in the OUTPUT_DIR directory
git -C "$REPOSITORY_DIR" ls-files -z "$REPOSITORY_SUBDIR/*.yaml" |
  tar -cf - -C "$REPOSITORY_DIR" --null --files-from=- |
  tar -xf - -C "$OUTPUT_DIR" --strip-components=1

# generate Haskell Semantic Conventions files
cabal run hs-opentelemetry-semantic-conventions:exe:generate "$OUTPUT_DIR"

# clean up git repository
rm -fr "$REPOSITORY_DIR"
