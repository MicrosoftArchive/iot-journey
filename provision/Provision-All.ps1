[CmdletBinding()]
Param
(
	[ValidateNotNullOrEmpty()]
	[Parameter(Mandatory = $True)]
	[string]$SubscriptionName,

	[ValidateNotNullOrEmpty()]
	[Parameter (Mandatory = $True)]
    [ValidatePattern("^[A-Za-z][-A-Za-z0-9]*[A-Za-z0-9]$")] # needs to start with letter or number, and contain only letters, numbers, and hyphens.
	[String]$ServiceBusNamespace,                                   
    
	[ValidateNotNullOrEmpty()]
	[Parameter (Mandatory = $True)]
    # dont use this: [ValidatePattern("^[a-z0-9]*$")]  # don't use this, powershell script is case insensitive, uppercase letter still pass as valid 
    [ValidateScript({
      # we need to use cmathch which is case sensitive, don't use match
      If ($_ -cmatch "^[a-z0-9]*$") {                         # needs contain only lower case letters and numbers.
        $True
      }else {
        Throw "`n---Storage account name can only contain lowercase letters and numbers!---"
      }
    })]
	[String]$StorageAccountName,    

	[ValidateNotNullOrEmpty()]
	[Parameter (Mandatory = $True)]
	[String]$StreamAnalyticsJobName = "fabrikamstreamjob01",

	[ValidateNotNullOrEmpty()]
	[Parameter (Mandatory = $True)]
	[string]$SqlServerName,

	[ValidateNotNullOrEmpty()]
	[Parameter (Mandatory = $False)]
	[string]$SqlDatabaseName = "fabrikamdb01",

	[ValidateNotNullOrEmpty()]
	[Parameter (Mandatory = $False)]
	[string]$SqlDatabaseUser="fabrikamdbuser01",

	[ValidateNotNullOrEmpty()]
	[Parameter (Mandatory = $True)]
	[string]$SqlDatabasePassword,             

	[ValidateNotNullOrEmpty()]
    [Parameter (Mandatory = $False)]
	[String]$ResourceGroupPrefix = "fabrikam",
    
	[ValidateNotNullOrEmpty()]
    [Parameter (Mandatory = $False)]
    [ValidatePattern("^[A-Za-z0-9]$|^[A-Za-z0-9][\w-\.\/]*[A-Za-z0-9]$")] # needs to start with letter or number, and contain only letters, numbers, periods, hyphens, and underscores.
	[String]$EventHubName = "eventhub01",                  

	[ValidateNotNullOrEmpty()]
	[Parameter (Mandatory = $False)]
    [ValidatePattern("^[A-Za-z][-A-Za-z0-9]*[A-Za-z0-9]$")]      # needs to start with letter or number, and contain only letters, numbers, and hyphens.
	[String]$ConsumerGroupNameSQL= "consumergroupSQL01", 

	[ValidateNotNullOrEmpty()]
	[Parameter (Mandatory = $False)]
    [ValidatePattern("^[A-Za-z][-A-Za-z0-9]*[A-Za-z0-9]$")]      # needs to start with letter or number, and contain only letters, numbers, and hyphens.
	[String]$ConsumerGroupNameCold= "consumergroupCold01", 

	[ValidateNotNullOrEmpty()]
    [Parameter (Mandatory = $False)]
	[String]$EventHubSharedAccessPolicyName = "ManagePolicy",
    
	[ValidateNotNullOrEmpty()]               
    [Parameter (Mandatory = $False)]
    [ValidatePattern("^[A-Za-z][-A-Za-z0-9]*[A-Za-z0-9]$")] #needs to start with letter or number, and contain only letters, numbers, and hyphens.
	[String]$ContainerName = "container01",

	[ValidateNotNullOrEmpty()]
    [Parameter (Mandatory = $False)]
    [ValidatePattern("^[A-Za-z][-A-Za-z0-9]*[A-Za-z0-9]$")] #needs to start with letter or number, and contain only letters, numbers, and hyphens.
	[string]$HDInsightStorageContainerName = "iot-hdicontainer01",
    
	[ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $True)]
    [ValidatePattern("^[A-Za-z][-A-Za-z0-9]*[A-Za-z0-9]$")] #needs to start with letter or number, and contain only letters, numbers, and hyphens.
	[String]$HDInsightClusterName,
    
    [Parameter (Mandatory = $False)]
	[int]$HDInsightClusterNodes = 2,

	[ValidateNotNullOrEmpty()]
    [Parameter (Mandatory = $False)]
	[String]$Location = "Central US"
)

