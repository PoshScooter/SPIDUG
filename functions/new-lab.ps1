. .\new-childvhd.ps1
. .\new-server.ps1

$parentVHD = 'C:\Virtual Machine\templates\Win2016.vhdx'

function new-lab {
    param(
        [Parameter(Mandatory=$false)]
        [string]$labname = 'Lab',
        [switch]$dc,
        [switch]$createNat,
        [object]$parentVHD,
        [string[]]$otherServers
    ) 

    if ($createNat) {
        if (-not (Get-VMSwitch | Where-Object name -match $labname )) {
            $switch = New-VMSwitch -SwitchName $labName -SwitchType Internal
            $vAdapter = Get-NetAdapter | Where-Object { $_.name -match $switch.name }
            New-NetIPAddress -IPAddress 192.168.244.10 -PrefixLength 24 -InterfaceIndex $vAdapter.ifIndex
            New-NetNat -Name 'NatNetwork' -InternalIPInterfaceAddressPrefix 192.168.244.0/24
        } else {
            Write-Error "Lab name already exists."
        }
    }
    $vmSwitch = Get-VMSwitch | Where-Object name -match $labname
    if ($dc) {
        # create DC
        $dc1 = new-server -name 'DC1' -VMswitch $vmSwitch.Name  `
            -parentvhd $parentVHD
        Write-Verbose "New DC1: $dc1"
    }

    if ($otherServers) {
        foreach ($os in $otherServers) {
            $s = new-server -name $os -VMswitch $vmSwitch.Name -parentvhd $parentVHD
            Write-Verbose "New Server: $S"
        }
    }
}

new-lab -labname 'lab' -parentVHD $parentVHD -otherServers 's1'
