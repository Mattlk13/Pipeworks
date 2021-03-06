function Get-EC2SecurityGroup
{
    <#
    .Synopsis
        Lists EC2 security groups
    .Description
        Lists Amazon Web Services EC2 security groups.  Security Groups define remote access to a machine.            
    .Example
        Get-EC2SecurityGroup
    .Link
        Remove-EC2SecurityGroup
    
    #>
    [OutputType([PSObject])]
    param()
    
    process {
        $AwsConnections.EC2.DescribeSecurityGroups((New-Object Amazon.EC2.Model.DescribeSecurityGroupsRequest)).DescribeSecurityGroupsResult.SecurityGroup
    }
}