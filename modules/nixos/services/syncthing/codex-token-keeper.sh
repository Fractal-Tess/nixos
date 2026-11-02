# codex-token-keeper - refresh the synced Codex ChatGPT login ahead of time
#
# Every host shares one ~/.codex/auth.json through Syncthing. Refresh tokens
# rotate, so if two hosts refresh the same login, the second one is rejected.
# Codex refreshes on its own once a login is 8 days old (the access token
# lasts 10). This refreshes earlier instead. Each host gets a different
# REFRESH_BEFORE_HOURS, so the first host online refreshes and the rest
# receive the new file through Syncthing.
#
# Usage: codex-token-keeper <codex home>...

client_id=app_EMoamEEZ73f0CkXaXp7hrann
token_url=https://auth.openai.com/oauth/token
refresh_before_s=$((${REFRESH_BEFORE_HOURS:-72} * 3600))

# Seconds until the access token in <auth.json> expires (negative if expired).
seconds_left() {
  local payload
  payload=$(jq -r '.tokens.access_token // "" | split(".")[1] // ""' "$1" | tr '_-' '/+')
  while ((${#payload} % 4)); do payload+='='; done
  echo $(($(base64 -d <<<"$payload" 2>/dev/null | jq '.exp // 0') - $(date +%s)))
}

for dir in "$@"; do
  auth=$dir/auth.json
  [[ -f $auth ]] || continue
  if [[ -z $(jq -r '.tokens.refresh_token // ""' "$auth") ]]; then
    echo "$auth: no ChatGPT login, nothing to do"
    continue
  fi

  left=$(seconds_left "$auth")
  if ((left > refresh_before_s)); then
    echo "$auth: $((left / 3600)) h left, nothing to do"
    continue
  fi

  body=$(jq -c '{client_id: $client_id, grant_type: "refresh_token",
      refresh_token: .tokens.refresh_token, scope: "openid profile email"}' \
    --arg client_id "$client_id" "$auth")
  response=$(mktemp)
  status=$(curl -sS -o "$response" -w '%{http_code}' --max-time 30 \
    -H 'Content-Type: application/json' -d "$body" "$token_url") || status=000
  if [[ $status != 200 ]]; then
    echo "$auth: refresh failed (HTTP $status): $(head -c 300 "$response")" >&2
    rm -f "$response"
    continue
  fi

  # The temp name is outside the Syncthing allow-list, so only the final
  # rename is synced.
  tmp=$auth.keeper-tmp
  (
    umask 077
    jq --slurpfile r "$response" --arg now "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)" '
      ($r[0]) as $r
      | .tokens.access_token = $r.access_token
      | .tokens.id_token = ($r.id_token // .tokens.id_token)
      | .tokens.refresh_token = ($r.refresh_token // .tokens.refresh_token)
      | .last_refresh = $now
    ' "$auth" >"$tmp"
  )
  rm -f "$response"
  mv "$tmp" "$auth"
  echo "$auth: refreshed, $(($(seconds_left "$auth") / 3600)) h left"
done
