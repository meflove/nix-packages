#!/usr/bin/env sh
# Commit paths supplied as arguments and push through the normal pipeline.
set -eu

: "${PRIVATE_SSH_KEY:?configure this Tangled repository secret}"
: "${TANGLED_PUSH_URL:?configure this Tangled repository secret}"
branch="${TANGLED_REPO_DEFAULT_BRANCH:?set TANGLED_REPO_DEFAULT_BRANCH}"

key_dir="${RUNNER_TEMP:-/tmp}/tangled-ci"
mkdir -p "$key_dir"
key_file="$key_dir/id_ed25519"
printf '%s\n' "$PRIVATE_SSH_KEY" >"$key_file"
chmod 600 "$key_file"

git_ssh="ssh -i $key_file -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

git config user.name "tangled-ci[bot]"
git config user.email "tangled-ci@noreply.invalid"
git add -- "$@"
git diff --cached --quiet && exit 0
git commit -m "${TANGLED_COMMIT_MESSAGE:?set TANGLED_COMMIT_MESSAGE}"

# The workspace can be based on an older commit than the branch tip (scheduled
# triggers pin a SHA), so rebase before pushing instead of being rejected as
# non-fast-forward. The clone is shallow, hence --unshallow.
if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
  GIT_SSH_COMMAND="$git_ssh" git fetch --unshallow --no-tags "$TANGLED_PUSH_URL" "refs/heads/$branch"
else
  GIT_SSH_COMMAND="$git_ssh" git fetch --no-tags "$TANGLED_PUSH_URL" "refs/heads/$branch"
fi
git rebase FETCH_HEAD

GIT_SSH_COMMAND="$git_ssh" git push "$TANGLED_PUSH_URL" "HEAD:refs/heads/$branch"
