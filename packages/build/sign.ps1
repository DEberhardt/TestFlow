begin {
  # Sign step
  Write-Verbose -Message 'Signing module' -Verbose

  $RootDir = $(Get-Location).path
  Write-Output "Current location:      $RootDir"
  #$ModuleDir = "$RootDir\packages\module"
  $ModuleDir = "$RootDir\src"
  Write-Output "Module build location: $ModuleDir"

}
process {
  # Setting Location
  Set-Location $ModuleDir

  # Defining Scope (Modules to process)
  Write-Verbose -Message 'General: Building Module Scope - Parsing Modules' -Verbose
  $global:ModuleDirectory = Get-ChildItem -Path $ModuleDir -Directory | Sort-Object Name -Descending
  $global:ModulesToParse = $ModuleDirectory.Basename
  Write-Output "Defined Scope: $($ModulesToParse -join ', ')"
  #endregion

  # Singing all Modules
  #TODO does this need to be done for all modules or is it enough to sign the Main module?
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


    # This should be replaced by signing the script with Secret from Github Actions (personal certificate)
    Write-Verbose -Message "$Module`: Applying Authenticode Signature" -Verbose
    #Import-Module Microsoft.PowerShell.Security
    Write-Output 'Currently SKIPPED - This should be replaced by signing the script with Secret from Github Actions (personal certificate)' -Verbose
    #Codesign Variable to use: $env:CodeSign

  }
}
end {
  Set-Location $RootDir
}