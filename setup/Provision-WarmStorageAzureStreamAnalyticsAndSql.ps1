# Copyright (c) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

<#
.SYNOPSIS
  

.DESCRIPTION
  

.PARAMETER SubscriptionName
    Name of the Azure Subscription.

.PARAMETER ApplicationName
    Name of the Application.

.PARAMETER StorageAccountName
    Name of the storage account name.
     
.PARAMETER ContainerName
    Name of the container use to store output from the Stream Analytics job.

.PARAMETER EventHubName
    Name of the EventHub that will receive events from the simulator.

.PARAMETER EventHubSharedAccessPolicyName
    Shared Access Policy

.PARAMETER Location
    Location

.PARAMETER ResourceGroupPrefix
    Prefix that will be combined with Location to produce the ResourceGroupName

.PARAMETER ServiceBusNamespace
    Name of the Namespace tha will contain the EventHub instance.

.PARAMETER ConsumerGroupName
    Stream Analytics consumer group for sql server.

.PARAMETER SqlDatabaseName
    Name of the database used to store data from Stream Analytics.

.PARAMETER SqlServerAdminLogin
    Admin login of the SQL Server.

.PARAMETER SqlServerAdminPassword
    Admin password of the SQL Server.

.PARAMETER SqlServerName
    Sql Server name.

.PARAMETER StreamAnalyticsBlobsJobName
    Name of the Stream Analytics Job name used to output to blob storage.
    
.PARAMETER StreamAnalyticsSqlJobName
    Name of the Stream Analytics Job name used to output to Sql.
     
.EXAMPLE
  .\Provision-ColdStorageAzureStreamAnalytics.ps1 -SubscriptionName [YourAzureSubscriptionName] -ApplicationName [YourApplicationName] -SqlServerAdminPassword [YourPassword] -Verbose
