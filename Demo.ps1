$name = 's1'
$locpwd = ConvertTo-SecureString "Password!" -AsPlainText -Force
#$saCreds = New-Object System.Management.Automation.PSCredential ("sa", $locpwd)

$domCreds = New-Object System.Management.Automation.PSCredential ("poshscooter\administrator", $locpwd)

Invoke-Command -VMName $name -Credential $domCreds -ScriptBlock {
    Set-DbaMaxDop -SqlInstance localhost
    Set-DbaMaxMemory -SqlInstance localhost
    Set-DbaDbCompression

}

