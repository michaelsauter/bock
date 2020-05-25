#!/usr/bin/env bash
set -ue

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATH=${SCRIPT_DIR}:$PATH

git mock --init

git mock --receive log --times 1

git mock --receive="show HEAD" --times 1

git mock --receive='commit' --times 0

git log

git show HEAD

# git commit -m "foo"

git mock --verify
