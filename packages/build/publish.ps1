param (
  [string] $Version,
  [string] $preReleaseTag
)
begin {
  # release step
  Write-Output 'Creating Release'

  $RootDir = Get-Location
  Write-Verbose "Current location:      $($RootDir.Path)"
  $ModuleDir = "$RootDir\packages\module"
  Write-Verbose "Module build location: $ModuleDir"

  #region Orbit specific
  Set-Location $ModuleDir

  # Defining Scope (Modules to process)
  Write-Verbose -Message 'General: Building Module Scope - Parsing Modules' -Verbose
  $global:OrbitDirs = Get-ChildItem -Path $ModuleDir -Directory | Sort-Object Name -Descending
  $global:OrbitModule = $OrbitDirs.Basename
  Write-Output "Defined Scope: $($OrbitModule -join ', ')"
  #endregion

  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
}
process {
  #Publish Module
  Write-Verbose -Message 'Publish: Loop through all Modules' -Verbose
  foreach ($Module in $OrbitModule) {
    Write-Verbose -Message "$Module`: Publishing Module - PowerShellGallery" -Verbose
    try {
      # Build a splat containing the required details and make sure to Stop for errors which will trigger the catch
      $PM = @{
        Path        = "$ModuleDir\$Module\$Module.psd1"
        NuGetApiKey = $env:NuGetApiKey
        Verbose     = $true
        ErrorAction = 'Stop'
        #Tags        = @('', '')
        #LicenseUri  = 'https://github.com/DEberhardt/Orbit/blob/master/LICENSE.md'
        #ProjectUri  = 'https://github.com/DEberhardt/Orbit'
      }

      # Fetching current Version from Module
      $ManifestTest = Test-ModuleManifest -Path $PM.path

      <# Handling prereleases
      if ('-' -in $ManifestTest.Version) {
        $Prerelease = if ( -not $preReleaseTag ) { '-PreRelease' } else { $preReleaseTag }

        $PSD1Content = (Get-Content $PM.path -Raw)
        $PSD1Content.Replace("#Prerelease = '-prerelease'", "Prerelease = '-$Prerelease'") | Out-File -Encoding 'UTF8' $PM.path

        Update-Metadata -Path $ManifestTest.Path -PropertyName Prerelease -Value $Prerelease

        $ManifestTest = Test-ModuleManifest -Path $PM.path
      }

      # Updating Version
      $Copyright = "(c) 2020-$( (Get-Date).Year ) $Name. All rights reserved."
      Update-Metadata -Path $ManifestTest.Path -PropertyName Copyright -Value $Copyright
      Update-Metadata -Path $ManifestTest.Path -PropertyName ModuleVersion -Value $Version
      #>

      Publish-Module @PM -WhatIf
      #Publish-Module @PM
      Write-Output "$Module PowerShell Module version $($ManifestTest.Version) published to the PowerShell Gallery."
    }
    catch {
      # Sad panda; it broke
      Write-Warning "Publishing update $($TestManiManifestTestfest.Version) to the PowerShell Gallery failed."
      throw $_
    }
  }
}
end {
  Set-Location $RootDir.Path
}