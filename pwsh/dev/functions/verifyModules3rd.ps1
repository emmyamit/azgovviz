function verifyModules3rd {
    [CmdletBinding()]Param(
        [object]$modules
    )

    foreach ($module in $modules) {
        $moduleVersion = $module.ModuleVersion

        if ($moduleVersion) {
            Write-Host " Verify '$($module.ModuleName)' ($moduleVersion)"
        }
        else {
            Write-Host " Verify '$($module.ModuleName)' (latest)"
        }

        $maxRetry = 3
        $tryCount = 0
        do {
            $tryCount++
            if ($tryCount -gt $maxRetry) {
                Write-Host " Managing '$($module.ModuleName)' failed (tried $($tryCount - 1)x)"
                throw " Managing '$($module.ModuleName)' failed"
            }

            $installModuleSuccess = $false
            try {

                if (-not $moduleVersion) {
                    Write-Host '  Check latest module version'
                    try {
                        $moduleVersion = (Find-Module -name $($module.ModuleName)).Version
                        Write-Host "  Latest module version: $moduleVersion"
                        if ($module.ModuleName -eq 'PSRule.Rules.Azure') {
                            $PSRuleVersion = $moduleVersion
                        }
                    }
                    catch {
                        Write-Host '  Check latest module version failed'
                        throw
                    }
                }

                if (-not $installModuleSuccess) {
                    $moduleVersionLoaded = (Get-InstalledModule -name $($module.ModuleName)).Version
                    if ($moduleVersionLoaded -eq $moduleVersion) {
                        $installModuleSuccess = $true
                    }
                    else {
                        throw "  '(Get-InstalledModule -name $($module.ModuleName)).Version' returned null"
                    }
                }
            }
            catch {
                Write-Host "  '$($module.ModuleName)' not installed"
                if (($env:SYSTEM_TEAMPROJECTID -and $env:BUILD_REPOSITORY_ID) -or $env:GITHUB_ACTIONS) {
                    Write-Host "  Installing $($module.ModuleName) module ($($moduleVersion))"
                    try {
                        $params = @{
                            Name            = "$($module.ModuleName)"
                            Force           = $true
                            RequiredVersion = $moduleVersion
                        }
                        Install-Module @params
                    }
                    catch {
                        throw "  Installing '$($module.ModuleName)' module ($($moduleVersion)) failed"
                    }
                }
                else {
                    do {
                        $installModuleUserChoice = $null
                        $installModuleUserChoice = Read-Host "  Do you want to install $($module.ModuleName) module ($($moduleVersion)) from the PowerShell Gallery? (y/n)"
                        if ($installModuleUserChoice -eq 'y') {
                            try {
                                Install-Module -Name $module.ModuleName -RequiredVersion $moduleVersion
                            }
                            catch {
                                throw "  'Install-Module -Name $module.ModuleName -RequiredVersion $moduleVersion' failed"
                            }
                        }
                        elseif ($installModuleUserChoice -eq 'n') {
                            Write-Host "  $($module.ModuleName) module is required, please visit https://aka.ms/$($module.ModuleProductName) or https://www.powershellgallery.com/packages/$($module.ModuleProductName)"
                            throw "  $($module.ModuleName) module is required"
                        }
                        else {
                            Write-Host "  Accepted input 'y' or 'n'; start over.."
                        }
                    }
                    until ($installModuleUserChoice -eq 'y')
                }
            }
        }
        until ($installModuleSuccess)
    }
}