function CreateOrUpdateSettingsFile
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)][string]$ServiceBusNamespace,
        [Parameter(Mandatory=$True)][string]$EventHubName,
        [Parameter(Mandatory=$True)][string]$EventHubSasKeyName,
        [Parameter(Mandatory=$True)][string]$EventHubPrimaryKey,
        [Parameter(Mandatory=$True)][string]$ColdStorageCheckpointStorageAccount,
        [Parameter(Mandatory=$True)][string]$ColdStorageEventHubConnectionString,
        [Parameter(Mandatory=$True)][string]$ColdStorageEventHubName,
        [Parameter(Mandatory=$True)][string]$ColdstorageBlobWriterStorageAccount,
        [Parameter(Mandatory=$True)][string]$WarmstorageEventHubConnectionString,
        [Parameter(Mandatory=$True)][string]$WarmstorageEventHubName,
        [Parameter(Mandatory=$True)][string]$WarmstorageCheckpointStorageAccount
    )
    PROCESS
    {
        $MySettingsTemplateFilePath = (Split-Path $PSScriptRoot -Parent) + "\src\RunFromConsole\mysettings-template.config"

        if(!(Test-Path $MySettingsTemplateFilePath))
        {
            throw "Cannot find 'mysettings-template.config' file in [$MySettingsTemplateFilePath]."
        }

        $MySettingsFilePath = (Split-Path $PSScriptRoot -Parent) + "\src\RunFromConsole\mysettings.config"

        Copy-Item $MySettingsTemplateFilePath $MySettingsFilePath

        $xml = [xml](Get-Content $MySettingsFilePath)


        $node = $xml.appSettings.add | where {$_.key -eq 'Simulator.EventHubNamespace'}
        $node.Value = $ServiceBusNamespace

        $node = $xml.appSettings.add | where {$_.key -eq 'Simulator.EventHubName'}
        $node.Value = $EventHubName

        $node = $xml.appSettings.add | where {$_.key -eq 'Simulator.EventHubSasKeyName'}
        $node.Value = $EventHubSasKeyName

        $node = $xml.appSettings.add | where {$_.key -eq 'Simulator.EventHubPrimaryKey'}
        $node.Value = $EventHubPrimaryKey

#        $node = $xml.appSettings.add | where {$_.key -eq 'Simulator.EventHubConnectionString'}
#        $node.Value = $SimulatorEventHubConnectionString

#        $node = $xml.appSettings.add | where {$_.key -eq 'Simulator.EventHubPath'}
#        $node.Value = $SimulatorEventHubPath

        
        $node = $xml.appSettings.add | where {$_.key -eq 'Coldstorage.CheckpointStorageAccount'}
        $node.Value = $ColdStorageCheckpointStorageAccount

        $node = $xml.appSettings.add | where {$_.key -eq 'Coldstorage.EventHubConnectionString'}
        $node.Value = $ColdStorageEventHubConnectionString

        $node = $xml.appSettings.add | where {$_.key -eq 'Coldstorage.EventHubName'}
        $node.Value = $ColdStorageEventHubName

        $node = $xml.appSettings.add | where {$_.key -eq 'Coldstorage.BlobWriterStorageAccount'}
        $node.Value = $ColdstorageBlobWriterStorageAccount


        $node = $xml.appSettings.add | where {$_.key -eq 'Warmstorage.EventHubConnectionString'}
        $node.Value = $WarmstorageEventHubConnectionString

        $node = $xml.appSettings.add | where {$_.key -eq 'Warmstorage.EventHubName'}
        $node.Value = $WarmstorageEventHubName

        $node = $xml.appSettings.add | where {$_.key -eq 'Warmstorage.CheckpointStorageAccount'}
        $node.Value = $WarmstorageCheckpointStorageAccount

        Write-Verbose "Updating [$MySettingsFilePath] configuration file."

        $xml.Save($MySettingsFilePath)
    }
}

