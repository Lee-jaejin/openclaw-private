#!/bin/bash
# Arguments module for ralph.sh
# CLI argument parsing
# Dependencies: constants.sh

# Parse command line arguments
# Sets: MAX_ITERATIONS, ONCE_FLAG
# Usage: parse_arguments "$@"
parse_arguments() {
  MAX_ITERATIONS=10
  ONCE_FLAG=false

  while [[ $# -gt 0 ]]; do
    case $1 in
      --help|-h)
        show_help
        ;;
      --once)
        ONCE_FLAG=true
        shift
        ;;
      --max-iterations|-n)
        MAX_ITERATIONS="$2"
        shift 2
        ;;
      --max-iterations=*)
        MAX_ITERATIONS="${1#*=}"
        shift
        ;;
      [0-9]*)
        MAX_ITERATIONS="$1"
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  # --once overrides max-iterations
  if [ "$ONCE_FLAG" = true ]; then
    MAX_ITERATIONS=1
  fi
}
