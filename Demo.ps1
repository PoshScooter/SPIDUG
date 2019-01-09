pause

$name = 's3'
$sql2017 = Get-Item -Path 'C:\iso\en_sql_server_2017_developer_x64_dvd_11296168.iso'
# save passwords for later use
$locpwd = ConvertTo-SecureString "Password!" -AsPlainText -Force
$locCreds = New-Object System.Management.Automation.PSCredential (".\administrator", $locpwd)
$domCreds = New-Object System.Management.Automation.PSCredential ("poshscooter\administrator", $locpwd)

# i'm really lazy so copy this cheater function to a PS window for demo
<#
function x ($y) {
    $locpwd = ConvertTo-SecureString "Password!" -AsPlainText -Force
    $locCreds = New-Object System.Management.Automation.PSCredential (".\administrator", $locpwd)
    enter-pssession -vmname $y -credential $locCreds
}
#>


pause 

############################
# TODO: install modules 

invoke-command -VMName $name -credential $locCreds -scriptblock {
    write-verbose "Setting package trusts"
    Get-PackageSource -Name PSGallery | Set-PackageSource -Trusted -Force -ForceBootstrap

    write-verbose "installing Package providor"
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

    write-verbose "installing modules"
    Install-Module ComputerManagementDSC -Force -RequiredVersion 5.2.0.0
    Install-Module NetworkingDSC -Force -RequiredVersion 6.1.0.0
    Install-Module SQLServerDSC -force -RequiredVersion 12.1.0.0
    install-module StorageDsc -force -requiredversion 4.1.0.0
    install-module DBATools -force
    install-module pester -Force -SkipPublisherCheck
    install-module dbachecks -force
} #>

pause

# Add SQL ISO to VM
Set-VMDvdDrive -VMName $name -Path $sql2017


# Run the config to setup the Local Configuration Manager (LCM) to reboot when needed
Set-location 'C:\code\github\SPIDUG'
Invoke-Command -VMName $name -Credential $locCreds -FilePath ".\DSC\$($name)_Config2.ps1" -ArgumentList $name

Start-Sleep -Seconds 60

invoke-command -VMName $name -Credential $locCreds -ScriptBlock { Get-DscLocalConfigurationManager }

#grant rights to share for 
invoke-command -VMName 'dc1' -Credential $domCreds -ScriptBlock { Grant-SmbShareAccess -Name 'distro' -AccountName "poshscooter\$($args[0])`$" -AccessRight 'full' -Confirm:$false } -ArgumentList $name

# TODO: run the DSC install SQL
Invoke-Command -VMName $name -Credential $locCreds -FilePath ".\DSC\$($name)_Config3.ps1"

invoke-command -VMName $name -Credential $locCreds -ScriptBlock {
    New-NetFirewallRule -Name 'allow all' -Direction Inbound -Action Allow -Enabled True -DisplayName 'allow all'
}

invoke-command -VMName $name -Credential $locCreds -ScriptBlock { Restart-Computer -Force }


# run DbcCheck to see the current status ON S!
    Invoke-DbcCheck -SqlInstance s1 -ComputerName s1 -Tags Instance

    Invoke-DbcCheck -SqlInstance s2 -ComputerName s2 -Tags Instance

    Invoke-DbcCheck -SqlInstance s3 -ComputerName s3 -Tags Instance
