<#
.SYNOPSIS
Hive query - View number of events grouped by device.

.DESCRIPTION
This script creates a Hive external table on cold storage blobs, executes a Hive query that will calculate the number of events per device and display the results. You will need to provision your HDInsight cluster in the same storage account as your cold storage.

.PARAMETER subscriptionName
The name of the subscription to use.

.PARAMETER storageAccountName
The name of the storage account used as cold storage.

.PARAMETER clusterName
The name of an HDInsight cluster to use. You must provision the cluster before you can execute this script.

.EXAMPLE
C:\PS> .\hivequeryforcoldstorageeventprocessor.ps1 -subscriptionName "{subscription-name}" -storageAccountName "{storage-account-name}" -clusterName "{hdinsight-cluster-name}"
#>

Param
(
	[Parameter (Mandatory = $true)]
	[string] $subscriptionName,

	[Parameter (Mandatory = $true)]
	[string] $storageAccountName,
	
	[Parameter (Mandatory = $true)]
	[string] $clusterName,

    [string] $containerName = "eventhub-iot-coldstorage",
	[string] $directoryName = "fromeventprocessor"
)

Add-AzureAccount

$tableName = "iotjourneyhivetable2";
$location = "wasb://$containerName@$storageAccountName.blob.core.windows.net/$directoryName";

Select-AzureSubscription -SubscriptionName $subscriptionName;
Use-AzureHdInsightCluster $clusterName;

$query = "DROP TABLE $tableName; CREATE EXTERNAL TABLE IF NOT EXISTS $tableName (json string) LOCATION '" + $location  + "';
 SELECT get_json_object($tableName.json, '$.Payload.DeviceId'), count(*) 
 FROM $tableName 
 GROUP BY get_json_object($tableName.json, '$.Payload.DeviceId')";

$result = Invoke-Hive -Query $query;

Write-Host "";

"Query results"
"============="

Write-Host $result;