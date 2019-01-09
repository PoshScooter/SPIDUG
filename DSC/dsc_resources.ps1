
write-verbose "Setting package trusts"
Get-PackageSource -Name PSGallery | Set-PackageSource -Trusted -Force -ForceBootstrap

write-verbose "installing Package providor"
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force


Install-module -Name xActiveDirectory       -RequiredVersion '2.19.0.0'  -Force -Confirm:$false
Install-module -Name ComputerManagementDSC  -RequiredVersion '5.2.0.0' -Force -Confirm:$false
Install-module -Name xSMBShare              -RequiredVersion '2.1.0.0' -Force -Confirm:$false
Install-module -Name networkingDSC          -RequiredVersion '6.1.0.0' -Force -Confirm:$false
Install-module -Name xdhcpserver            -RequiredVersion '2.0.0.0' -Force -Confirm:$false
Install-module -Name ActiveDirectoryCSDsc   -RequiredVersion '3.0.0.0' -Force -Confirm:$false
