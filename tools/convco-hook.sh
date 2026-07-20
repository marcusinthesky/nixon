#!/bin/sh
set -eu

exec convco check --from-stdin < "$1"
