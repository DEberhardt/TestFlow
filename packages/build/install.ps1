begin {
  # Install step
  Write-Verbose -Message 'Preparing Environment' -Verbose

  $RootDir = Get-Location
  Write-Output "Current location:      $($RootDir.Path)"

  # Installing Standard Version
  #npm i -g standard-version
}
process {
  # Install package providers for PowerShell Modules
  Write-Verbose -Message 'Installing Package Provider' -Verbose
  [string[]]$PackageProviders = @('NuGet', 'PowerShellGet')
  foreach ($Provider in $PackageProviders) {
    if (!(Get-PackageProvider $Provider -ErrorAction SilentlyContinue)) {
      Install-PackageProvider $Provider -Force -ForceBootstrap -Scope CurrentUser
    }
  }

  # Install the PowerShell Modules
  Write-Verbose -Message 'Installing PowerShell Modules' -Verbose
  [string[]]$PowerShellModules = @('Pester', 'posh-git', 'platyPS', 'InvokeBuild', 'BuildHelpers', 'MicrosoftTeams')
  foreach ($Module in $PowerShellModules) {
    Write-Output "Installing $Module"
    if (!(Get-Module -ListAvailable $Module -ErrorAction SilentlyContinue)) {
      $InstallSplat = @{
        'Name'         = $Module
        'Scope'        = 'CurrentUser'
        'Repository'   = 'PSGallery'
        'Force'        = $true
        'AllowClobber' = $true
      }
      Install-Module @InstallSplat
    }
    If (!(Get-Module $Module -ErrorAction SilentlyContinue)) {
      $ImportSplat = @{
        'Name'  = $Module
        'Force' = $true
      }
      #if ( $Module -eq 'AzureAdPreview' ) { $ImportSplat += @{ 'Cmdlet' = @('Open-AzureADMSPrivilegedRoleAssignmentRequest', 'Get-AzureADMSPrivilegedRoleAssignment') } }
      Import-Module @ImportSplat
    }
  }
  Get-Module

}
end {
  Set-Location $RootDir.Path
}