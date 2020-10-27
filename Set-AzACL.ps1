#Requires -Version 4
#Requires -Modules Azure


function Set-AzACL {
<# 
 .SYNOPSIS
  Function/tool to set/update Azure Access Control List for a given Azure VM Endpoint

 .DESCRIPTION
  Function/tool to set/update Azure Access Control List for a given Azure VM Endpoint

 .PARAMETER IPList
  One or more PSObjects that have 'IP' and 'Date' properties.
  This object is the output object from Get-IPsFromLogs function/tool
  http://superwidgets.wordpress.com/2014/12/18/powershell-functiontool-to-get-ips-from-httperr-logs-based-on-frequency/
  
 .PARAMETER SubscriptionName
  Name of the Azure Subscription where the Azure VM resides.
  To see your Azure subscriptions use the cmdlet:
      (Get-AzureSubscription).SubscriptionName

 .PARAMETER VMName
  Name of the Azure VM 
  To see your Azure VMs use the cmdlet:
      (Get-AzureVM).Name

 .PARAMETER EndPointName
  Name of the Azure VM EndPoint
  To see your Azure VM Endpoints for a given VM use the cmdlet:
      $VMName = "MyAzureVM"
      (Get-AzureVM | where { $_.Name -eq $VMName } | Get-AzureEndpoint).Name

 .EXAMPLE
  Set-AzACL -IPList (Get-IPsFromLogs -Logs c:\temp\log1.txt) -SubscriptionName "MyAzureSubscription" -VMName "MyAzureVM" -EndpointName "Web"
  In this example, the function/tool Get-IPsFromLogs compiles a list of IPs that appeared more than 500 times
  in the log file c:\temp\log1.txt, and the function/tool Set-AzACL adds that list to the Web endpoint of MyAzureVM
 
 .INPUTS
  The function requires a PSObject that has 2 properties: IP, Date
  The Date is used to populate the rule description of the ACL
  This object is the output object from Get-IPsFromLogs function/tool
  http://superwidgets.wordpress.com/2014/12/18/powershell-functiontool-to-get-ips-from-httperr-logs-based-on-frequency/

 .OUTPUTS
  None

 .LINK
  https://superwidgets.wordpress.com/category/powershell/

 .NOTES
  Function by Sam Boutros
  v1.0 - 12/19/2014

#>

    [CmdletBinding(ConfirmImpact='High')] 
    Param(
        [Parameter(Mandatory=$true,
                   Position=0)]
            [System.Object[]]$IPList,
        [Parameter(Mandatory=$true,
                   Position=1)]
            [String]$SubscriptionName,
        [Parameter(Mandatory=$true,
                   Position=2)]
            [String]$VMName,
        [Parameter(Mandatory=$true,
                   Position=3)]
            [String]$EndPointName
    )


    Begin {
        $Props = ($IPList | Get-Member -MemberType NoteProperty).Name
        if ($Props -notcontains "Date" -or $Props -notcontains "IP") {
            throw "Incorrect object received. Expecting PSObject containing 'Date' and 'IP' properties."
        }
        try { 
            Select-AzureSubscription -SubscriptionName $SubscriptionName -ErrorAction Stop 
        } catch { 
            throw "unable to select Azure subscription '$SubscriptionName', check correct spelling.. " 
        }
        try { 
            $ServiceName = (Get-AzureVM -ErrorAction Stop | where { $_.Name -eq $VMName }).ServiceName 
        } catch { 
            throw "unable to get Azure VM '$VMName', check correct spelling, or run Add-AzureAccount to enter Azure credentials.. " 
        }
        $objVM = Get-AzureVM -Name $VMName -ServiceName $ServiceName
    }

    Process {
        # Get current ACL
        $ACL = Get-AzureAclConfig -EndpointName $EndPointName -VM $objVM
        Write-Verbose "Current ACL:" 
        Write-Verbose  ($ACL | FT -Auto | Out-String) 


        # Add/Update rules from $IPList
        Write-Verbose "Updating Access Control List for '$EndPointName' endpoint for VM '$VMName'"
        foreach ($IP in $IPList) {
            $ExistingRule = $ACL | where { $_.RemoteSubnet -match "$($IP.IP)/32"} 
            if ($ExistingRule) { # Update Description
                Set-AzureAclConfig -SetRule -Action Deny -RuleId $ExistingRule.RuleID -RemoteSubnet $ExistingRule.RemoteSubnet -Description $IP.Date -ACL $ACL | Out-Null
            } else { # Add new rule
                Set-AzureAclConfig -AddRule Deny -RemoteSubnet "$($IP.IP)/32" -Description $IP.Date -ACL $ACL | Out-Null
            }
        } 


        # Reset rule order
        $i=0
        $ACL | Sort Description -Descending | % {
            Set-AzureAclConfig -SetRule -RuleId $_.RuleID -Action Deny -RemoteSubnet $_.RemoteSubnet -Description $_.Description -Order $i -ACL $ACL | Out-Null
            $i++
        }
        Write-Verbose ($ACL | Sort Order | FT -Auto | Out-String)


        # check for duplicates
        if ($ACL.RemoteSubnet.Count -eq ($ACL.RemoteSubnet | Select -Unique).Count) {
            Write-Verbose "Verified no duplicate rules. Rule count: '$($ACL.RemoteSubnet.Count)'"
        } else {
            throw "Found '$($ACL.RemoteSubnet.Count - ($ACL.RemoteSubnet | Select -Unique).Count)' duplicate rules."
        }


        Write-Verbose "Saving updated ACL to EndPoint '$EndPointName' for VM '$VMName'"
        $Duration = Measure-Command {
            $Result = Set-AzureEndpoint –ACL $ACL –Name $EndPointName -VM $objVM | Update-AzureVM 
        }
        Write-Verbose "  done in $($Duration.Minutes):$($Duration.Seconds) mm:ss"
        Write-Verbose ($Result | FT -AutoSize | Out-String)
    } # Process


} # function