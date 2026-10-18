# Offline state-machine tests; child scope supplies UI/network/command stubs.
$ErrorActionPreference = 'Stop'
$source = Get-Content "$PSScriptRoot/../kickstarter.ps1" -Raw
# Avoid exiting the test host at DONE; the production script stays unchanged.
$source = $source.Replace('            exit', '            return')
foreach ($mode in @('ok', 'download-error', 'installer-error', 'version-error', 'decline')) {
    $result = & {
        param($source, $mode)
        $global:ClaudeTestAnswers = [System.Collections.Generic.Queue[string]]::new()
        $confirm = if ($mode -eq 'decline') { 'n' } else { 'y' }
        foreach ($a in @('2', '4', $confirm, 'n', '3', '')) { $global:ClaudeTestAnswers.Enqueue($a) }
        function Read-Host { param($Prompt) if (!$global:ClaudeTestAnswers.Count) { throw "Unexpected prompt: $Prompt ($mode)" }; $global:ClaudeTestAnswers.Dequeue() }
        function Clear-Host {}
        function Start-Sleep { param($Seconds) }
        function Write-Host { param([Parameter(ValueFromPipeline=$true)]$Object) process { Write-Output $Object } }
        function Invoke-WebRequest {
            param($Uri, $Method, $TimeoutSec, $MaximumRedirection, [switch]$UseBasicParsing)
            if ($Uri -like '*generate_204') { return @{StatusCode=204} }
            if ($Uri -ne 'https://claude.ai/install.ps1') { throw "Wrong source: $Uri" }
            if ($mode -eq 'download-error') { throw 'stub download failure' }
            $code = if ($mode -eq 'installer-error') { 1 } else { 0 }
            return @{Content=('Write-Host ''installer-ran''; $global:LASTEXITCODE = ' + $code)}
        }
        function Get-Command { param($Name, $ErrorAction) @{Source='Invoke-ClaudeStub'} }
        function Invoke-ClaudeStub {
            param($Version)
            Write-Host 'claude-stub'
            $global:LASTEXITCODE = if ($mode -eq 'version-error') { 1 } else { 0 }
        }
        $fixture = Join-Path ([System.IO.Path]::GetTempPath()) ("kickstarter-" + [guid]::NewGuid() + ".ps1")
        try {
            [System.IO.File]::WriteAllText($fixture, $source, [System.Text.UTF8Encoding]::new($true))
            & $fixture
        } finally { Remove-Item $fixture -Force }
    } $source $mode
    $text = $result -join "`n"
    if ($mode -eq 'ok') {
        if ($text -notmatch 'Installation succeeded' -or $text -notmatch 'personal AI computer assistant') { throw "FAIL: $mode`n$text" }
    } elseif ($mode -eq 'decline') {
        if ($text -match 'installer-ran') { throw "FAIL: $mode" }
    } else {
        if ($text -notmatch 'Installation failed' -or $text -match 'personal AI computer assistant') { throw "FAIL: $mode" }
    }
    Write-Host "PASS: Claude $mode"
}

# Expected failing fixtures must not leak a native exit code to the CI host.
$global:LASTEXITCODE = 0
Remove-Variable ClaudeTestAnswers -Scope Global
