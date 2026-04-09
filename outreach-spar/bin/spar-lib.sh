#!/bin/bash
# Shared shell functions for SPAR batch scripts.
# Source this file: source "$SCRIPT_DIR/spar-lib.sh"

slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//'
}
