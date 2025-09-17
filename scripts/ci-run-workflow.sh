#!/usr/bin/env bash
set -euo pipefail

# Run a workflow locally with nektos/act. Examples:
#  scripts/ci-run-workflow.sh -w .github/workflows/ci.yml pull_request
#  scripts/ci-run-workflow.sh -w .github/workflows/linux.yml -j build-linux

usage() {
  echo "Usage: $0 -w <workflow_file> [<event_name>] [-j <job>] [-E <event_json>]" >&2
}

WORKFLOW=""
EVENT_NAME="push"
EVENT_PATH=""
JOB=""

while getopts ":w:j:E:h" opt; do
  case ${opt} in
    w) WORKFLOW="$OPTARG" ;;
    j) JOB="$OPTARG" ;;
    E) EVENT_PATH="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

if [[ -z "${WORKFLOW}" ]]; then
  usage; exit 1
fi

shift $((OPTIND-1))
if [[ $# -gt 0 ]]; then
  EVENT_NAME="$1"
fi

if ! command -v act >/dev/null 2>&1; then
  echo "act not found. Install act or use the devcontainer image where it's preinstalled." >&2
  exit 1
fi

ARGS=( "-W" "${WORKFLOW}" )
if [[ -n "${JOB}" ]]; then
  ARGS+=( "-j" "${JOB}" )
fi

if [[ -n "${EVENT_PATH}" ]]; then
  ARGS+=( "-e" "${EVENT_PATH}" )
fi

echo "Running act ${ARGS[*]} ${EVENT_NAME}"
act "${ARGS[@]}" "${EVENT_NAME}"
