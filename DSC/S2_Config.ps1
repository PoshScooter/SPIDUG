pause

######################
# TODO: Create the VM locally
set-location '~\OneDrive\Github\SPIDUG'
$functions = Get-ChildItem .\functions -Filter *.ps1
foreach ($f in $functions) {
    . "$($f.fullname)"
}

# i'm really lazy so copy this cheater function to a PS window for demo
<#
function x ($y) {
    $locpwd = ConvertTo-SecureString "Password!" -AsPlainText -Force
    $locCreds = New-Object System.Management.Automation.PSCredential (".\administrator", $locpwd)
    enter-pssession -vmname $y -credential $locCreds
}
#>

$locpwd = ConvertTo-SecureString "Password!" -AsPlainText -Force
$locCreds = New-Object System.Management.Automation.PSCredential (".\administrator", $locpwd)

$domCreds = New-Object System.Management.Automation.PSCredential ("poshscooter\administrator", $locpwd)

$parentvhd = get-item "C:\VMs\templates\template2019.vhdx"
$name = 's2' 

Pause
# TODO: create VM
new-server -name $name -VMswitch 'nat' -parentvhd $parentvhd 

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


# TODO: run the DSC to set IP and rename

Invoke-Command -VMName $name -Credential $locCreds -FilePath ".\DSC\$($name)_Config2.ps1" -ArgumentList $name

Start-Sleep -Seconds 15

invoke-command -VMName $name -Credential $locCreds -ScriptBlock { Get-DscLocalConfigurationManager }

# TODO: run the DSC install SQL

#grant rights to share for new VM
invoke-command -VMName 'dc1' -Credential $domCreds -ScriptBlock { Grant-SmbShareAccess -Name 'distro' -AccountName "poshscooter\$($args[0])`$" -AccessRight 'full' -Confirm:$false } -ArgumentList 's4'

Invoke-Command -VMName $name -Credential $locCreds -FilePath ".\DSC\$($name)_Config3.ps1" 

invoke-command -VMName $name -Credential $locCreds -ScriptBlock {
    New-NetFirewallRule -Name 'allow all' -Direction Inbound -Action Allow -Enabled True -DisplayName 'allow all'
}

invoke-command -VMName $name -Credential $locCreds -ScriptBlock { Restart-Computer -Force }
