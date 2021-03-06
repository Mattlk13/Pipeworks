function Remove-EC2SecurityGroup
{
    <#
    .Synopsis
        Removes an EC2 Security Group
    .Description
        Removes a Security Group from EC2
    .Example
        Get-EC2SecurityGroup |
            Remove-EC2SecurityGroup
    .Link
        Get-EC2SecurityGroup
    #>
    [CmdletBinding(SupportsShouldProcess='true', ConfirmImpact='High')]
    param(
    # The name of the security group
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
    [string]
    $GroupName    
    )
    
    process {
        $toTerminate = (New-Object Amazon.EC2.Model.DeleteSecurityGroupRequest).WithGroupName($GroupName)
        if ($psCmdlet.ShouldProcess($GroupName)) {
            $AwsConnections.EC2.DeleteSecurityGroup($toTerminate)  | Out-Null
        }
    }
} 
 
