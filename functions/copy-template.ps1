function Copy-Template {
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty]
        [string]$name,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty]
        [object]$tmplt,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty]
        [object]$newVM
    )

    try {
        New-Item -Path $newVM -ItemType Directory > $null
        Copy-Item -Path (Get-ChildItem -Path $tmplt.FullName).fullname -Destination $newVM -PassThru
    }
    catch {
        Write-Error "Could not copy $($tmplt.fullname) to $newVM"
    }
}