#>
[CmdletBinding()]
Param
(
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $True)][string]$SubscriptionName,
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $True)][String]$ApplicationName,
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][bool]$AddAccount = $True,
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$StorageAccountName =$ApplicationName,
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$ContainerName = "warm-asa",
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$EventHubName = "eventhub-iot",
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$EventHubSharedAccessPolicyName = "ManagePolicy",
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$Location = "Central US",
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$ResourceGroupPrefix = $ApplicationName,
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$ServiceBusNamespace = $ApplicationName,
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$ConsumerGroupName = "cg-sql-asa",
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$SqlDatabaseName = "fabrikam",
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$SqlServerAdminLogin = "dbuser",
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $True)][String]$SqlServerAdminPassword,
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$SqlServerName = $ApplicationName,
    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][String]$StreamAnalyticsSqlJobName = $ApplicationName+"ToSQL",

    [ValidateNotNullOrEmpty()][Parameter (Mandatory = $False)][ValidateScript({ Test-FileName "JobDefinitionPath" $_})]
    [String]$JobDefinitionPath = "..\src\LongTermStorage\AzureStreamAnalytics\StreamAnalyticsJobDefinitionSQL.json"
)
PROCESS
{
    .\Init.ps1

    Load-Module -ModuleName Validation -ModuleLocation .\modules

    # Validate input.
    Test-OnlyLettersAndNumbers "StorageAccountName" $StorageAccountName
    Test-OnlyLettersNumbersAndHyphens "ConsumerGroupName" $ConsumerGroupName
    Test-OnlyLettersNumbersHyphensPeriodsAndUnderscores "EventHubName" $EventHubName
    Test-OnlyLettersNumbersAndHyphens "ServiceBusNamespace" $ServiceBusNamespace
    Test-OnlyLettersNumbersAndHyphens "ContainerName" $ContainerName

    # Load modules.
    Load-Module -ModuleName Config -ModuleLocation .\modules
    Load-Module -ModuleName Utility -ModuleLocation .\modules
    Load-Module -ModuleName AzureARM -ModuleLocation .\modules
    Load-Module -ModuleName AzureStorage -ModuleLocation .\modules
    Load-Module -ModuleName AzureServiceBus -ModuleLocation .\modules
    Load-Module -ModuleName AzureStreamAnalytics -ModuleLocation .\modules
    Load-Module -ModuleName AzureSqlDatabase -ModuleLocation .\modules


    if($AddAccount)
    {
        Add-AzureAccount
    }

    Select-AzureSubscription $SubscriptionName

    New-ProvisionedStorageAccount -StorageAccountName $StorageAccountName `
                                  -ContainerName $ContainerName `
                                  -Location $Location
        
    $EventHubInfo = New-ProvisionedEventHub -SubscriptionName $SubscriptionName `
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

    $ResourceGroupName = $ResourceGroupPrefix + "-" + $Location.Replace(" ","-")

    Provision-SqlDatabase -SqlServerName $SqlServerName `
                                        -SqlServerAdminLogin $SqlServerAdminLogin `
                                        -SqlServerAdminPassword $SqlServerAdminPassword `
                                        -SqlDatabaseName $SqlDatabaseName `
                                        -ResourceGroupName $ResourceGroupName `
                                        -Location $Location



        # Get Storage Account Key
        $storageAccountKey = Get-AzureStorageKey -StorageAccountName $StorageAccountName
        $storageAccountKeyPrimary = $storageAccountKey.Primary
        $RefdataContainerName = $ContainerName + "-refdata"
        
        $context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKeyPrimary;

        New-StorageContainerIfNotExists -ContainerName $RefdataContainerName `
                                        -Context $context

        Set-BlobData -StorageAccountName $StorageAccountName `
                     -ContainerName $RefdataContainerName `
                     -BlobName "fabrikam/buildingdevice.json" `
                     -FilePath ".\data\fabrikam_buildingdevice.json"


        $EventHubSharedAccessPolicyKey = Get-EventHubSharedAccessPolicyKey -ServiceBusNamespace $ServiceBusNamespace `
                                                                           -EventHubName $EventHubName `
                                                                           -EventHubSharedAccessPolicyName $EventHubSharedAccessPolicyName

        # Get Storage Account Key
        $storageAccountKey = Get-AzureStorageKey -StorageAccountName $StorageAccountName
        $storageAccountKeyPrimary = $storageAccountKey.Primary

        # Create SQL Job Definition
        [string]$JobDefinitionText = (Get-Content -LiteralPath (Join-Path $PSScriptRoot -ChildPath $JobDefinitionPath)).
                                    Replace("_StreamAnalyticsJobName",$StreamAnalyticsSQLJobName).
                                    Replace("_Location",$Location).
                                    Replace("_ConsumerGroupName",$ConsumerGroupName).
                                    Replace("_EventHubName",$EventHubName).
                                    Replace("_ServiceBusNamespace",$ServiceBusNamespace).
                                    Replace("_EventHubSharedAccessPolicyName",$EventHubSharedAccessPolicyName).
                                    Replace("_EventHubSharedAccessPolicyKey",$EventHubSharedAccessPolicyKey).
                                    Replace("_AccountName",$StorageAccountName).
                                    Replace("_AccountKey",$storageAccountKeyPrimary).
                                    Replace("_Container",$ContainerName).
                                    Replace("_RefdataContainer",$RefdataContainerName).
                                    Replace("_DBName",$SqlDatabaseName).
                                    Replace("_DBPassword",$SqlServerAdminPassword).
                                    Replace("_DBServer",$SqlServerName).
                                    Replace("_DBUser",$SqlServerAdminLogin)

    Provision-StreamAnalyticsJob -ServiceBusNamespace $ServiceBusNamespace `
                                            -EventHubName $EventHubName `
                                            -EventHubSharedAccessPolicyName $EventHubSharedAccessPolicyName `
                                            -StorageAccountName $StorageAccountName `
                                            -ContainerName $ContainerName `
                                            -ResourceGroupName $ResourceGroupName `
                                            -Location $Location `
                                            -JobDefinitionText $JobDefinitionText
    
    Write-Output "Provision Finished OK"                                               
}