############################
##
## Script start up
##
############################

.\Init.ps1

# Make the script stop on error
# Set the output level to verbose and make the script stop on error 

$VerbosePreference = "SilentlyContinue" 
Switch-AzureMode -Name AzureServiceManagement
$VerbosePreference = "Continue" 

$ErrorActionPreference = "Stop" 

Assert-AzureModuleIsInstalled

Add-AzureAccount

$VerbosePreference = "SilentlyContinue"

.\Provision-SQLDatabase.ps1 -SubscriptionName $SubscriptionName `
							-ServerName $SqlServerName `
							-ResourceGroupPrefix $ResourceGroupPrefix `
							-ServerAdminLogin $SqlDatabaseUser `
							-ServerAdminPassword $SqlDatabasePassword `
							-DatabaseName $SqlDatabaseName
 
$EventHubCreationInfo = .\Provision-EventHub.ps1 -SubscriptionName $SubscriptionName `
                         -Location $Location `
                         -ServiceBusNamespace $ServiceBusNamespace `
                         -EventHubName $EventHubName `
                         -ConsumerGroupNameSQL $ConsumerGroupNameSQL `
                         -ConsumerGroupNameCold $ConsumerGroupNameCold `
                         -EventHubSharedAccessPolicyName $EventHubSharedAccessPolicyName 

$StorageAccountCreationInfo = .\Provision-StorageAccount.ps1 -SubscriptionName $SubscriptionName `
                               -Location $Location `
                               -StorageAccountName $StorageAccountName `
                               -ContainerName $ContainerName

.\Provision-StreamAnalyticsJob.ps1 -SubscriptionName $SubscriptionName `
                                   -StreamAnalyticsJobName $StreamAnalyticsJobName `
                                   -Location $Location `
                                   -ResourceGroupPrefix $ResourceGroupPrefix `
                                   -ServiceBusNamespace $ServiceBusNamespace `
                                   -EventHubName $EventHubName `
			                       -ConsumerGroupNameSQL $ConsumerGroupNameSQL `
						           -ConsumerGroupNameCold $ConsumerGroupNameCold `
                                   -EventHubSharedAccessPolicyName $EventHubSharedAccessPolicyName `
                                   -StorageAccountName $StorageAccountName `
                                   -ContainerName $ContainerName `
                                   -SqlDatabaseName $SqlDatabaseName `
                                   -SqlDatabasePassword $SqlDatabasePassword `
                                   -SqlServerName $SqlServerName `
                                   -SqlDatabaseUser $SqlDatabaseUser

.\Provision-HDInsight.ps1 -SubscriptionName $SubscriptionName `
                          -StorageAccountName $StorageAccountName `
                          -StorageContainerName $HDInsightStorageContainerName `
                          -ClusterName $HDInsightClusterName `
                          -ClusterNodes $HDInsightClusterNodes `
                          -Location $Location


$EventHubConnectionString = $EventHubCreationInfo.EventHubConnectionString + ";TransportType=Amqp"

$StorageAccountConnectionString = "DefaultEndpointsProtocol=https;AccountName={0};AccountKey={1}" -f $StorageAccountCreationInfo.AccountName, $StorageAccountCreationInfo.AccountKey

CreateOrUpdateSettingsFile  `
                           -ServiceBusNamespace $ServiceBusNamespace `
                           -EventHubName $EventHubName `
                           -EventHubSasKeyName $EventHubCreationInfo.EventHubRuleName `
                           -EventHubPrimaryKey $EventHubCreationInfo.EventHubRuleKey `
                           -ColdStorageCheckpointStorageAccount  $StorageAccountConnectionString `
                           -ColdStorageEventHubConnectionString $EventHubConnectionString `
                           -ColdStorageEventHubName $EventHubCreationInfo.EventHubName `
                           -ColdstorageBlobWriterStorageAccount $StorageAccountConnectionString `
                           -WarmstorageEventHubConnectionString $EventHubConnectionString `
                           -WarmstorageEventHubName $EventHubCreationInfo.EventHubName `
                           -WarmstorageCheckpointStorageAccount $StorageAccountConnectionString


$VerbosePreference = "Continue" 
Write-Verbose "Provision-All completed"