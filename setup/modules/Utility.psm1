function Write-SettingsFile
{
    Param 
    (
        [Parameter(Mandatory = $true)][string] $configurationTemplateFile,
        [Parameter(Mandatory = $true)][string] $configurationFile,
        [Parameter(Mandatory = $false)][hashtable] $appSettings,
        [string] $useLocation
    )
    PROCESS
    {
        $fileExists = Test-Path -Path $configurationFile -PathType Leaf
        $continue = $true
        if (-not $fileExists)
        {
            # copy from template
            "Configuration file not found, copying from $configurationTemplateFile"
            Copy-Item -Path $configurationTemplateFile -Destination $configurationFile -Force
        }
        else
        {
            # prompt overwrite
            $title = "Overwrite File"
            $message = "Do you want to overwrite the existing $configurationFile file?"

            $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
                "Overwrites the mysettings.config file."

            $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
                "Keeps the current file."

            $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

            $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

            switch ($result)
                {
                    0 {$continue = $true}
                    1 {$continue = $false}
                }
        }

        if ($continue)
        {
            Write-Output "Configuration file Path: $configurationFile"
            [xml]$xmlServiceConfiguration = Get-Content $configurationFile 
            $ns = new-object Xml.XmlNamespaceManager $xmlServiceConfiguration.NameTable

            if ($appSettings -ne $null) {
                Write-Output "Updating appSettings"
                foreach ($key in $appSettings.Keys) {
                    if ($useLocation -eq 'true') {
                        $node = $xmlServiceConfiguration.SelectSingleNode("/appSettings/add[@key='${key}']", $ns)
                    } else {
                        $node = $xmlServiceConfiguration.SelectSingleNode("/appSettings/add[@key='${key}']", $ns)
                    }
        
                    if ($node -ne $null) {
                        $node.value = $appSettings.Item($key)

                        Write-Output "Updated appSetting '${key}' value to '$($appSettings.Item($key))'" 
                    }
                    else {
                        Write-Error "The appSetting '${key}' could not be found in the configuration file!"
                    }
                }
            }
            else {
                Write-Output "Nothing to update in appSettings."
            }

            $xmlServiceConfiguration.Save($configurationFile)
            ""
            "File updated: {0}" -f $configurationFile
        }
    }
}

function Write-CloudSettingsFiles
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]] $serviceConfigFiles,

        [Parameter(Mandatory = $true)]
        [hashtable] $appSettings
    )
    PROCESS
    {
        $ErrorActionPreference = "Stop"

        if ($appSettings -eq $null)
        {
            Write-Error "[appSettings] paremeter cannot be null"
        }

        foreach ($file in $serviceConfigFiles)
        {
            $fileExists = Test-Path -Path $file.FullName -PathType Leaf

            if (!$fileExists)
            {
                Write-Error "Could not find file {0}" -f $file
            }

            [Xml]$xmlServiceConfiguration = Get-Content $file.FullName
            $ns = New-Object Xml.XmlNamespaceManager $xmlServiceConfiguration.NameTable
            $ns.AddNamespace('dns', 'http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceConfiguration')

            foreach ($key in $appSettings.Keys)
            {
       
                $nodes = $xmlServiceConfiguration.SelectNodes("/dns:ServiceConfiguration/dns:Role/dns:ConfigurationSettings/dns:Setting[@name='${key}']", $ns)

                if ($nodes -ne $null)
                {
                    foreach ($node in $nodes)
                    {
                        $node.value = $appSettings.Item($key)
                    }
                }
            }

            $xmlServiceConfiguration.Save($file)
            ""
            "Service Configuration File (Cloud) updated : {0}" -f $file.FullName
        }
    }
}

Export-ModuleMember Write-SettingsFile
Export-ModuleMember Write-CloudSettingsFiles