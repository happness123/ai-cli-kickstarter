# AI CLI Kickstarter — Windows PowerShell
# NOTE: kickstarter.sh mirrors this script; keep states and strings in sync.
$ErrorActionPreference = "Stop"
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "需要 PowerShell 5 或更新版本 / PowerShell 5 or newer is required."
    Read-Host "Press Enter to exit" | Out-Null
    exit 1
}
$Version = "0.1.0"
$State = "LANGUAGE"
$Language = ""
$GoogleStatus = "unknown"
$ProviderName = ""
$CommandName = ""
$InstallUrl = ""
$LastError = ""

function T([string]$Key) {
    $zh = @{
        title="AI CLI 启动器"; choose_language="请选择语言 / Choose your language";
        probing="正在检测 PowerShell 是否能直接访问 Google……";
        reachable="可以直接访问 Google。"; unreachable="无法直接访问 Google。";
        unknown="无法可靠判断 Google 是否可访问。";
        network_note="该结果只代表当前 PowerShell 对 Google 的连接，不判断地理位置。";
        choose="请选择一个 Kickstarter："; default="直接按 Enter 选择 Qwen Code，或输入 1–4";
        qwen="中国大陆友好；官方独立安装器"; kimi="中国大陆友好；首次启动后输入 /login";
        buddy="腾讯生态；官方原生安装器目前为 Beta";
        claude="Anthropic；官方原生安装器；首次启动需认证";
        checking="正在执行安装前检查……"; ready="即将安装"; confirm="继续？[Y/n]";
        installing="正在运行官方安装器……"; verifying="正在验证……"; success="安装成功。";
        not_found="安装器已结束，但当前 PowerShell 尚未找到命令。请重新打开 PowerShell 后再运行。";
        launch="现在启动？[Y/n]"; failed="安装失败"; retry="[1] 重试  [2] 换一个工具  [3] 退出";
        exit="按 Enter 退出"
    }
    $en = @{
        title="AI CLI Kickstarter"; choose_language="请选择语言 / Choose your language";
        probing="Testing whether PowerShell can reach Google directly...";
        reachable="Google is directly reachable."; unreachable="Google is not directly reachable.";
        unknown="Google reachability could not be determined reliably.";
        network_note="This only tests PowerShell access to Google; it does not infer location.";
        choose="Choose a kickstarter:"; default="Press Enter for Qwen Code, or enter 1–4";
        qwen="Mainland-China friendly; official standalone installer";
        kimi="Mainland-China friendly; enter /login after first launch";
        buddy="Tencent ecosystem; official native installer is currently Beta";
        claude="Anthropic; official native installer; authentication required on first launch";
        checking="Running pre-installation checks..."; ready="Ready to install"; confirm="Continue? [Y/n]";
        installing="Running the official installer..."; verifying="Verifying..."; success="Installation succeeded.";
        not_found="The installer finished, but the command is not visible yet. Reopen PowerShell and try again.";
        launch="Launch now? [Y/n]"; failed="Installation failed"; retry="[1] Retry  [2] Choose another tool  [3] Exit";
        exit="Press Enter to exit"
    }
    if ($Language -eq "zh") { return $zh[$Key] } else { return $en[$Key] }
}

function Banner {
    Clear-Host
    Write-Host ""
    Write-Host "=== $(T 'title') v$Version ==="
    Write-Host ""
}

function Test-GoogleReachability {
    try {
        $r = Invoke-WebRequest -Uri "https://www.google.com/generate_204" -Method Get -TimeoutSec 7 -MaximumRedirection 2 -UseBasicParsing
        if ($r.StatusCode -eq 204) { $script:GoogleStatus = "reachable" }
        else { $script:GoogleStatus = "unknown" }
    } catch {
        # An HTTP response other than 204 means "unknown"; no response means "unreachable".
        if ($_.Exception -is [System.Net.WebException] -and $_.Exception.Response) { $script:GoogleStatus = "unknown" }
        else { $script:GoogleStatus = "unreachable" }
    }
}

function Test-Yes([string]$Answer) {
    return ([string]::IsNullOrWhiteSpace($Answer) -or $Answer -match "^(y|yes|是)$")
}

function Select-Provider([string]$Choice) {
    switch ($Choice) {
        "1" { $script:ProviderName="Qwen Code"; $script:CommandName="qwen"; $script:InstallUrl="https://qwen-code-assets.oss-cn-hangzhou.aliyuncs.com/installation/install-qwen-standalone.ps1" }
        "2" { $script:ProviderName="Kimi Code"; $script:CommandName="kimi"; $script:InstallUrl="https://code.kimi.com/install.ps1" }
        "3" { $script:ProviderName="CodeBuddy CLI"; $script:CommandName="codebuddy"; $script:InstallUrl="https://www.codebuddy.cn/cli/install.ps1" }
        "4" { $script:ProviderName="Claude Code"; $script:CommandName="claude"; $script:InstallUrl="https://claude.ai/install.ps1" }
    }
}

function Sync-SessionPath {
    # Append, never replace: the installer runs via Invoke-Expression in this
    # process and may have extended $env:Path in-session rather than in the registry.
    $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $user = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$env:Path;$machine;$user;$HOME\.local\bin;$HOME\AppData\Local\codebuddy\bin"
}

