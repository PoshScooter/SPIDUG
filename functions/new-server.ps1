function new-server {
    param (
        [Parameter(Mandatory)]
        [VAlidatenotnullorempty()]
        [string]$name,
        [Parameter(Mandatory)]
        [VAlidatenotnullorempty()]
        [string]$VMswitch,
        [Parameter(Mandatory)]
        [VAlidatenotnullorempty()]
        [string]$parentvhd,
        [int64]$MaxMB = 2GB,
        [int64]$minMB = 512MB,
        [int64]$startUpBytes = 1GB,
        [int64]$pCount = 1
    )
    
    if (-not (test-path -Path "$((get-vmhost).virtualharddiskpath)\$($name).vhdx")) {
        $hd = new-childvhd -name $name -parentvhd $parentvhd 
        New-VM -Name $name -VHDPath $hd.path -SwitchName $VMswitch |
            set-vmmemory -DynamicMemoryEnabled $true `
            -MaximumBytes $MaxMB -MinimumBytes $minMB -StartupBytes $startUpBytes |
            Set-VMProcessor -Count $pCount
            
        start-vm -Name $name
    } else {
        Write-Error "VHD already exists with this name."
    }
}