Powershell function/tool to set/update Azure ACL of a given VM Endpoint
=======================================================================

            

One of the nice new features (2014) introduced is Access Control Lists for Azure VM Endpoints. I think of it as a virtual firewall for each Azure VM. This is a really nice feature because it can be managed and automated from Powershell. It's also scoped
 to a single VM which is another nice design feature to minimize possible effects in case of error/mis-configuration. 


This script has a function which acts as a tool to set/update ACL for a VM Endpoint.
[See this link for more details.](http://superwidgets.wordpress.com/2014/12/19/powershell-functiontool-to-setupdate-azure-vm-endpoint-access-control-list/)


It uses an input object that has (at least) 2 properties: IP and Date. The Date is used to populate the Description of the rule in the ACL. 


[The Get-IPsFromLogs function/tool](http://superwidgets.wordpress.com/2014/12/18/powershell-functiontool-to-get-ips-from-httperr-logs-based-on-frequency/)parses HTTPErr logs and outputs such object.


To use it, download it, unblock the file, adjust PS execution policy as needed, run it, then use it in a controller script. 


To see useage:


 

Powershell displays the built-in help:

![Image](https://github.com/azureautomation/powershell-functiontool-to-setupdate-azure-acl-of-a-given-vm-endpoint/raw/master/get-ipsfromlogs9.jpg)

        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
