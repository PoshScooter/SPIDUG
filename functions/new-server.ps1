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
        [string]$parentvhd

    )
    
    if (-not (test-path -Path "$((get-vmhost).virtualharddiskpath)\$($name).vhdx")) {
        $hd = new-childvhd -name $name -parentvhd $parentvhd 
        New-VM -Name $name -VHDPath $hd.path -SwitchName $VMswitch |
            set-vmmemory -DynamicMemoryEnabled $true `
            -MaximumBytes 2GB -MinimumBytes 512MB -StartupBytes 1GB
        start-vm -Name $name
    } else {
        Write-Error "VHD already exists with this name."
    }
}