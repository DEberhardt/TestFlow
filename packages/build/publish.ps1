begin {
  # release step
  Write-Verbose -Message 'Creating Release' -Verbose

  $RootDir = Get-Location
  Write-Output "Current location:      $($RootDir.Path)"
  #$ModuleDir = "$RootDir\packages\module"
  $ModuleDir = "$RootDir\src"
  Write-Output "Module build location: $ModuleDir"

  # Importing Package.json for processing & reading version from file
  $PackageJson = Get-Content $RootDir\package.json -Raw | ConvertFrom-Json
  $ModuleVersion = $PackageJson.Version
  Write-Output "New Version is '$ModuleVersion'"

  #region Orbit specific
  Set-Location $ModuleDir

  # Defining Scope (Modules to process)
  Write-Verbose -Message 'General: Building Module Scope - Parsing Modules' -Verbose
  $global:ModuleDirectory = Get-ChildItem -Path $ModuleDir -Directory | Sort-Object Name -Descending
  $global:ModulesToParse = $ModuleDirectory.Basename
  Write-Output "Defined Scope: $($ModulesToParse -join ', ')"
  #endregion

  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
}
process {
  #Publish Module
  Write-Verbose -Message 'Publish: Loop through all Modules' -Verbose
  foreach ($Module in $ModulesToParse) {
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

      # Handling prereleases
      if ($PackageJson.isPreRelease) {
        $preReleaseTag = $PackageJson.preReleaseTag

        $PrivateData = Get-Metadata -Path $ManifestTest.Path -PropertyName PrivateData
        $PrivateData.PsData.Prerelease = "-$preReleaseTag" # Adding or setting Prerelease tag
        Update-Metadata -Path $ManifestTest.Path -PropertyName PrivateData -Value $PrivateData

        $ManifestTest = Test-ModuleManifest -Path $PM.path

        <# Alternative to the above, crude replacement in file
        # This requires the string "#Prerelease = '-prerelease'" in the PrivateData.Psdata object!
        $PSD1Content = (Get-Content $PM.path -Raw)
        $PSD1Content.Replace("#Prerelease = '-prerelease'", "Prerelease = '-$preReleaseTag'") | Out-File -Encoding 'UTF8' $PM.path
        #>
      }

      # Updating Metadata from Package.json - for Definition see above
      # Updating Copyright
      $CurrentYear = $( (Get-Date).Year )
      $Copyright = $PackageJson.Copyright -replace '$CurrentYear', $CurrentYear
      Update-Metadata -Path $ManifestTest.Path -PropertyName Copyright -Value $Copyright

      # Updating Version
      Update-Metadata -Path $ManifestTest.Path -PropertyName ModuleVersion -Value $ModuleVersion


      # Publishing Module
      Publish-Module @PM -WhatIf
      #Publish-Module @PM
      Write-Output "PowerShell Module '$Module', Version $($ManifestTest.Version) published to the PowerShell Gallery."
    }
    catch {
      # Sad panda; it broke
      Write-Warning "PowerShell Module '$Module', Publishing module failed for Version $($TestManiManifestTestfest.Version)"
      throw $_
    }
  }
}
end {
  Set-Location $RootDir.Path
}