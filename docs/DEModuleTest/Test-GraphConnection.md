---
external help file: DEModuleTest-help.xml
Module Name: DEModuleTest
online version: https://github.com/DEberhardt/TeamsFunctions/tree/main/docs/Test-GraphConnection.md
schema: 2.0.0
---

# Test-GraphConnection

## SYNOPSIS
Tests whether a valid PS Session exists for Azure Active Directory (v2)

## SYNTAX

```
Test-GraphConnection [<CommonParameters>]
```

## DESCRIPTION
A connection established via Connect-AzureAD is parsed.

## EXAMPLES

### EXAMPLE 1
```
Test-GraphConnection
```

Will Return $TRUE only if a session is found.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### Boolean
## NOTES
Calls Get-MgContext to determine whether a Connection exists

## RELATED LINKS

[https://github.com/DEberhardt/TeamsFunctions/tree/main/docs/Test-GraphConnection.md](https://github.com/DEberhardt/TeamsFunctions/tree/main/docs/Test-GraphConnection.md)

[https://github.com/DEberhardt/TeamsFunctions/tree/main/docs/about_TeamsSession.md](https://github.com/DEberhardt/TeamsFunctions/tree/main/docs/about_TeamsSession.md)

[https://github.com/DEberhardt/TeamsFunctions/tree/main/docs/](https://github.com/DEberhardt/TeamsFunctions/tree/main/docs/)

