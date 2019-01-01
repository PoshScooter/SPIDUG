


Install-module -Name xActiveDirectory       -RequiredVersion '2.19.0.0'  -Force -Confirm:$false
Install-module -Name ComputerManagementDSC  -RequiredVersion '5.2.0.0' -Force -Confirm:$false
Install-module -Name xSMBShare              -RequiredVersion '2.1.0.0' -Force -Confirm:$false
Install-module -Name networkingDSC          -RequiredVersion '6.1.0.0' -Force -Confirm:$false
Install-module -Name xdhcpserver            -RequiredVersion '2.0.0.0' -Force -Confirm:$false
Install-module -Name ActiveDirectoryCSDsc   -RequiredVersion '3.0.0.0' -Force -Confirm:$false

if (-not (Test-Path c:\temp)) {
    New-Item -Path C:\ -Name Temp -ItemType Directory
}

save-module -Name xActiveDirectory       -RequiredVersion '2.19.0.0'  -Path C:\temp\DSC-Resourses
save-module -Name ComputerManagementDSC  -RequiredVersion '5.2.0.0' -Path C:\temp\DSC-Resourses
save-module -Name xSMBShare              -RequiredVersion '2.1.0.0' -Path C:\temp\DSC-Resourses
save-module -Name networkingDSC          -RequiredVersion '6.1.0.0' -Path C:\temp\DSC-Resourses
save-module -Name xdhcpserver            -RequiredVersion '2.0.0.0' -Path C:\temp\DSC-Resourses
save-module -Name ActiveDirectoryCSDsc   -RequiredVersion '3.0.0.0' -Path C:\temp\DSC-Resourses