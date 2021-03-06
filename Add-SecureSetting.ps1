function Add-SecureSetting
{
    <#
    .Synopsis
        Adds an encrypted setting to the registry
    .Description
        Stores secured user settings in the registry
    .Example
        Add-SecureSetting AStringSetting 'A String'
    .Example
        Add-SecureSetting AHashtableSetting @{a='b';c='d'}
    .Example
        Add-SecureSetting ACredentialSetting (Get-Credential)
    .Example
        Add-SecureSetting ASecureStringSetting (Read-Host "Is It Secret?" -AsSecureString)
    .Link
        https://www.youtube.com/watch?v=0haXavQU_nY
    .Link
        Get-SecureSetting
    .Link
        ConvertTo-SecureString
    .Link
        ConvertFrom-SecureString
    #>
    [CmdletBinding(DefaultParameterSetName='System.Security.SecureString')]
    [OutputType('SecureSetting')]
    param(   
    # The name of the secure setting
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
    [String]
    $Name,
    
    # A string value to store.  This will be converted into a secure string and stored in the registry. 
    [Parameter(Mandatory=$true,Position=1,ParameterSetName='String',ValueFromPipelineByPropertyName=$true)]
    [string]
    $String,
    
    # An existing secure string to the registry.
    [Parameter(Mandatory=$true,Position=1,ParameterSetName='System.Security.SecureString',ValueFromPipelineByPropertyName=$true)]
    [Security.SecureString]
    $SecureString,
    
    # A table of values.  The table will be converted to a string, and this string will be stored in the registry.
    [Parameter(Mandatory=$true,Position=1,ParameterSetName='Hashtable',ValueFromPipelineByPropertyName=$true)]
    [Hashtable]
    $Hashtable,
    
    # A credential.  The credential will stored in the registry as a pair of secured values.
    [Parameter(Mandatory=$true,Position=1,ParameterSetName='System.Management.Automation.PSCredential',ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.PSCredential]
    $Credential
    )
    
    process {       
        #region Create Registry Location If It Doesn't Exist 
        $registryPath = "HKCU:\Software\Start-Automating\$($myInvocation.MyCommand.ScriptBlock.Module.Name)"
        $fullRegistryPath = "$registryPath\$($psCmdlet.ParameterSetName)"
        if (-not (Test-Path $fullRegistryPath)) {
            $null = New-Item $fullRegistryPath  -Force
        }   
        #endregion Create Registry Location If It Doesn't Exist
        
        
        
        if ($psCmdlet.ParameterSetName -eq 'String') {
            #region Encrypt and Store Strings
            $newSecureString = $String | 
                ConvertTo-SecureString -AsPlainText -Force | 
                ConvertFrom-SecureString
                
            Set-ItemProperty $fullRegistryPath -Name $Name -Value $newSecureString
            #endregion Encrypt and Store Strings
        } elseif ($psCmdlet.ParameterSetName -eq 'Hashtable') {
            #region Embed And Store Hashtables
            $newSecureString = Write-PowerShellHashtable -InputObject $hashtable | 
                ConvertTo-SecureString -AsPlainText -Force | 
                ConvertFrom-SecureString
                                
            Set-ItemProperty $fullRegistryPath -Name $Name -Value $newSecureString
            #endregion Embed And Store Hashtables
        } elseif ($psCmdlet.ParameterSetName -eq 'System.Security.SecureString') {
            #region Store Secure Strings
            $newSecureString = $secureString | 
                ConvertFrom-SecureString
                
            Set-ItemProperty $fullRegistryPath -Name $Name -Value $newSecureString
            #endregion Store Secure Strings
        } elseif ($psCmdlet.ParameterSetName -eq 'System.Management.Automation.PSCredential') {
            #region Store credential pairs
            $secureUserName = $Credential.UserName | 
                ConvertTo-SecureString -AsPlainText -Force | 
                ConvertFrom-SecureString
            $securePassword = $Credential.Password | 
                ConvertFrom-SecureString
                            
            Set-ItemProperty $fullRegistryPath -Name "${Name}_Username" -Value $secureUserName
            Set-ItemProperty $fullRegistryPath -Name "${Name}_Password" -Value $securePassword
            #endregion Store credential pairs
        }                    
    }

} 
