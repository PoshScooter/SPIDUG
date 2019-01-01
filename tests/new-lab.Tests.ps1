$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$here = $here -replace '\\tests', '\\functions'
. "$here\$sut"

Describe "new-lab" {
    It "does something useful" {
        $true | Should Be $false
    }
}
