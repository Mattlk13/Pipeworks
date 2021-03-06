function Wait-EC2
{    
    <#
    .Synopsis
        Waits for an EC2 instance to become available
    .Description
        Waits for an EC2 instance password to become available
    .Example
        Add-EC2 -ImageId ami-078b536e -PassThru  |      # Creates a server 2008 R2 image 
            Wait-EC2 |                                  # Waits for the password to become ready, one sign the image is good to go     
                                                        # Enables remoting for serveral protocols
            Enable-EC2Remoting -PowerShellCredSSP -Ssh -Echo -Http -Https
                                                        

        $ec2 | 
            Invoke-EC2 -ScriptBlock { "Hello from $env:ComputerName" } 
        # Pull the EC2 credential to the instance.  
        # I don't ever even really know the credential of the box     
        $ec2Cred = $ec2 |
            Get-EC2InstancePassword -AsCredential

        # Hello, World
        Invoke-Command -ComputerName $ec2.PublicDnsName -Credential $ec2Cred -ScriptBlock {
            "hello, world"
        }
    .Link
        Add-EC2
    #>
    param(
    # The EC2 Instance ID
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
    [string]
    $InstanceId
    )
    
    process {
        $oldWarningPreference = $WarningPreference 
        $WarningPreference = 'SilentlyContinue'
        $since = Get-Date
        $perc = 0 
        $progId = Get-Random
        do {                        
            $perc += Get-Random -Maximum 7
            if ($perc -gt 100) { $perc = 0 }
            Write-Progress "Waiting for EC2 Instance $instanceId" "Since $since" -PercentComplete $perc -Id $progId 
            $canGetPassword = 
                Get-EC2InstancePassword -EC2 $instanceId
            
            if ($canGetPassword) {
                Write-Progress "EC2 Instance $instanceId" "Ready" -Completed -Id $progId 
                return Get-EC2 -InstanceId $InstanceId
            }        
        } while (1)
        $WarningPreference = $oldWarningPreference 
    }
} 
 
