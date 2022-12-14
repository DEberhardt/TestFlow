begin {
  # document step
  Write-Verbose -Message 'Updating Documentation & README' -Verbose

  $RootDir = $(Get-Location).path
  Write-Output "Current location:      $RootDir"
  #$ModuleDir = "$RootDir\packages\module"
  $ModuleDir = "$RootDir\src"
  Write-Output "Module build location: $ModuleDir"

  # Adding custom script Set-ShieldsIoBadge2 (Build helper Module has a bug that is yet to be fixed, PR pending)
  . $PSScriptRoot\Set-ShieldsIoBadge2.ps1
  . $PSScriptRoot\Get-FunctionStatus.ps1

  Set-Location $ModuleDir
  $global:ModuleDirectory = Get-ChildItem -Path $ModuleDir -Directory | Sort-Object Name -Descending
  $global:ModulesToParse = $ModuleDirectory.Basename

}
process {
  Write-Verbose -Message 'Documentation update - Displaying README before changes are made to it' -Verbose
  $README = Get-Content $RootDir\README.md
  $README

  # Setting Build Helpers Build Environment ENV:BH*
  Set-BuildEnvironment -Path $ModuleDir

  # Updating Component Status
  Write-Verbose -Message 'Documentation update - Updating Build Status in README' -Verbose
  Set-ShieldsIoBadge2 -Path $RootDir\README.md # Default updates 'Build' to 'pass' or 'fail'

  Write-Verbose -Message 'Documentation update - Querying Private & Public Functions & their status' -Verbose
  $AllPublicFunctions = Get-ChildItem -LiteralPath $global:ModuleDirectory.FullName | Where-Object Name -EQ 'Public' | Get-ChildItem -Filter *.ps1
  Write-Output "Counting AllPublicFunctions: $($AllPublicFunctions.Count)"
  $AllPrivateFunctions = Get-ChildItem -LiteralPath $global:ModuleDirectory.FullName | Where-Object Name -EQ 'Private' | Get-ChildItem -Filter *.ps1
  Write-Output "Counting AllPrivateFunctions: $($AllPrivateFunctions.Count)"
  $Script:FunctionStatus = Get-Functionstatus -PublicPath $($AllPublicFunctions.FullName) -PrivatePath $($AllPrivateFunctions.FullName)
  Write-Output $Script:FunctionStatus

  # Updating Component Status
  Write-Verbose -Message 'Documentation update - Updating Component Status in README' -Verbose

  Set-ShieldsIoBadge2 -Path $RootDir\README.md -Subject Public -Status $Script:FunctionStatus.Public -Color blue
  Set-ShieldsIoBadge2 -Path $RootDir\README.md -Subject Private -Status $Script:FunctionStatus.Private -Color grey

  Set-ShieldsIoBadge2 -Path $RootDir\README.md -Subject Live -Status $Script:FunctionStatus.PublicLive -Color blue
  Set-ShieldsIoBadge2 -Path $RootDir\README.md -Subject RC -Status $Script:FunctionStatus.PublicRC -Color green
  Set-ShieldsIoBadge2 -Path $RootDir\README.md -Subject BETA -Status $Script:FunctionStatus.PublicBeta -Color yellow
  Set-ShieldsIoBadge2 -Path $RootDir\README.md -Subject ALPHA -Status $Script:FunctionStatus.PublicAlpha -Color orange

  Write-Verbose -Message 'Documentation update - Displaying README for validation' -Verbose
  $README = Get-Content $RootDir\README.md
  $README


  # Create new markdown and XML help files
  Write-Verbose -Message 'Creating MarkDownHelp with PlatyPs' -Verbose
  Import-Module PlatyPs
  foreach ($Module in $ModulesToParse) {
    Write-Verbose -Message "Importing Module: $Module" -Verbose
    Write-Output "Module Path: '$ModuleDir\$Module\$Module.psd1'"
    Import-Module "$ModuleDir\$Module\$Module.psd1" -Force
    $ModuleLoaded = Get-Module $Module
    if (-not $ModuleLoaded) { throw "Module '$Module' not found" }
    $DocsFolder = "$RootDir\docs\$Module\"

    New-MarkdownHelp -Module $ModuleLoaded.Name -OutputFolder $DocsFolder -Force -AlphabeticParamsOrder:$false
    New-ExternalHelp -Path $DocsFolder -OutputPath $DocsFolder -Force
    $HelpFiles = Get-ChildItem -Path $DocsFolder -Recurse
    Write-Output "Helpfiles total: $($HelpFiles.Count)"
  }

  # Updating version for Release Workflow
  Write-Verbose -Message 'Updating Package.json with Version Number' -Verbose
  # Fetching current Version from Root Module
  $ManifestPath = "$ModuleDir\DEModuleTest\DEModuleTest.psd1"
  $ManifestTest = Test-ModuleManifest -Path $ManifestPath

  # Workflow Changelog and Release Drafter are using Package.json file to read new version
  $PackageJSON = Get-Content "$RootDir\package.json" -Raw | ConvertFrom-Json
  $PackageJSON.Version = $ManifestTest.Version.ToString()
  Write-Output "Packgage.JSON updated to $($PackageJSON.Version)"
  $PackageJSON | ConvertTo-Json | Set-Content "$RootDir\package.json"
  $PackageJSON

}
end {
  Set-Location $RootDir
}