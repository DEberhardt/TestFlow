begin {
  # Build step
  Write-Verbose -Message 'Building module' -Verbose

  $RootDir = Get-Location
  Write-Output "Current location:      $($RootDir.Path)"
  $ModuleDir = "$RootDir\packages\module"
  Write-Output "Module build location: $ModuleDir"

  # Importing Package.json for processing & reading version from file
  $PackageJson = Get-Content $RootDir\package.json -Raw | ConvertFrom-Json
  $ModuleVersion = $PackageJson.Version
  Write-Output "Current Version is '$ModuleVersion'"
}
process {
  Write-Verbose -Message 'Creating Directory' -Verbose
  # Create Directory
  New-Item -Path $ModuleDir -ItemType Directory

  # Copy from Server
  Write-Verbose -Message 'Copying Module' -Verbose
  $Excludes = @('.vscode', '*.git*', '*.md', 'Archive', 'Incubator', 'packages', 'Workbench', 'PSScriptA*', 'Scrap*.*')
  Copy-Item -Path .\src\* -Destination $ModuleDir -Exclude $Excludes -Recurse -Force

  # Setting Location
  Set-Location $ModuleDir

  # Defining Scope (Modules to process)
  Write-Verbose -Message 'General: Building Module Scope - Parsing Modules' -Verbose
  $global:ModuleDirectory = Get-ChildItem -Path $ModuleDir -Directory | Sort-Object Name -Descending
  $global:ModulesToParse = $ModuleDirectory.Basename
  Write-Output "Defined Scope: $($ModulesToParse -join ', ')"

  # Setting location to Module Root ($ModuleDir)
  Write-Verbose -Message 'General: Set-BuildEnvironment to Module Directory' -Verbose
  $ManifestPath = "$ModuleDir\DEModuleTest\DEModuleTest.psd1"
  $ManifestTest = Test-ModuleManifest -Path $ManifestPath

  # Setting Build Helpers Build Environment ENV:BH*
  Set-BuildEnvironment -Path $ManifestTest.ModuleBase

  # Resetting RequiredModules in Orbit Root to allow processing via Build script - This will be added later, before publishing
  Write-Verbose -Message "General: Updating Orbit.psm1 to reflect all nested Modules' Version" -Verbose
  $RequiredModulesValue = @(
    @{ModuleName = 'MicrosoftTeams'; ModuleVersion = '4.8.0'; }
  )
  Update-Metadata -Path $env:BHPSModuleManifest -PropertyName RequiredModules -Value $RequiredModulesValue
  #region

  # Updating all Modules
  Write-Verbose -Message 'Build: Loop through all Modules' -Verbose
  foreach ($Module in $ModulesToParse) {
    Write-Verbose -Message "$Module`: Testing Manifest" -Verbose
    # This is where the module manifest lives
    $ManifestPath = "$ModuleDir\$Module\$Module.psd1"
    $ManifestTest = Test-ModuleManifest -Path $ManifestPath

    # Setting Build Helpers Build Environment ENV:BH*
    Write-Verbose -Message "$Module`: Preparing Build Environment" -Verbose
    Set-BuildEnvironment -Path $ManifestTest.ModuleBase -Force
    Get-Item ENV:BH* | Select-Object Key, Value

    # Functions to Export
    $Pattern = @('FunctionsToExport', 'AliasesToExport')
    $Pattern | ForEach-Object {
      Write-Output "Old $_`:"
      Select-String -Path $manifestPath -Pattern $_

      switch ($_) {
        'FunctionsToExport' { Set-ModuleFunction -Name $manifestPath }
        'AliasesToExport' { Set-ModuleAlias -Name $manifestPath }
      }

      Write-Output "New $_`:"
      Select-String -Path $manifestPath -Pattern $_
    }

    # Updating Metadata from Package.json - for Definition see above
    # Updating Copyright
    $CurrentYear = $( (Get-Date).Year )
    $Copyright = $PackageJson.Copyright -replace '$CurrentYear', $CurrentYear
    Update-Metadata -Path $ManifestTest.Path -PropertyName Copyright -Value $Copyright

    # Updating Version
    Update-Metadata -Path $ManifestTest.Path -PropertyName ModuleVersion -Value $ModuleVersion

    Write-Output 'Manifest re-tested incl. Version, Copyright, etc.'
    $ManifestTest = Test-ModuleManifest -Path $ManifestPath
    $ManifestTest

    #Importing Module
    Write-Verbose -Message "$($manifestTest.Name) Importing Module" -Verbose
    Import-Module $ManifestPath

  }

}
end {
  Set-Location $RootDir.Path
}