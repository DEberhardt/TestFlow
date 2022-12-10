begin {
  # release step
  Write-Verbose -Message 'Creating Release' -Verbose

  $RootDir = $(Get-Location).path
  Write-Output "Current location:      $RootDir"
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
    Write-Verbose -Message "Module '$Module': Publishing Module to PowerShellGallery" -Verbose
    try {
      # Build a splat containing the required details and make sure to Stop for errors which will trigger the catch
      $PM = @{
        #Name        = "$ModuleDir\$Module\$Module.psd1"
        Path        = "$ModuleDir\$Module"
        NuGetApiKey = $env:NuGetApiKey
        Verbose     = $true
        ErrorAction = 'Stop'
        LicenseUri  = $PackageJson.LicenseUri
        ProjectUri  = $PackageJson.ProjectUri
      }

      # Fetching current Version from Module
      $ManifestFile = "$($PM.path)\$Module.psd1"
      $ManifestTest = Test-ModuleManifest -Path $ManifestFile

      # Handling prereleases
      $PrivateData = Get-Metadata -Path $ManifestFile -PropertyName PrivateData
      if ( $PackageJson.isPreRelease -eq 'true' ) {
        $preReleaseTag = $PackageJson.preReleaseTag

        $PrivateData = Get-Metadata -Path $ManifestFile -PropertyName PrivateData
        $PrivateData.PsData.Prerelease = $preReleaseTag # Adding or setting Prerelease tag
        Update-Metadata -Path $ManifestFile -PropertyName PrivateData -Value $PrivateData

        $ManifestTest = Test-ModuleManifest -Path $ManifestFile
      }
      else {
        if ( $PrivateData.PsData.ContainsKey('PreRelease') ) {
          [void]$PrivateData.PsData.Remove('PreRelease')
          Update-Metadata -Path $ManifestFile -PropertyName PrivateData -Value $PrivateData
          $ManifestTest = Test-ModuleManifest -Path $ManifestFile
        }
        else {
          Write-Output 'No Pre-Release key found in Manifest: OK'
        }
      }

      # Updating Metadata from Package.json - for Definition see above
      # Updating Copyright
      $CurrentYear = $( (Get-Date).Year )
      $Copyright = $PackageJson.Copyright -replace '$CurrentYear', $CurrentYear
      Update-Metadata -Path $ManifestFile -PropertyName Copyright -Value $Copyright

      # Updating Version
      Update-Metadata -Path $ManifestFile -PropertyName ModuleVersion -Value $ModuleVersion

      # Output ManifestTest
      Write-Output $ManifestTest

      # Publishing Module
      #Publish-Module @PM -WhatIf
      Publish-Module @PM
      Write-Output "PowerShell Module '$Module', Version $($ManifestTest.Version) published to the PowerShell Gallery."
    }
    catch {
      # Sad panda; it broke
      Write-Warning "PowerShell Module '$Module', Publishing module failed for Version $($ManifestTest.Version)"
      throw $_
    }
  }
}
end {
  Set-Location $RootDir
}