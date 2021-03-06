function Add-Deployment
{
    <#
    .Synopsis
        Adds a Pipeworks deployment
    .Description
        Adds a PowerShell Pipeworks deployment to the list of deployed modules
    .Example
        Add-Deployment Pipeworks    
    .Link
        Get-Deployment
    .Link
        Remove-Deployment        
    #>
    [OutputType([Nullable])]
    param(
    # The name of the module
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [string]
    $Name,
    
    # The deployment group.  
    # Certain groups will be automatically created from the Pipeworks manifest.
    # * If AllowDownload=$true is set, the module will be added to the deployment group "Downloads"
    # * If Win8 is set, the module will be added to the deployment group "Win8Apps"
    # * If Bots are provided, the module will be added to the deployment group "Bots"
    # * If any command can be run online, the module will be added to the deployment group "SoftwareServices"
    # * If any command includes a price, the module will be added to the deployment group "CommercialServices"    
    # * If the module includes AdSense or PubCenter publishing, the module will be added to the deployment group "AdSupported"    
    # * If the module contains a UserTable or UserDB, the module will be added to the deployment group "UserSystems" 
    # * If the module contains analytics trackers, the module will be added to the deployment group "Analyzed"
    # * If the module contains securesettings, the module will be added to the deployment group "UsesCredential"
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string[]]
    $Group        
    )  
    begin {
        $deploymentInfoList = New-Object Collections.ArrayList                    
    }

    process {
        $deploymentInfo = @{} + $PSBoundParameters


        $realModule = Get-Module -Name $Name

        if (-not $realModule) { return }
        $moduleDir = $realModule | Split-Path
        $manifest = $realModule | Get-PipeworksManifest 

        if (-not $DeploymentInfo.Group) {
            $DeploymentInfo.Group = @()
        }

        $deploymentInfo["Path"] = $moduleDir

        if ($manifest.AllowDownload) {
            $deploymentInfo.Group += "Downloads"
            $deploymentInfo.Group = @($deploymentInfo.Group | Select-Object -Unique)
        }

        if ($manifest.Bot) {
            $deploymentInfo.Group += "Bots"
            $deploymentInfo.Group = @($deploymentInfo.Group | Select-Object -Unique)
        }

        if ($manifest.Win8) {
            $deploymentInfo.Group += "Win8Apps"

            $deploymentInfo.Group = @($deploymentInfo.Group | Select-Object -Unique)
        }
        
        if ($manifest.WebCommand) {
            $deploymentInfo.Group += "SoftwareServices"

            $deploymentInfo.Group = @($deploymentInfo.Group | Select-Object -Unique)

            if ($manifest.WebCommand.Values | Where-Object { $_.Price -or $_.Cost }) {
                $deploymentInfo.Group += "CommercialServices"
                $deploymentInfo.Group = @($deploymentInfo.Group | Select-Object -Unique)

            }
        }        

        if ($manifest.AdSenseId -or $manifest.PubCenter) {
            $deploymentInfo.Group += "AdSupported"
            $deploymentInfo.Group = @($deploymentInfo.Group | Select-Object -Unique)
        }

        if ($manifest.UserTable -or $manifest.UserDB) {
            $deploymentInfo.Group += "UserSystems"
            $deploymentInfo.Group = @($deploymentInfo.Group | Select-Object -Unique)
        }

        if ($manifest.AnalyticsID) {
            $deploymentInfo.Group += "Analyzed"
            $deploymentInfo.Group = @($deploymentInfo.Group | Select-Object -Unique)
        }

        if ($manifest.SecureSetting -or $manifest.SecureSettings) {
            $deploymentInfo.Group += "UsesCredential"
            $deploymentInfo.Group = @($deploymentInfo.Group | Select-Object -Unique)
        }

        if (-not $existingDeployments) {
            $existingDeployments = @{}
        }


        $null = $deploymentInfoList.add($deploymentInfo)        
    }

    end {
        $existingDeployments = Get-SecureSetting -Name "PipeworksDeployments" -ValueOnly
        if (-not $existingDeployments) {
            $existingDeployments = @{}
        }

        foreach ($dl in $deploymentInfoList) {
            $existingDeployments.($dl.Name) = $dl
        }
        

        Add-SecureSetting -Name PipeworksDeployments -Hashtable $existingDeployments

    }
}
 
