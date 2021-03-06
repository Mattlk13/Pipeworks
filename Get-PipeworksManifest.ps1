function Get-PipeworksManifest
{
    <#
    .Synopsis
        Gets the Pipeworks manifest for a module
    .Description
        Gets the Pipeworks manifest for a PowerShell module.  
                
        The pipeworks manifest is a .psd1 file that describes how the module will be published as a web service.
    .Example
        Get-PipeworksManifest -Module Pipeworks
    .Example
        Get-Module Pipeworks | Get-PipeworksManifest
    .Example
        Get-Module | Get-PipeworksManifest
    .Link
        New-PipeworksManifest
    #>
    [OutputType([Hashtable])]
    param(
    # The name of the module
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [Alias('Name')]
    [string]
    $ModuleName
    )

    process {
        
        $realModule = Get-Module $moduleName
        if (-not $realModule) { 
            Write-Error "$moduleName not found"
            return 
        } 

        if (-not $realModule.Path) { return }

        # Import pipeworks manifest
        
        $moduleRoot = Split-Path $realModule.Path                     
        #region Initialize Pipeworks Manifest
        $pipeworksManifestPath = Join-Path $moduleRoot "$($realmodule.Name).Pipeworks.psd1"
        if (Test-Path $pipeworksManifestPath) {
            try {                     
                $result = & ([ScriptBlock]::Create(
                    "data -SupportedCommand Add-Member, New-WebPage, New-Region, Write-CSS, Write-Ajax, Out-Html, Write-Link { $(
                        [ScriptBlock]::Create([IO.File]::ReadAllText($pipeworksManifestPath))                    
                    )}"))
                    
                $result.Name = $moduleName 
                $result.Module = $realModule
                $result |
                    Add-Member NoteProperty Name $ModuleName -Force -PassThru |                  
                    Add-Member NoteProperty Module $RealModule -Force -PassThru
            } catch {
                # Write-Error "Could not read pipeworks manifest for $ModuleName" 
                return
            }                                                
        }

    }
}