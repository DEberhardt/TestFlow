begin {
  # Install step
  Write-Verbose -Message 'Preparing Environment' -Verbose

  $RootDir = Get-Location
  Write-Output "Current location:      $($RootDir.Path)"

  # Installing Standard Version
  #npm i -g standard-version
}
process {
  # Installation of PowerShell Modules is done through PsModuleCache
  # Here we simply import them so that they are ready to use
  Write-Verbose -Message 'Installing PowerShell Modules' -Verbose
  [string[]]$PowerShellModules = @('Pester', 'posh-git', 'platyPS', 'InvokeBuild', 'BuildHelpers', 'MicrosoftTeams')
  foreach ($Module in $PowerShellModules) {
    If (!(Get-Module $Module -ErrorAction SilentlyContinue)) {
      $ImportSplat = @{
        'Name'  = $Module
        'Force' = $true
      }
      #if ( $Module -eq 'AzureAdPreview' ) { $ImportSplat += @{ 'Cmdlet' = @('Open-AzureADMSPrivilegedRoleAssignmentRequest', 'Get-AzureADMSPrivilegedRoleAssignment') } }
      Write-Output "Importing Module: $Module"
      Import-Module @ImportSplat
    }
  }
  Get-Module

}
end {
  Set-Location $RootDir.Path
}