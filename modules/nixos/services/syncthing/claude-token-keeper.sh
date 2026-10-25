# claude-token-keeper - refresh synced Claude Code OAuth logins ahead of time
#
# Every host shares one .credentials.json per account through Syncthing.
# Claude Code only refreshes in the last 5 minutes before expiry, so every
# host with a live session refreshes at the same moment, the refresh token
# rotates on one of them, and the others get invalid_grant and blank the file
# on disk, which Syncthing then spreads. This refreshes hours earlier instead.
# Each host gets a different REFRESH_BEFORE_MIN, so the first one online does
# it and the rest receive the new file through Syncthing.
#
# A blanked file (empty refreshToken) is repaired from the newest Syncthing
# conflict copy whose refresh token still works, once it has been blank for
# REPAIR_AFTER_MIN (again staggered per host).
#
# Usage: claude-token-keeper <claude config dir>...

client_id=9d1c250a-e61b-44d9-88ed-5944d1962f5e
token_url=https://platform.claude.com/v1/oauth/token
refresh_before_ms=$((${REFRESH_BEFORE_MIN:-120} * 60 * 1000))
repair_after_s=$((${REPAIR_AFTER_MIN:-0} * 60))

# refresh <source credentials file> <target credentials file>
refresh() {
  local src=$1 target=$2 body response status tmp
  body=$(jq -c '.claudeAiOauth | {
      grant_type: "refresh_token",
      refresh_token: .refreshToken,
      client_id: $client_id,
      scope: ((.scopes // []) | join(" "))
    }' --arg client_id "$client_id" "$src")
  response=$(mktemp)
  status=$(curl -sS -o "$response" -w '%{http_code}' --max-time 30 \
    -A 'axios/1.13.2' -H 'Content-Type: application/json' -d "$body" "$token_url") || status=000
  if [[ $status != 200 ]]; then
    echo "$target: refresh failed (HTTP $status): $(head -c 300 "$response")" >&2
    rm -f "$response"
    return 1
  fi

  # The temp name matches the /.credentials.json.* ignore rule, so only the
  # final rename is synced.
  tmp=$target.keeper-tmp
  (
    umask 077
    jq --slurpfile r "$response" --argjson now "$(date +%s%3N)" '
      ($r[0]) as $r
      | .claudeAiOauth.accessToken = $r.access_token
      | .claudeAiOauth.refreshToken = ($r.refresh_token // .claudeAiOauth.refreshToken)
      | .claudeAiOauth.expiresAt = ($now + $r.expires_in * 1000)
      | if $r.refresh_token_expires_in then
          .claudeAiOauth.refreshTokenExpiresAt = ($now + $r.refresh_token_expires_in * 1000)
        else . end
      | if $r.scope then .claudeAiOauth.scopes = ($r.scope | split(" ")) else . end
    ' "$src" >"$tmp"
  )
  rm -f "$response"
  mv "$tmp" "$target"
  echo "$target: refreshed, valid until $(date -d "@$(($(jq '.claudeAiOauth.expiresAt' "$target") / 1000))")"
}

for dir in "$@"; do
  creds=$dir/.credentials.json
  [[ -f $creds ]] || continue

  if [[ -n $(jq -r '.claudeAiOauth.refreshToken // ""' "$creds") ]]; then
    left=$(($(jq '.claudeAiOauth.expiresAt // 0' "$creds") - $(date +%s%3N)))
    if ((left > refresh_before_ms)); then
      echo "$creds: $((left / 60000)) min left, nothing to do"
      continue
    fi
    refresh "$creds" "$creds" || true
    continue
  fi

  # Blank login: give hosts earlier in the order a chance to repair it first.
  if (($(date +%s) - $(stat -c %Y "$creds") < repair_after_s)); then
    echo "$creds: blank, leaving the repair to another host for now"
    continue
  fi
  repaired=false
  mapfile -t copies < <(find "$dir" -maxdepth 1 -name '.credentials.sync-conflict-*.json' -printf '%T@ %p\n' | sort -rn | cut -d' ' -f2-)
  for copy in "${copies[@]}"; do
    [[ -n $(jq -r '.claudeAiOauth.refreshToken // ""' "$copy") ]] || continue
    if refresh "$copy" "$creds"; then
      repaired=true
      break
    fi
  done
  $repaired || echo "$creds: blank and no working conflict copy; run /login" >&2
done
