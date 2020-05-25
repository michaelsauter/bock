#!/usr/bin/env bash
set -ue

PATH=.:$PATH

git mock --init

git mock --receive log --times 1

git mock --receive="show HEAD" --times 1

git mock --receive='commit' --times 0

git log

git show HEAD

# git commit -m "foo"

git mock --verify
