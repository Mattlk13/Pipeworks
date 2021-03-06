function Remove-EC2
{
    <#
    .Synopsis
        Removes EC2 instances
    .Description
        Removes EC2 instances from Amazon Web Services
    .Example
        Get-EC2 | 
            Remove-EC2
    .Link
        Get-EC2
    .Link
        Add-EC2
    #>
    [CmdletBinding(SupportsShouldProcess='true', ConfirmImpact='High')]
    [OutputType([Nullable])]
    param(
    # The ec2 Instance ID
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
    [string]
    $InstanceId
    )
    
    process {
        #region Terminate the Instance
        $toTerminate = (New-Object Amazon.EC2.Model.TerminateInstancesRequest).WithInstanceId($InstanceId)
        if ($psCmdlet.ShouldProcess($InstanceId)) {
            $AwsConnections.EC2.TerminateInstances($toTerminate)  | Out-Null
        }
        #endregion Terminate the Instance
    }
} 
