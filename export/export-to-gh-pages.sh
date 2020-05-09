#!/bin/bash

set -eux

content_dir="$1"
repo_uri="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

git config user.name "$GITHUB_ACTOR"
git config user.email "${GITHUB_ACTOR}@bots.github.com"

git fetch origin refs/remotes/origin/gh-pages
git checkout --force -B gh-pages --track refs/remotes/origin/gh-pages

rsync -av --delete --cvs-exclude "${content_dir}/" ./
git add .

if ! git commit -m "updated GitHub Pages"; then
    echo "nothing to commit"
    exit 0
fi

git remote set-url origin "$repo_uri"
git push origin gh-pages
