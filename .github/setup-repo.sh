#!/bin/sh
# One-time GitHub settings for sophne/openpixel: who may release, how main is protected, and where release
# secrets live. Safe to run again (it updates rulesets with the same name). Needs `gh` logged in as an admin.
#
#   sh .github/setup-repo.sh
#
# Rulesets on a private organisation repository need a paid GitHub plan; on a public repository they're free.
set -eu
REPO="${REPO:-sophne/openpixel}"

ruleset() {  # name, JSON body
  id="$(gh api "repos/$REPO/rulesets" --jq ".[] | select(.name == \"$1\") | .id" 2>/dev/null || true)"
  if [ -n "$id" ]; then
    echo "$2" | gh api -X PUT "repos/$REPO/rulesets/$id" --input - >/dev/null && echo "updated ruleset: $1"
  else
    echo "$2" | gh api -X POST "repos/$REPO/rulesets" --input - >/dev/null && echo "created ruleset: $1"
  fi
}

# Only repository admins may create, move or delete v* tags. Pushing such a tag is the only way to release.
ruleset "Release tags" '{
  "name": "Release tags", "target": "tag", "enforcement": "active",
  "conditions": { "ref_name": { "include": ["refs/tags/v*"], "exclude": [] } },
  "rules": [ { "type": "creation" }, { "type": "update" }, { "type": "deletion" } ],
  "bypass_actors": [
    { "actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always" },
    { "actor_id": 1, "actor_type": "OrganizationAdmin", "bypass_mode": "always" }
  ]
}'

# main: changes arrive by squash-merged pull request, reviewed by a code owner, with CI green. Admins may merge
# their own pull requests without a second reviewer.
ruleset "main" '{
  "name": "main", "target": "branch", "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request", "parameters": {
        "required_approving_review_count": 1, "require_code_owner_review": true,
        "dismiss_stale_reviews_on_push": true, "require_last_push_approval": false,
        "required_review_thread_resolution": true, "allowed_merge_methods": ["squash"] } },
    { "type": "required_status_checks", "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [ { "context": "app-ci" }, { "context": "web-ci" } ] } }
  ],
  "bypass_actors": [
    { "actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "pull_request" },
    { "actor_id": 1, "actor_type": "OrganizationAdmin", "bypass_mode": "pull_request" }
  ]
}'

# The "release" environment holds the signing secrets; only v* tags may deploy to it.
gh api -X PUT "repos/$REPO/environments/release" --input - >/dev/null <<'EOF'
{ "deployment_branch_policy": { "protected_branches": false, "custom_branch_policies": true } }
EOF
if ! gh api "repos/$REPO/environments/release/deployment-branch-policies" --jq '.branch_policies[].name' | grep -qx 'v\*'; then
  gh api -X POST "repos/$REPO/environments/release/deployment-branch-policies" -f name='v*' -f type=tag >/dev/null
fi
echo "environment: release (v* tags only)"

# Squash merges only, tidy branches, and security features.
gh api -X PATCH "repos/$REPO" --input - >/dev/null <<'EOF'
{ "allow_squash_merge": true, "allow_merge_commit": false, "allow_rebase_merge": false,
  "delete_branch_on_merge": true, "squash_merge_commit_title": "PR_TITLE",
  "squash_merge_commit_message": "PR_BODY", "has_wiki": false }
EOF
gh api -X PUT "repos/$REPO/vulnerability-alerts" >/dev/null && echo "Dependabot alerts on"
gh api -X PUT "repos/$REPO/automated-security-fixes" >/dev/null && echo "Dependabot security updates on"
gh api -X PUT "repos/$REPO/private-vulnerability-reporting" >/dev/null 2>&1 && echo "private vulnerability reporting on" \
  || echo "note: private vulnerability reporting turns on once the repository is public"
gh api -X PATCH "repos/$REPO" --input - >/dev/null 2>&1 <<'EOF' && echo "secret scanning + push protection on" \
  || echo "note: secret scanning turns on once the repository is public (or with GitHub Advanced Security)"
{ "security_and_analysis": { "secret_scanning": { "status": "enabled" },
  "secret_scanning_push_protection": { "status": "enabled" } } }
EOF
echo
echo "Also set in Settings → Actions → General: 'Require approval for all external contributors' for fork pull"
echo "requests, and Workflow permissions: 'Read repository contents'."
