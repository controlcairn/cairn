#!/usr/bin/env bash
# THE cairn ACTION'S ONE STEP (#39, ADR-009): run cairn in its image on the checkout, so a GitHub,
# Forgejo or Gitea job runs exactly what any other CI system runs. The checkout is mounted at
# /repo and cairn runs as the job's own user, so the reports it writes belong to the job. The CI
# system's own variables pass through, so `cairn push` names the run; the step summary's file is
# mounted where GitHub names it, so `--report markdown` appends to it. `cairn drift --comment` reads
# the pull request from GITHUB_REF and comments with CAIRN_FORGE_TOKEN, both by name (#40).
set -euo pipefail

: "${CAIRN_IMAGE:?the cairn action needs its image input}"
workspace="${GITHUB_WORKSPACE:-$PWD}"
args=(run --rm --user "$(id -u):$(id -g)" --volume "${workspace}:/repo" --workdir /repo)
for name in CAIRN_TOKEN CAIRN_ID_TOKEN ACTIONS_ID_TOKEN_REQUEST_URL ACTIONS_ID_TOKEN_REQUEST_TOKEN \
  CAIRN_FORGE_TOKEN GITHUB_ACTIONS FORGEJO_ACTIONS GITEA_ACTIONS GITHUB_SHA \
  GITHUB_REF GITHUB_REF_NAME GITHUB_REPOSITORY GITHUB_SERVER_URL GITHUB_API_URL GITHUB_RUN_ID \
  GITHUB_ACTOR GITHUB_WORKFLOW; do
  [ -n "${!name:-}" ] && args+=(--env "$name")
done
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  args+=(--volume "$(dirname "$GITHUB_STEP_SUMMARY"):/summary" --env "GITHUB_STEP_SUMMARY=/summary/$(basename "$GITHUB_STEP_SUMMARY")")
fi
if [ -n "${CAIRN_DOCKER_ARGS:-}" ]; then
  read -r -a extra <<<"$CAIRN_DOCKER_ARGS"
  args+=("${extra[@]}")
fi
args+=("$CAIRN_IMAGE" "${CAIRN_COMMAND:-check}" --root "/repo/${CAIRN_ROOT:-.}")
[ -n "${CAIRN_CONFIG:-}" ] && args+=(--config "/repo/${CAIRN_CONFIG}")
[ "${CAIRN_COMMENT:-false}" = true ] && args+=(--comment)
while IFS= read -r spec; do
  spec="${spec#"${spec%%[![:space:]]*}"}"
  spec="${spec%"${spec##*[![:space:]]}"}"
  [ -n "$spec" ] && args+=(--report "$spec")
done <<<"${CAIRN_REPORT:-}"
exec docker "${args[@]}"
