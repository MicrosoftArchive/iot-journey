[CmdletBinding()]
Param
(
	[ValidateNotNullOrEmpty()][Parameter (Mandatory = $True)][string]$SubscriptionName,
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $True)][String]$ApplicationName,
	[ValidateNotNullOrEmpty()][Parameter (Mandatory = $True)][bool]$AddAccount,
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$StorageAccountName =$ApplicationName,
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$ServiceBusNamespace = $ApplicationName,
	[ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$EventHubName = "eventhub-iot",                  
	[ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$ConsumerGroupName  = "cg-elasticsearch", 
	[ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$EventHubSharedAccessPolicyName = "ManagePolicy",
	[ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$Location = "Central US"
)
PROCESS
{
    .\Init.ps1

    Load-Module -ModuleName Validation -ModuleLocation .\modules

    # Validate input.
    Test-OnlyLettersNumbersAndHyphens "ConsumerGroupName" $ConsumerGroupName
    Test-OnlyLettersNumbersHyphensPeriodsAndUnderscores "EventHubName" $EventHubName
    Test-OnlyLettersNumbersAndHyphens "ServiceBusNamespace" $ServiceBusNamespace

    # Load modules.
    Load-Module -ModuleName Config -ModuleLocation .\modules
    Load-Module -ModuleName Utility -ModuleLocation .\modules
    Load-Module -ModuleName AzureARM -ModuleLocation .\modules
    Load-Module -ModuleName AzureStorage -ModuleLocation .\modules
    Load-Module -ModuleName AzureServiceBus -ModuleLocation .\modules


    if($AddAccount)
    {
        Add-AzureAccount
    }

    $StorageAccountInfo = Provision-StorageAccount -StorageAccountName $StorageAccountName `
                                                   -Location $Location

    $EventHubInfo = Provision-EventHub -SubscriptionName $SubscriptionName `
                                    -ServiceBusNamespace $ServiceBusNamespace `
                                    -EventHubName $EventHubName `
                                    -ConsumerGroupName $ConsumerGroupName `
                                    -EventHubSharedAccessPolicyName $EventHubSharedAccessPolicyName `
                                    -Location $Location `
                                    -PartitionCount 16 `
                                    -MessageRetentionInDays 7 `
    # Update settings

    $simulatorSettings = @{
        'Simulator.EventHubNamespace'= $EventHubInfo.EventHubNamespace;
        'Simulator.EventHubName' = $EventHubInfo.EventHubName;
        'Simulator.EventHubSasKeyName' = $EventHubInfo.EventHubSasKeyName;
        'Simulator.EventHubPrimaryKey' = $EventHubInfo.EventHubPrimaryKey;
        'Simulator.EventHubTokenLifetimeDays' = ($EventHubInfo.EventHubTokenLifetimeDays -as [string]);
    }

    Write-SettingsFile -configurationTemplateFile (Join-Path $PSScriptRoot -ChildPath "..\src\Simulator\ScenarioSimulator.ConsoleHost.Template.config") `
                       -configurationFile (Join-Path $PSScriptRoot -ChildPath "..\src\Simulator\ScenarioSimulator.ConsoleHost.config") `
                       -appSettings $simulatorSettings
        
    $EventHubConnectionString = $EventHubInfo.ConnectionStringFix + ";TransportType=Amqp"
    $StorageAccountConnectionString = "DefaultEndpointsProtocol=https;AccountName={0};AccountKey={1}" -f $StorageAccountInfo.AccountName, $StorageAccountInfo.AccountKey

    $settings = @{
        'Warmstorage.CheckpointStorageAccount' = $StorageAccountConnectionString;
        'Warmstorage.EventHubConnectionString' = $EventHubConnectionString;
        'Warmstorage.EventHubName' = $EventHubInfo.EventHubName;
        'Warmstorage.ConsumerGroupName' = $ConsumerGroupName;
    }

    Write-SettingsFile -configurationTemplateFile (Join-Path $PSScriptRoot -ChildPath "..\src\AdhocExploration\DotnetEventProcessor\WarmStorage.EventProcessor.ConsoleHost.Template.config") `
                       -configurationFile (Join-Path $PSScriptRoot -ChildPath "..\src\AdhocExploration\DotnetEventProcessor\WarmStorage.EventProcessor.ConsoleHost.config") `
                       -appSettings $settings


    Write-Warning "This scenario requires Elastich Search installed to run which is not provisioned with this script."
    Write-Output "Provision Finished OK"
}
