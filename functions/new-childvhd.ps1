

function new-childvhd {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [string[]]$name,
        [parameter(Mandatory)]
        [object]$parentvhd
    )
    
    begin {
        # create a new vhd that is a child disc of 
        if (-not (Test-Path -Path $parentvhd)) {
            Write-Error "Could not find parent disk"
        }
    }
    
    process {
        foreach ($n in $name) {
            $vhd = New-VHD -ParentPath $parentvhd -Path "$((Get-VMHost).VirtualHardDiskPath)\\$($n).vhdx" -Differencing
        }
    }
    
    end {
        return $vhd 
    }
}
