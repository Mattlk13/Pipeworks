function Use-DashboardSchematic
{
    <#
    .Synopsis
        Builds a web application according to a schematic
    .Description
        Use-Schematic builds a web application according to a schematic.
        
        Web applications should not be incredibly unique: they should be built according to simple schematics.        
    .Notes
    
        When ConvertTo-ModuleService is run with -UseSchematic, if a directory is found beneath either Pipeworks 
        or the published module's Schematics directory with the name Use-Schematic.ps1 and containing a function 
        Use-Schematic, then that function will be called in order to generate any pages found in the schematic.
        
        The schematic function should accept a hashtable of parameters, which will come from the appropriately named 
        section of the pipeworks manifest
        (for instance, if -UseSchematic Blog was passed, the Blog section of the Pipeworks manifest would be used for the parameters).
        
        It should return a hashtable containing the content of the pages.  Content can either be static HTML or .PSPAGE                
    #>
    [OutputType([Hashtable])]
    param(
    # Any parameters for the schematic
    [Parameter(Mandatory=$true)][Hashtable]$Parameter,
    
    # The pipeworks manifest, which is used to validate common parameters
    [Parameter(Mandatory=$true)][Hashtable]$Manifest,
    
    # The directory the schemtic is being deployed to
    [Parameter(Mandatory=$true)][string]$DeploymentDirectory,
    
    # The directory the schematic is being deployed from
    [Parameter(Mandatory=$true)][string]$InputDirectory     
    )
    
    process {
    
        if (-not $Parameter.Dashboards) {
            Write-Error "No items found"
            return
        }
        
        if (-not $Parameter.EdgeColor) {
            Write-Error "Managers must have an edge color"
            return
        }
        
        if (-not $Parameter.BackgroundColor) {
            Write-Error "Managers must have a background color"
            return
        }
        
        
        
                               
                                                              
        
        $stagesInTables = 
            $parameter.Dashboards.GetEnumerator() | 
                Where-Object { 
                    $_.Value.Id 
                } 
        
        if ($stagesInTables) {
            if (-not $Manifest.Table.Name) {
                Write-Error "No table found in manifest"
                return
            }
            
            if (-not $Manifest.Table.StorageAccountSetting) {
                Write-Error "No storage account name setting found in manifest"
                return
            }
            
            if (-not $manifest.Table.StorageKeySetting) {
                Write-Error "No storage account key setting found in manifest"
                return
            }
        }
        
        
        $outputPages = @{}
        
        $orgName = $parameter.Organization.Name
        
        
        $orginfo = if ($parameter.Organization) {
            $parameter.Organization
        } else {
            @{}
        }
        
        $pageName = $parameter.Name
        $pageHeaderImage = $parameter.pageHeaderImage
        
        
        
        foreach ($dashboardObject in @($parameter.Dashboards)) {
            $pageName = $dashboardObject.Name
            $pageHeaderImage = $dashboardObject.pageHeaderImage
            
            $pageScript = "
`$pageName = '$pageName'
`$pageHeaderImage = '$pageHeaderImage';
`$edgeColor = '$($parameter.EdgeColor)';`
`$dashboardColor ='$($parameter.DashboardColor)';
`$bgColor = '$($parameter.BackgroundColor)';
`$fontName = '$(if ($parameter.FontName) {  $parameter.FontName }else { 'Gisha' } )'
`$orginfo= $(Write-PowerShellHashtable -InputObject $orginfo )
`$dashboard = @(`$pipeworksManifest.Dashboard.Dashboards) | Where-Object { `$_.Name -eq '$pageName' } 
" + {
$headerContent = 
    if ($pageHeaderImage) {
        "<img src='Assets/$pageHeaderImage' style='width:100%' />        
        "    
    } else {
        "<h1 style='text-align:center;font-size:xx-large;' class='ui-widget-content ui-corner-all'>        
            $($module.Name)
        </h1>
        "
    }
        
        
$showCommandOutputIfLoggedIn = {
    param($cmdName, [Hashtable]$CmdParameter = @{}) 
    
    if (-not $session['User'] -and $request.Cookies["$($module.Name)_ConfirmationCookie"]) {
        
        $storageAccount = (Get-WebConfigurationSetting -Setting $pipeworksManifest.UserTable.StorageAccountSetting)
        $storageKey = (Get-WebConfigurationSetting -Setting $pipeworksManifest.UserTable.StorageKeySetting)
        $confirmCookie= $Request.Cookies["$($module.Name)_ConfirmationCookie"]

        $matchApiInfo = [ScriptBLock]::Create("`$_.SecondaryApiKey -eq '$($confirmCookie.Values['Key'])'")           
        $userFound = 
            Search-AzureTable -TableName $pipeworksManifest.UserTable.Name -StorageAccount $storageAccount -StorageKey $storageKey -Where $matchApiInfo 

        if (-not $userFound) {
            $secondaryApiKey = $session["$($module.Name)_ApiKey"]
            $confirmCookie = New-Object Web.HttpCookie "$($module.Name)_ConfirmationCookie"
            $confirmCookie["Key"] = "$secondaryApiKey"
            $confirmCookie["CookiedIssuedOn"] = (Get-Date).ToString("r")
            $confirmCookie.Expires = (Get-Date).AddDays(-365)                    
            $response.Cookies.Add($confirmCookie)
            $response.Flush()
            
            $response.Write("User $($confirmCookie | Out-String) Not Found, ConfirmationCookie Set to Expire")                                        
            return
        }                                        

        $userIsConfirmed = $userFound |
            Where-Object {
                $_.Confirmed -ilike "*$true*" 
            }
            
        $userIsConfirmedOnThisMachine = $userIsConfirmed |
            Where-Object {
                $_.ConfirmedOn -ilike "*$($Request['REMOTE_ADDR'] + $request['REMOTE_HOST'])*"
            }
                
        if (-not $userIsConfirmedOnThisMachine) {                                                            
                return
        }
         
        $session['User'] = $userIsConfirmedOnThisMachine
        $session['UserId'] = $userIsConfirmedOnThisMachine.UserId


        $secondaryApiKey = "$($confirmCookie.Values['Key'])"                                                                                   

        $partitionKey = $userIsConfirmedOnThisMachine.PartitionKey
        $rowKey = $userIsConfirmedOnThisMachine.RowKey
        $tableName = $userIsConfirmedOnThisMachine.TableName
        $userIsConfirmedOnThisMachine.psobject.properties.Remove('PartitionKey')
        $userIsConfirmedOnThisMachine.psobject.properties.Remove('RowKey')
        $userIsConfirmedOnThisMachine.psobject.properties.Remove('TableName')                    
        $userIsConfirmedOnThisMachine | Add-Member -MemberType NoteProperty -Name LastLogon -Force -Value (Get-Date)
        $userIsConfirmedOnThisMachine | Add-Member -MemberType NoteProperty -Name LastLogonFrom -Force -Value "$($Request['REMOTE_ADDR'] + $request['REMOTE_HOST'])"
        $userIsConfirmedOnThisMachine |
            Update-AzureTable -TableName $tableName -RowKey $rowKey -PartitionKey $partitionKey -Value { $_} 
            
        $session['User'] = $userIsConfirmedOnThisMachine                
    }
                             
        
    if ($session['User']) {   
        $loginName = if ($session['User'].Name) {
            $session['User'].Name
        } else {
            $session['User'].UserEmail
        }
        $commandInfo = Get-Command $cmdName        
        & $commandInfo @CmdParameter | Out-HTML
    } else { @"
<div id='loginHolder_For_$cmdName'>    
    
</div>
<script>
    query = 'Module.ashx?join=true'        
    `$(function() {
        `$.ajax({
            url: query,
            cache: false,
            success: function(data){     
                `$('#loginHolder_For_$cmdName').html(data);
            } 
        })
    })
</script>
"@
    }
    
}

$showCommandInputIfLoggedIn = { param($cmdName) 
    if (-not $session['User'] -and $request.Cookies["$($module.Name)_ConfirmationCookie"]) {
        
        $storageAccount = (Get-WebConfigurationSetting -Setting $pipeworksManifest.UserTable.StorageAccountSetting)
        $storageKey = (Get-WebConfigurationSetting -Setting $pipeworksManifest.UserTable.StorageKeySetting)
        $confirmCookie= $Request.Cookies["$($module.Name)_ConfirmationCookie"]

        $matchApiInfo = [ScriptBLock]::Create("`$_.SecondaryApiKey -eq '$($confirmCookie.Values['Key'])'")           
        $userFound = 
            Search-AzureTable -TableName $pipeworksManifest.UserTable.Name -StorageAccount $storageAccount -StorageKey $storageKey -Where $matchApiInfo 

        if (-not $userFound) {
            $secondaryApiKey = $session["$($module.Name)_ApiKey"]
            $confirmCookie = New-Object Web.HttpCookie "$($module.Name)_ConfirmationCookie"
            $confirmCookie["Key"] = "$secondaryApiKey"
            $confirmCookie["CookiedIssuedOn"] = (Get-Date).ToString("r")
            $confirmCookie.Expires = (Get-Date).AddDays(-365)                    
            $response.Cookies.Add($confirmCookie)
            $response.Flush()
            
            $response.Write("User $($confirmCookie | Out-String) Not Found, ConfirmationCookie Set to Expire")                                        
            return
        }                                        

        $userIsConfirmed = $userFound |
            Where-Object {
                $_.Confirmed -ilike "*$true*" 
            }
            
        $userIsConfirmedOnThisMachine = $userIsConfirmed |
            Where-Object {
                $_.ConfirmedOn -ilike "*$($Request['REMOTE_ADDR'] + $request['REMOTE_HOST'])*"
            }
                
        if (-not $userIsConfirmedOnThisMachine) {                                                            
                return
        }
         
        $session['User'] = $userIsConfirmedOnThisMachine
        $session['UserId'] = $userIsConfirmedOnThisMachine.UserId


        $secondaryApiKey = "$($confirmCookie.Values['Key'])"                                                                                   

        $partitionKey = $userIsConfirmedOnThisMachine.PartitionKey
        $rowKey = $userIsConfirmedOnThisMachine.RowKey
        $tableName = $userIsConfirmedOnThisMachine.TableName
        $userIsConfirmedOnThisMachine.psobject.properties.Remove('PartitionKey')
        $userIsConfirmedOnThisMachine.psobject.properties.Remove('RowKey')
        $userIsConfirmedOnThisMachine.psobject.properties.Remove('TableName')                    
        $userIsConfirmedOnThisMachine | Add-Member -MemberType NoteProperty -Name LastLogon -Force -Value (Get-Date)
        $userIsConfirmedOnThisMachine | Add-Member -MemberType NoteProperty -Name LastLogonFrom -Force -Value "$($Request['REMOTE_ADDR'] + $request['REMOTE_HOST'])"
        $userIsConfirmedOnThisMachine |
            Update-AzureTable -TableName $tableName -RowKey $rowKey -PartitionKey $partitionKey -Value { $_} 
            
        $session['User'] = $userIsConfirmedOnThisMachine                
    }
    
    if ($session['User']) {
        $loginName = if ($session['User'].Name) {
            $session['User'].Name
        } else {
            $session['User'].UserEmail
        }
        $hide = @{}
        if ($pipeworksManifest.WebCommand.$cmdName.HideParameter) {
            $hide["HideParameter"] = $pipeworksManifest.WebCommand.$cmdName.HideParameter
        }
        Request-CommandInput -CommandMetaData (Get-Command $cmdName) -Action "$cmdName/?" @hide
    } else { @"
<div id='loginHolder_For_$cmdName'>    
    
</div>
<script>
    query = 'Module.ashx?join=true'        
    `$(function() {
        `$.ajax({
            url: query,
            cache: false,
            success: function(data){     
                `$('#loginHolder_For_$cmdName').html(data);
            } 
        })
    })
</script>
"@
    }
}


$editProfileIfLoggedIn = { 
    if ($session['User']) {
        @"
<div id='editProfileHolder'>    
    
</div>
<script>
    query = 'Module.ashx?editProfile=true'        
    `$(function() {
        `$.ajax({
            url: query,
            cache: false,
            success: function(data){     
                `$('#editProfileHolder').html(data);
            } 
        })
    })
</script>
"@
    } elseif ($request.Cookies["$($module.Name)_ConfirmationCookie"]) {
        $out = ""
        $out += Write-Link -Caption "Login as $($request.Cookies["$($module.Name)_ConfirmationCookie"]["Email"])?" -Url "Module.ashx?Login=true" |
            New-Region -LayerId "ShouldILogin_For_$cmdName" -Style @{
                'margin-left' = $MarginPercentLeftString
                'margin-right' = $MarginPercentRightString
            }
        $out
    } else { @"
<div id='loginToEditProfile'>    
    
</div>
<script>
    query = 'Module.ashx?join=true'        
    `$(function() {
        `$.ajax({
            url: query,
            success: function(data){     
                `$('#loginToEditProfile').html(data);
            } 
        })
    })
</script>
"@
    }
}
    
$header = 
    $headerContent |
        New-Region -LayerID InnerHeader -Style @{
            "margin-left" = "auto"
            "margin-right" = "auto"            
            "color" = $bgColor            
            "width" = '100%'
        } | 
        New-Region -LayerID OuterHeader -Style @{                
            "margin-left" = "5%"
            "margin-right" = "5%"
        } 


$dashboardLayers = @{}
$dashboardItemOrder = @()
$dashboardUrls = @{}
$defaultDashboardItem = ""
foreach ($dashboardTable in @($pipeworksManifest.Dashboard.Dashboards)) {
    
    

    $itemOrder = @()
    $layers = @{}
    
    # add the link to other dashboards
    
    if ($dashboardTable.Name -ne $pageName) { 
        $dashboardItemOrder += $dashboardTable.Name
        $dashboardUrls[$dashboardTable.Name] += "$($dashboardTable.Name).aspx"        
        continue 
    } else {
        $defaultDashboardItem = $dashboardTable.Name
    }
    $defaultLayerParameter = @{}
    foreach ($dashboardItemHashtable in $dashboard.Items) {
        
        $dashboardItem = New-Object PSObject -Property $dashboardItemHashtable
        
        $layerContent = 
            if ($dashboardItem.Id) {
                $storageAccount = Get-WebConfigurationSetting -Setting $pipeworksManifest.Table.StorageAccountSetting
                $storageKey = Get-WebConfigurationSetting -Setting $pipeworksManifest.Table.StorageKeySetting
                $part, $row = $dashboardItem.Value.Id -split ":"
                Show-WebObject -Table $pipeworksManifest.Table.Name -Part $part -Row $row
            } elseif ($dashboardItem.Content) {        
                $dashboardItem.Content
            } elseif ($dashboardItem.Command) {
                $cmdObj = Get-Command $dashboardItem.Command
              
                $getParameters = @{}
                if ($dashboardItem.QueryParameter) {   
                    
                    foreach ($qp in $dashboardItem.QueryParameter.GetEnumerator()) {
                        
                        if ($request[$qp.Key]) {
                            $getParameters += @{$qp.Value.Trim()=$request[$qp.Key].Trim()}
                        }
                        
                    }        
                    
                    if (-not $getParameters.Count) { continue} else {
                        $defaultLayerParameter["Default"] = $dashboardItem.DisplayName
                    }
                }
                
                if ($dashboardItem.DefaultParameter) {
                    
                    foreach ($qp in $dashboardItem.DefaultParameter.GetEnumerator()) {
                        $getParameters += @{$qp.Key=$qp.Value}                        
                    }
                }
                                
                
                if ($getParameters.Count) {
                    if ($pipeworksManifest.WebCommand.($cmdObj.Name).RequireLogin -or 
                        $dashboardItem.RequireLogin) {
                        & $showCommandOutputIfLoggedIn ($cmdObj.Name) $getParameters | Out-HTML
                    } else {            
                        & $cmdObj @getParameters | Out-HTML
                    }
                } else {
                    if ($pipeworksManifest.WebCommand.($cmdObj.Name)) {
                        if ($pipeworksManifest.WebCommand.($cmdObj.Name).RequireLogin -or 
                            $dashboardItem.RequireLogin) {
                            & $showCommandInputIfLoggedIn ($cmdObj.Name)
                        } else {            
                            Request-CommandInput -Action "$($cmdObj.Name)/" -CommandMetaData $cmdObj -DenyParameter $pipeworksManifest.WebCommand.($cmdObj.Name).HideParameter
                        }  
                    }
                    # Display an input form if the command is a web command
                }                                
               
                
                   
            } elseif ($dashboardItem.EditProfile -and $session['User']) {
                $displayName = $dashboardItem.EditProfile
                & $editProfileIfLoggedIn        
            }
            
            if ($layerContent) {
                $itemOrder += $dashboardItem.DisplayName
                $layers[$dashboardItem.DisplayName] =$layerContent
            }
    }

    $LayerOrder = 
        $ItemOrder

    
    if ($request['Show']) {
        $defaultLayerParameter['Default'] = $Request['Show']
    }

    $content = 
        New-Region -LayerID "Dashboard_$($dashboard.Name)" -Style @{
            "border"="blank"
            "width" = "100%"
            "padding" = "3px"
        } -AsLeftSidebarMenu -Order $itemOrder -Layer $layers @defaultLayerParameter

    $dashboardItemOrder += $dashboardTable.Name
    $dashboardLayers[$dashboardTable.Name] = $content
    
     
}

$style = @{    
    "margin-left" = "5%"
    "margin-right" = "5%"    
}

$browserSpecificStyle =
    if ($Request.UserAgent -clike "*IE*") {
        @{'height'='78%';"margin-top"="-5px"}
    } else {
        @{'min-height'='78%'}
    }  

$style += $browserSpecificStyle
$content = 
    New-Region -LayerID "MainDashboard" -AsPopIn -Order $dashboardItemOrder -Layer $dashboardLayers -Style $style -LayerUrl $dashboardUrls -Default $defaultDashboardItem 



$footer = 
    if ($orgInfo.Count) {
        "<p text-align='center' style='background-color:$edgeColor'>
    <span itemprop='Address'>$($orgInfo.Address)</span> | <span itemprop='telephone'>$($orgInfo.telephone)</span><br><span style='font-size:xx-small'><span itemprop='name'>$($orgInfo.Name)</span> | Copyright $((Get-Date).Year)
    </span></p>"
    } else {
        " "
    }

$footer = $footer| 
    New-Region -LayerID Footer -ItemType http://schema.org/Organization -CssClass ui-widget-content, ui-corner-all -Style @{
        "margin-left" = "5%"
        "margin-right" = "5%"                  
        "Color" = $dashboardColor
        "padding" = "10px"          
        "text-align" = "center"
    }
    
    
$lowerLoginButton = if ($pipeworksManifest.UserTable.Name) {
    Write-Link -Url "Module.ashx?Login=true" -Caption "<span class='ui-icon ui-icon-locked'> Login </span>" |
        New-Region -LayerID LoginButtonLayer -Style @{
            Position = 'Absolute'
            Right = '5px'
            Bottom = '5px'
        }
} else {
    ""
}    

$lowerLoginButton, $header, $content | 
    New-WebPage -NoCache -Css @{
        Body = @{
            "background-color" = $bgColor
            "font" = $fontName
        }
    } -Title "$pageName"
            
        } 
        if (-not $outputPages.Count) {
            $outputPages["default.pspage"] = "<| $pageScript  |>"
        }
        $outputPages["$pageName.pspage"] = "<| $pageScript  |>"
    }        
        
        
        
                    
          
        
        $outputPages                         
        
        
                                           
    }        
} 
 

