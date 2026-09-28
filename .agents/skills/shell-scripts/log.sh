#!/bin/sh

info() {
  echo "[I] $*" >&2
}

warn() {
  echo "[W] $*" >&2
}

error() {
  echo "[E] $*" >&2
  return 1
}