function Show-Handoff {
    if ($Language -eq "zh") {
@'
我是计算机新手。请作为我的个人 AI 电脑助手。

请遵守：
1. 执行命令前，用通俗语言解释目的。
2. 修改配置文件前先备份。
3. 涉及管理员权限、删除、覆盖、付费或隐私时，先询问我。
4. 每完成一步都验证结果。
5. 对每个在线服务都实际检测可访问性，不要仅根据 Google 的结果推断。
6. 只在必要时教我概念和命令，不要一次塞给我太多知识。

首先，请检查当前电脑环境，并告诉我下一步最值得做什么。
'@ | Write-Host
    } else {
@'
I am a complete beginner. Act as my personal AI computer assistant.

Please follow these rules:
1. Explain the purpose in plain language before running commands.
2. Back up configuration files before changing them.
3. Ask first before administrator access, deletion, overwriting, payment, or privacy-sensitive actions.
4. Verify every completed step.
5. Test each online service directly; do not infer all connectivity from the Google result.
6. Teach concepts and commands only when necessary; do not overwhelm me.

First inspect this computer and tell me the single most valuable next step.
'@ | Write-Host
    }
}

while ($true) {
    switch ($State) {
        "LANGUAGE" {
            Banner
            Write-Host (T "choose_language")
            Write-Host "`n  [1] 中文`n  [2] English`n"
            $c = Read-Host ">"
            if ($c -eq "1") { $Language="zh"; $State="PROBE" }
            elseif ($c -eq "2") { $Language="en"; $State="PROBE" }
        }
        "PROBE" {
            Banner; Write-Host (T "probing"); Test-GoogleReachability
            Write-Host "`n$(T $GoogleStatus)"
            Write-Host (T "network_note")
            Start-Sleep -Seconds 1; $State="SELECT"
        }
        "SELECT" {
            Banner
            Write-Host "$(T $GoogleStatus)`n"
            Write-Host (T "choose")
            Write-Host "`n  [1] Qwen Code — $(T 'qwen')"
            Write-Host "`n  [2] Kimi Code — $(T 'kimi')"
            Write-Host "`n  [3] CodeBuddy CLI — $(T 'buddy')`n"
            Write-Host "`n  [4] Claude Code — $(T 'claude')`n"
            $c = Read-Host (T "default")
            if ([string]::IsNullOrWhiteSpace($c)) { $c="1" }
            if ($c -match '^[1234]$') { Select-Provider $c; $State="PRECHECK" }
        }
        "PRECHECK" {
            Banner; Write-Host (T "checking")
            $State="CONFIRM"
        }
        "CONFIRM" {
            Banner
            Write-Host "$(T 'ready'): $ProviderName"
            Write-Host "Google: $GoogleStatus"
            Write-Host "Source: $InstallUrl`n"
            $c=Read-Host (T "confirm")
            if (Test-Yes $c) { $State="INSTALL" } else { $State="DONE" }
        }
        "INSTALL" {
            Banner; Write-Host (T "installing")
            try {
                # Invoke-WebRequest keeps the script as raw text; Invoke-RestMethod
                # would deserialize it if the server sent a JSON/XML content type.
                $resp = Invoke-WebRequest -Uri $InstallUrl -UseBasicParsing -TimeoutSec 60
                $installer = if ($resp.Content -is [byte[]]) { [System.Text.Encoding]::UTF8.GetString($resp.Content) } else { [string]$resp.Content }
                if ([string]::IsNullOrWhiteSpace($installer)) { throw "Empty installer script from $InstallUrl" }
                $global:LASTEXITCODE = 0
                Invoke-Expression $installer
                if ($CommandName -eq "claude" -and $LASTEXITCODE -ne 0) { throw "Claude Code installer returned an error" }
                $State="VERIFY"
            } catch {
                $LastError=$_.Exception.Message; $State="ERROR"
            }
        }
        "VERIFY" {
            Sync-SessionPath; Write-Host "`n$(T 'verifying')"
            try {
                $cmd=Get-Command $CommandName -ErrorAction Stop
                $global:LASTEXITCODE = 0
                & $cmd.Source --version
                if ($CommandName -eq "claude" -and $LASTEXITCODE -ne 0) { throw "Claude Code --version failed" }
                Write-Host (T "success")
            } catch {
                Write-Host (T "not_found")
                if ($CommandName -eq "claude") { $LastError="Claude Code verification failed"; $State="ERROR"; break }
            }
            $State="HANDOFF"
        }
        "HANDOFF" {
            Write-Host ""; Show-Handoff
            $c=Read-Host "`n$(T 'launch')"
            if (Test-Yes $c) {
                Sync-SessionPath
                try { & $CommandName } catch { Write-Host (T "not_found") }
            }
            $State="DONE"
        }
        "ERROR" {
            Write-Host "`n$(T 'failed'): $LastError"
            $c=Read-Host (T "retry")
            if ($c -eq "1") { $State="PRECHECK" }
            elseif ($c -eq "2") { $State="SELECT" }
            elseif ($c -eq "3") { $State="DONE" }
        }
        "DONE" {
            Read-Host (T "exit") | Out-Null
            exit
        }
    }
}

