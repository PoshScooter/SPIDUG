$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$here = $here -replace '\\tests', '\\functions'
. "$here\$sut"

Describe "New-childvhd" {
    mock "New-VHD" 
    it "should return a vhdx" {
        $true | should be $false
    }
}