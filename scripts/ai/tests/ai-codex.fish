#!/usr/bin/env fish

set -l launcher (path resolve (path dirname (status filename))/../ai)
set -l expected_key "local-claude-codex-9f4c2a7e6b1d"
set -g test_root (mktemp -d /tmp/ai-codex-test.XXXXXX)

function _proxy_running
    set -l proxy_pid $argv[1]
    set -l state (ps -o stat= -p "$proxy_pid" 2>/dev/null | string trim)
    if test -z "$state"
        return 1
    end
    string match -q 'Z*' -- "$state"; and return 1
    return 0
end

function _stop_proxy
    set -l pid_file "$test_root/log/cliproxyapi.pid"
    test -f "$pid_file"; or return 0

    set -l proxy_pid (string trim <"$pid_file")
    string match -q -r '^[0-9]+$' -- "$proxy_pid"; or return 0
    _proxy_running "$proxy_pid"; or return 0

    kill -TERM "$proxy_pid" 2>/dev/null
    for attempt in (seq 1 20)
        _proxy_running "$proxy_pid"; and sleep 0.05; or return 0
    end
    kill -KILL "$proxy_pid" 2>/dev/null; or return 1
    for attempt in (seq 1 20)
        _proxy_running "$proxy_pid"; and sleep 0.05; or return 0
    end
    return 1
end

function _cleanup --on-event fish_exit
    _stop_proxy; or echo "FAIL: could not terminate CLIProxyAPI test stub" >&2
    rm -rf "$test_root"
end

function _fail
    echo "FAIL: $argv" >&2
    exit 1
end

function _assert_contains
    set -l needle $argv[1]
    set -l haystack $argv[2]
    set -l message $argv[3]
    string match -q "*$needle*" -- "$haystack"; or _fail "$message"
end

set -l stub_dir "$test_root/bin"
set -l test_home "$test_root/home"
set -l test_log "$test_root/log"
mkdir -p "$stub_dir" "$test_home" "$test_log"

printf '%s\n' \
    '#!/usr/bin/env fish' \
    'printf "%s\n" $argv > "$TEST_LOG/cliproxyapi.args"' \
    'echo $fish_pid > "$TEST_LOG/cliproxyapi.pid"' \
    'readlink "/proc/$fish_pid/fd/0" > "$TEST_LOG/cliproxyapi.stdin"' \
    'touch "$TEST_LOG/proxy-ready"' \
    'exec sleep 300' \
    >"$stub_dir/cliproxyapi"

printf '%s\n' \
    '#!/usr/bin/env fish' \
    'printf "%s\n" $argv >> "$TEST_LOG/curl.args"' \
    'contains -- "Authorization: Bearer $EXPECTED_KEY" $argv; or exit 22' \
    'contains -- "http://127.0.0.1:8317/v1/models" $argv; or exit 22' \
    'if test "$TEST_SCENARIO" = missing-model' \
    '    echo '\''{"data":[{"id":"some-other-model"}]}'\''' \
    '    exit 0' \
    'end' \
    'test -e "$TEST_LOG/proxy-ready"; or exit 7' \
    'echo '\''{"data":[{"id":"gpt-5.6-sol"}]}'\''' \
    >"$stub_dir/curl"

printf '%s\n' \
    '#!/usr/bin/env fish' \
    'printf "base=%s\ntoken=%s\ndiscovery=%s\nsubagent=%s\nargs=%s\n" "$ANTHROPIC_BASE_URL" "$ANTHROPIC_AUTH_TOKEN" "$CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY" "$CLAUDE_CODE_SUBAGENT_MODEL" (string join " " -- $argv) > "$TEST_LOG/claude.env"' \
    'if test "$TEST_SCENARIO" = ready-after-start' \
    '    kill -HUP (string trim < "$TEST_LOG/cliproxyapi.pid")' \
    'end' \
    >"$stub_dir/claude"

chmod +x "$stub_dir/cliproxyapi" "$stub_dir/curl" "$stub_dir/claude"

env HOME="$test_home" PATH="$stub_dir:$PATH" TEST_LOG="$test_log" \
    TEST_SCENARIO=ready-after-start EXPECTED_KEY="$expected_key" \
    fish "$launcher" codex >/dev/null 2>&1
or _fail "ready proxy scenario did not launch Claude"

set -l config_file "$test_home/.config/cliproxyapi/config.yaml"
test -f "$config_file"; or _fail "launcher did not create the explicit proxy config"
test (stat -c %a "$config_file") = 600; or _fail "proxy config permissions are not 600"

set -l config (string join ' ' <"$config_file")
_assert_contains 'host: 127.0.0.1' "$config" "proxy config is not loopback-only"
_assert_contains 'port: 8317' "$config" "proxy config does not use port 8317"
_assert_contains 'auth-dir: "~/.cli-proxy-api"' "$config" "proxy config uses the wrong auth directory"
_assert_contains "$expected_key" "$config" "proxy config API key does not match the launcher token"

set -l proxy_args (string join ' ' <"$test_log/cliproxyapi.args")
_assert_contains "-config $config_file" "$proxy_args" "cliproxyapi was not started with the explicit config"
test -s "$test_log/curl.args"; or _fail "launcher never checked /v1/models readiness"
set -l proxy_pid (string trim <"$test_log/cliproxyapi.pid")
_proxy_running "$proxy_pid"; or _fail "CLIProxyAPI did not survive launcher exit and SIGHUP"
test (string trim <"$test_log/cliproxyapi.stdin") = /dev/null; or _fail "CLIProxyAPI stdin was not detached to /dev/null"

set -l claude_env (string join ' ' <"$test_log/claude.env")
_assert_contains 'base=http://127.0.0.1:8317' "$claude_env" "Claude did not receive the proxy base URL"
_assert_contains "token=$expected_key" "$claude_env" "Claude did not receive the configured proxy token"
_assert_contains 'discovery=1' "$claude_env" "Claude gateway model discovery was not enabled"
_assert_contains 'subagent=gpt-5.6-sol' "$claude_env" "Claude subagent model was not configured"
_assert_contains 'args=--model gpt-5.6-sol' "$claude_env" "Claude did not receive gpt-5.6-sol as its model"

_stop_proxy; or _fail "cleanup could not terminate CLIProxyAPI test stub"
rm -f "$test_log/cliproxyapi.args" "$test_log/cliproxyapi.pid" "$test_log/cliproxyapi.stdin" "$test_log/claude.env" "$test_log/proxy-ready"
set -l missing_output (env HOME="$test_home" PATH="$stub_dir:$PATH" TEST_LOG="$test_log" \
    TEST_SCENARIO=missing-model EXPECTED_KEY="$expected_key" \
    fish "$launcher" codex 2>&1)
set -l missing_status $status

test $missing_status -ne 0; or _fail "missing model scenario unexpectedly succeeded"
test ! -e "$test_log/claude.env"; or _fail "Claude launched without gpt-5.6-sol credentials"
test ! -e "$test_log/cliproxyapi.args"; or _fail "healthy proxy was unnecessarily restarted"
set -l login_command "cliproxyapi -config $config_file -codex-login"
_assert_contains "$login_command" (string join ' ' -- $missing_output) "missing model error omitted the exact OAuth login command"

echo "PASS: ai codex proxy regression"
