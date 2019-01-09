pause

$sql2014 = Get-Item -Path 'C:\ISO\en_sql_server_2014_developer_edition_with_service_pack_3_x64_dvd_083c344f.iso'
#$sql2017 = Get-Item -Path 'C:\iso\en_sql_server_2017_developer_x64_dvd_11296168.iso'
$locpwd = ConvertTo-SecureString "Password!" -AsPlainText -Force
$locCreds = New-Object System.Management.Automation.PSCredential (".\administrator", $locpwd)
$domCreds = New-Object System.Management.Automation.PSCredential ("poshscooter\administrator", $locpwd)

$name = 's1'


######################
# TODO: Create the VM locally
#set-location '~\OneDrive\Github\SPIDUG'
$functions = Get-ChildItem .\functions -Filter *.ps1
foreach ($f in $functions) {
    . "$($f.fullname)"
}
$parentvhd = get-item "$((Get-VMHost).VirtualMachinePath)\templates\win2016.vhdx"

# i'm really lazy so copy this cheater function to a PS window for demo
<#
function x ($y) {
    $locpwd = ConvertTo-SecureString "Password!" -AsPlainText -Force
    $locCreds = New-Object System.Management.Automation.PSCredential (".\administrator", $locpwd)
    enter-pssession -vmname $y -credential $locCreds
}
#>


new-server -name $name -parentvhd $parentvhd 

pause 

# TODO: change the password and show that next to nothing is installed

############################
# TODO: install modules and set LCM to reboot

invoke-command -VMName $name -credential $locCreds -scriptblock {
   
    # TODO: This will change the server name and reboot
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
Set-VMDvdDrive -VMName $name -Path $sql2014


Invoke-Command -VMName $name -Credential $locCreds -FilePath ".\DSC\$($name)_Config2.ps1" -ArgumentList $name

Start-Sleep -Seconds 45

invoke-command -VMName $name -Credential $locCreds -ScriptBlock { Get-DscLocalConfigurationManager }

# TODO: run the DSC install SQL

#grant rights to share for new VM
invoke-command -VMName 'dc1' -Credential $domCreds -ScriptBlock { Grant-SmbShareAccess -Name 'distro' -AccountName "poshscooter\$($args[0])`$" -AccessRight 'full' -Confirm:$false } -ArgumentList $name

Invoke-Command -VMName $name -Credential $locCreds -FilePath ".\DSC\$($name)_Config3.ps1"

invoke-command -VMName $name -Credential $locCreds -ScriptBlock {
    New-NetFirewallRule -Name 'allow all' -Direction Inbound -Action Allow -Enabled True -DisplayName 'allow all'
}

invoke-command -VMName $name -Credential $locCreds -ScriptBlock { Restart-Computer -Force }


Invoke-Command -VMName $name -Credential $domCreds -ScriptBlock {
    Set-DbcConfig -Name policy.instancemaxdop.userecommended -Value $true
    Restore-DbaDatabase -SqlInstance s1 -Path '\\dc1\Distro\packages\dbs\AdventureWorks2014.bak'
    Invoke-DbaCmd -SqlInstance s1 -File \\dc1\Distro\packages\dbs\instnwnd.sql
    Install-DbaWhoIsActive -SqlInstance s1 -Database Master
    Install-DbaFirstResponderKit -SqlInstance s1 -Database master
    Install-DbaMaintenanceSolution -SqlInstance s1 -Database master -BackupLocation \\dc1\Distro\backups\ -InstallJobs -ReplaceExisting -Solution All
    Set-DbaMaxDop -SqlInstance s1 
}




