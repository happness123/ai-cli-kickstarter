#!/usr/bin/env bash
# NOTE: kickstarter.ps1 mirrors this script; keep states and strings in sync.
set -u

VERSION="0.1.0"
STATE="LANGUAGE"
LANGUAGE=""
GOOGLE_STATUS="unknown"
PROVIDER_NAME=""
COMMAND_NAME=""
INSTALL_URL=""
LAST_ERROR=""

clear_screen(){ if command -v clear >/dev/null 2>&1; then clear || true; fi; }

is_yes(){ case "${1:-Y}" in y|Y|yes|YES|是) return 0;; *) return 1;; esac; }

t(){
  local k="$1"
  if [[ "$LANGUAGE" == "zh" ]]; then
    case "$k" in
      title) echo "AI CLI 启动器";;
      choose_language) echo "请选择语言 / Choose your language";;
      probing) echo "正在检测 Terminal 是否能直接访问 Google……";;
      reachable) echo "可以直接访问 Google。";;
      unreachable) echo "无法直接访问 Google。";;
      unknown) echo "无法可靠判断 Google 是否可访问。";;
      network_note) echo "该结果只代表当前 Terminal 对 Google 的连接，不判断地理位置。";;
      choose) echo "请选择一个 Kickstarter：";;
      default) echo "直接按 Enter 选择 Qwen Code，或输入 1–4：";;
      qwen) echo "中国大陆友好；官方独立安装器";;
      kimi) echo "中国大陆友好；首次启动后输入 /login";;
      buddy) echo "腾讯生态；官方原生安装器目前为 Beta";;
      claude) echo "Anthropic；官方原生安装器；首次启动需认证";;
      checking) echo "正在执行安装前检查……";;
      ready) echo "即将安装";;
      confirm) echo "继续？[Y/n]：";;
      installing) echo "正在运行官方安装器……";;
      verifying) echo "正在验证……";;
      success) echo "安装成功。";;
      not_found) echo "安装器已结束，但当前 Terminal 尚未找到命令。请重启 Terminal 后再运行。";;
      launch) echo "现在启动？[Y/n]：";;
      failed) echo "安装失败：";;
      retry) echo "[1] 重试  [2] 换一个工具  [3] 退出";;
      exit) echo "按 Enter 退出……";;
    esac
  else
    case "$k" in
      title) echo "AI CLI Kickstarter";;
      choose_language) echo "请选择语言 / Choose your language";;
      probing) echo "Testing whether this terminal can reach Google directly...";;
      reachable) echo "Google is directly reachable.";;
      unreachable) echo "Google is not directly reachable.";;
      unknown) echo "Google reachability could not be determined reliably.";;
      network_note) echo "This only tests the current terminal's access to Google; it does not infer location.";;
      choose) echo "Choose a kickstarter:";;
      default) echo "Press Enter for Qwen Code, or enter 1–4:";;
      qwen) echo "Mainland-China friendly; official standalone installer";;
      kimi) echo "Mainland-China friendly; enter /login after first launch";;
      buddy) echo "Tencent ecosystem; official native installer is currently Beta";;
      claude) echo "Anthropic; official native installer; authentication required on first launch";;
      checking) echo "Running pre-installation checks...";;
      ready) echo "Ready to install";;
      confirm) echo "Continue? [Y/n]: ";;
      installing) echo "Running the official installer...";;
      verifying) echo "Verifying...";;
      success) echo "Installation succeeded.";;
      not_found) echo "The installer finished, but the command is not visible yet. Restart Terminal and try again.";;
      launch) echo "Launch now? [Y/n]: ";;
      failed) echo "Installation failed:";;
      retry) echo "[1] Retry  [2] Choose another tool  [3] Exit";;
      exit) echo "Press Enter to exit...";;
    esac
  fi
}

banner(){ clear_screen; printf "\n=== %s v%s ===\n\n" "$(t title)" "$VERSION"; }

probe_google(){
  if ! command -v curl >/dev/null 2>&1; then GOOGLE_STATUS="unknown"; return; fi
  local code
  code="$(curl -L -sS -o /dev/null --connect-timeout 4 --max-time 7 -w '%{http_code}' https://www.google.com/generate_204 2>/dev/null || true)"
  if [[ "$code" == "204" ]]; then GOOGLE_STATUS="reachable"
  elif [[ -z "$code" || "$code" == "000" ]]; then GOOGLE_STATUS="unreachable"
  else GOOGLE_STATUS="unknown"; fi
}

select_provider(){
  case "$1" in
    1) PROVIDER_NAME="Qwen Code"; COMMAND_NAME="qwen"; INSTALL_URL="https://qwen-code-assets.oss-cn-hangzhou.aliyuncs.com/installation/install-qwen-standalone.sh";;
    2) PROVIDER_NAME="Kimi Code"; COMMAND_NAME="kimi"; INSTALL_URL="https://code.kimi.com/install.sh";;
    3) PROVIDER_NAME="CodeBuddy CLI"; COMMAND_NAME="codebuddy"; INSTALL_URL="https://www.codebuddy.cn/cli/install.sh";;
    4) PROVIDER_NAME="Claude Code"; COMMAND_NAME="claude"; INSTALL_URL="https://claude.ai/install.sh";;
  esac
}

