function Reset-EC2
{
    <#
    .Synopsis
        Reboots EC2 instances
    .Description
        Reboots Amazon Web Services EC2 instances 
    .Example
        # Reset all instances
        Get-EC2 |
            Reset-EC2
    .Link
        Get-EC2
    #>
    [CmdletBinding(SupportsShouldProcess='true', ConfirmImpact='High')]
    [OutputType([Nullable])]
    param(
    # The ID of the instance that will be rebooted. 
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
    [string]
    $InstanceId
    )
    
    process {
        #region Terminate the instance
        $toTerminate = (New-Object Amazon.EC2.Model.RebootInstancesRequest).WithInstanceId($InstanceId)
        if ($psCmdlet.ShouldProcess($InstanceId)) {
            $AwsConnections.EC2.RebootInstances($toTerminate)  | Out-Null
        }
        #endregion Terminate the instance
    }
} 
 
 
