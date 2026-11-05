#!/bin/sh
set -eu

git pull --ff-only
mise bootstrap --update
