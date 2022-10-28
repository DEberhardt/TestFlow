using module .\Class\DEModuleTest.Classes.psm1
# Above needs to remain the first line to import Classes
# remove the comment when using classes

# Requirements
#requires -Version 7
#Requires -Modules @{ ModuleName="MicrosoftTeams"; ModuleVersion="4.8.0" }

<#
  DEModuleTest - Module used for testing Github Workflows & Actions

  by David Eberhardt
  david@davideberhardt.at
  @MightyOrmus
  www.davideberhardt.at
  https://github.com/DEberhardt
  https://davideberhardt.wordpress.com/

  Any and all technical advice, scripts, and documentation are provided as is with no guarantee.
  Always review any code and steps before applying to a production system to understand their full impact.

.LINK
  https://github.com/DEberhardt/TestFlow/tree/master/docs

#>

#region Functions
#Get public and private function definition files.
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Recurse -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Recurse -ErrorAction SilentlyContinue )

#Dot source the files
Foreach ($Function in @($Public + $Private)) {
  Try {
    . $Function.Fullname
  }
  Catch {
    Write-Error -Message "Failed to import function $($Function.Fullname): $_"
  }
}

# Exporting Module Members (Functions)
Export-ModuleMember -Function $Public.Basename
#endregion

#region Aliases
# Query Aliases
$Aliases = $null
#$Aliases = Foreach ($Function in @($Public + $Private)) {
$Aliases = Foreach ($Function in @($Public)) {
  if ( $($Function.Fullname) -match '.tests.ps1' ) { continue }
  $Content = $AliasBlocks = $null

  $Content = $Function | Get-Content

  $AliasBlocks = $Content -split "`n" | Select-String 'Alias\(' -Context 1, 1
  $AliasBlocks | ForEach-Object {
    $Lines = $($_ -split "`n")
    if ( $Lines[0] -match 'CmdletBinding' -or $Lines[0] -match 'OutputType' -or $Lines[2] -match 'CmdletBinding' -or $Lines[2] -match 'OutputType' ) {
      if ( $($_ -split "`n")[1] -match "Alias\('(?<content>.*)'\)" ) {
        $($matches.content -split ',' -replace "'" -replace ' ') | ForEach-Object { if ( $_ -ne '' ) { $_ } }
      }
    }
    else {
      continue
    }
  }
}

# Manual definitions
$ManualAliases = @()

# Exporting Module Members (Aliases)
$AliasesToExport = @($Aliases + $ManualAliases)
Write-Verbose -Message "Aliases to Export - Count: $($Aliases.Count)"
Write-Verbose -Message "Aliases to Export - List: $($Aliases -join ',')"
if ( $AliasesToExport ) {
  Export-ModuleMember -Alias $AliasesToExport
}
#endregion

#region Variables

# Defining Help URL Base string:
$global:OrbitHelpURLBase = 'https://github.com/DEberhardt/TestFlow/blob/master/docs/'

#endregion