refresh_path(){
  export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.bun/bin:$HOME/.cargo/bin:$PATH"
  hash -r 2>/dev/null || true
}

handoff(){
  if [[ "$LANGUAGE" == "zh" ]]; then
cat <<'EOF'
我是计算机新手。请作为我的个人 AI 电脑助手。

请遵守：
1. 执行命令前，用通俗语言解释目的。
2. 修改配置文件前先备份。
3. 涉及管理员权限、删除、覆盖、付费或隐私时，先询问我。
4. 每完成一步都验证结果。
5. 对每个在线服务都实际检测可访问性，不要仅根据 Google 的结果推断。
6. 只在必要时教我概念和命令，不要一次塞给我太多知识。

首先，请检查当前电脑环境，并告诉我下一步最值得做什么。
EOF
  else
cat <<'EOF'
I am a complete beginner. Act as my personal AI computer assistant.

Please follow these rules:
1. Explain the purpose in plain language before running commands.
2. Back up configuration files before changing them.
3. Ask first before administrator access, deletion, overwriting, payment, or privacy-sensitive actions.
4. Verify every completed step.
5. Test each online service directly; do not infer all connectivity from the Google result.
6. Teach concepts and commands only when necessary; do not overwhelm me.

First inspect this computer and tell me the single most valuable next step.
EOF
  fi
}

while true; do
  case "$STATE" in
    LANGUAGE)
      banner; t choose_language; echo; echo "  [1] 中文"; echo "  [2] English"; echo
      read -r -p "> " c || exit 1
      case "$c" in 1) LANGUAGE="zh"; STATE="PROBE";; 2) LANGUAGE="en"; STATE="PROBE";; *) sleep 1;; esac;;
    PROBE)
      banner; t probing; probe_google; echo
      t "$GOOGLE_STATUS"; t network_note; sleep 1; STATE="SELECT";;
    SELECT)
      banner; t "$GOOGLE_STATUS"; echo; t choose; echo
      echo "  [1] Qwen Code — $(t qwen)"; echo
      echo "  [2] Kimi Code — $(t kimi)"; echo
      echo "  [3] CodeBuddy CLI — $(t buddy)"; echo
      echo "  [4] Claude Code — $(t claude)"; echo
      read -r -p "$(t default) " c || exit 1
      case "${c:-1}" in 1|2|3|4) select_provider "${c:-1}"; STATE="PRECHECK";; *) sleep 1;; esac;;
    PRECHECK)
      banner; t checking
      case "$(uname -s 2>/dev/null || true)" in Darwin|Linux) ;; *) LAST_ERROR="Unsupported OS"; STATE="ERROR"; continue;; esac
      command -v curl >/dev/null 2>&1 || { LAST_ERROR="curl is missing"; STATE="ERROR"; continue; }
      STATE="CONFIRM";;
    CONFIRM)
      banner; echo "$(t ready): $PROVIDER_NAME"; echo "Google: $GOOGLE_STATUS"; echo "Source: $INSTALL_URL"; echo
      read -r -p "$(t confirm) " c || exit 1
      if is_yes "$c"; then STATE="INSTALL"; else STATE="DONE"; fi;;
    INSTALL)
      banner; t installing; echo
      installer="$(curl -fsSL --connect-timeout 10 --max-time 60 "$INSTALL_URL")" || installer=""
      if [[ -z "$installer" ]]; then
        LAST_ERROR="download failed: $INSTALL_URL"; STATE="ERROR"
      elif bash -c "$installer"; then
        STATE="VERIFY"
      else
        LAST_ERROR="$PROVIDER_NAME installer returned an error"; STATE="ERROR"
      fi;;
    VERIFY)
      refresh_path; echo; t verifying
      if command -v "$COMMAND_NAME" >/dev/null 2>&1 && "$COMMAND_NAME" --version; then
        t success
      elif [[ "$COMMAND_NAME" == "claude" ]]; then
        LAST_ERROR="Claude Code verification failed; restart Terminal and run claude --version"; STATE="ERROR"; continue
      else t not_found; fi
      STATE="HANDOFF";;
    HANDOFF)
      echo; handoff; echo
      read -r -p "$(t launch) " c || exit 1
      if is_yes "$c"; then
        refresh_path
        if command -v "$COMMAND_NAME" >/dev/null 2>&1; then exec "$COMMAND_NAME"; else t not_found; fi
      fi
      STATE="DONE";;
    ERROR)
      echo; echo "$(t failed) $LAST_ERROR"; t retry; read -r -p "> " c || exit 1
      case "$c" in 1) STATE="PRECHECK";; 2) STATE="SELECT";; 3) STATE="DONE";; esac;;
    DONE)
      read -r -p "$(t exit)" _; exit 0;;
  esac
done

