# Navigation Aliases
# Quick directory navigation shortcuts

# Parent directory shortcuts
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# Jump to workspace directories
function j {
    param([Parameter(Position = 0)][string]$Target)
    switch ($Target) {
        'ccenter'  { Set-Location "$HOME\command-center" }
        'labs'     { Set-Location "$HOME\labs" }
        'projects' { Set-Location "$HOME\projects" }
        'tmp'      { Set-Location "$HOME\tmp" }
        'tools'    { Set-Location "$HOME\tools" }
        default {
            Write-Host "Usage: j <target>"
            Write-Host "  ccenter   ~/command-center"
            Write-Host "  labs      ~/labs"
            Write-Host "  projects  ~/projects"
            Write-Host "  tmp       ~/tmp"
            Write-Host "  tools     ~/tools"
        }
    }
}

# Tab completion for j function
Register-ArgumentCompleter -CommandName j -ParameterName Target -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    @('ccenter', 'labs', 'projects', 'tmp', 'tools') |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}

# Project launchers
function prefect {
    Set-Location "$HOME\projects\prefect-antig"
    & uv sync
    & .\.venv\Scripts\Activate.ps1
    & claude --dangerously-skip-permissions
}
