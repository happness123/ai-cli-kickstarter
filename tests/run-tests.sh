#!/usr/bin/env bash
# Offline smoke tests for kickstarter.sh: drives the state machine with
# scripted stdin and a stubbed curl. No network access, no dependencies.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STUBS="$ROOT/tests/stubs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/home"

PASS=0
FAIL=0
RC=""
OUT=""

# Runs kickstarter.sh with the given stdin payload and curl stub mode,
# in an isolated HOME and a minimal PATH. Kills the run after 15s so a
# regression to the old infinite redraw loop fails instead of hanging.
run_kickstarter(){
  local input="$1" mode="$2"
  rm -f "$WORK/home/.local/bin/claude"
  printf '%s' "$input" > "$WORK/stdin"
  env HOME="$WORK/home" PATH="$STUBS:/usr/bin:/bin" CURL_STUB_MODE="$mode" TERM=dumb \
    bash "$ROOT/kickstarter.sh" < "$WORK/stdin" > "$WORK/out" 2>&1 &
  local pid=$! waited=0
  RC="timeout"
  while :; do
    if ! kill -0 "$pid" 2>/dev/null; then
      wait "$pid"
      RC=$?
      break
    fi
    if [ "$waited" -ge 15 ]; then
      kill "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null
      RC="timeout"
      break
    fi
    sleep 1
    waited=$((waited + 1))
  done
  OUT="$(cat "$WORK/out")"
}

contains(){ case "$OUT" in *"$1"*) return 0;; *) return 1;; esac; }

check(){
  local desc="$1"
  shift
  if "$@"; then
    PASS=$((PASS + 1))
    echo "PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL: $desc"
    echo "  RC=$RC"
    printf '%s\n' "$OUT" | head -30 | sed 's/^/  | /'
  fi
}

not(){ ! "$@"; }
rc_is(){ [ "$RC" = "$1" ]; }
rc_nonzero(){ [ "$RC" != "timeout" ] && [ "$RC" != "0" ]; }

echo "== closed stdin exits immediately, installs nothing =="
run_kickstarter '' ok
check "exits with nonzero status" rc_nonzero
check "does not run the installer" not contains "Running the official installer"

echo "== EOF after language selection does not auto-install =="
run_kickstarter $'2\n' ok
check "exits with nonzero status" rc_nonzero
check "does not run the installer" not contains "Running the official installer"

echo "== failed download reaches the ERROR state =="
run_kickstarter $'2\n1\ny\n3\n\n' fail
check "reports installation failure" contains "Installation failed"
check "names the download as the cause" contains "download failed"
check "does not reach VERIFY" not contains "Verifying"
check "exits cleanly after user chooses exit" rc_is 0

echo "== successful install reaches VERIFY and exits cleanly =="
run_kickstarter $'2\n1\ny\nn\n\n' ok
check "executes the downloaded installer" contains "installer-ran"
check "reaches VERIFY" contains "Verifying"
check "reports command not on PATH yet" contains "not visible yet"
check "exits cleanly" rc_is 0

echo "== declining at CONFIRM skips installation =="
run_kickstarter $'2\n1\nn\n\n' ok
check "does not run the installer" not contains "Running the official installer"
check "exits cleanly" rc_is 0

echo "== Claude Code native installer =="
run_kickstarter $'2\n4\nn\n\n' ok
check "shows official Claude source" contains "https://claude.ai/install.sh"
check "decline skips installer" not contains "Running the official installer"
run_kickstarter $'2\n4\ny\nn\n\n' claude-ok
check "Claude version succeeds" contains "claude-stub"
check "Claude success reaches handoff" contains "personal AI computer assistant"
check "Claude exits cleanly" rc_is 0
run_kickstarter $'2\n4\ny\n3\n\n' claude-bad-version
check "nonzero version enters ERROR" contains "verification failed"
check "failed version blocks handoff" not contains "personal AI computer assistant"
run_kickstarter $'2\n4\ny\n3\n\n' fail
check "Claude download failure enters ERROR" contains "download failed"
run_kickstarter $'2\n4\ny\n3\n\n' installer-error
check "Claude installer failure enters ERROR" contains "installer returned an error"
run_kickstarter $'1\n4\nn\n\n' ok
check "Chinese menu includes Claude" contains "[4] Claude Code"

echo
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]

