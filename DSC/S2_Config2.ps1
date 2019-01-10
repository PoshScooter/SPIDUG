param (
    [Parameter(Mandatory)]
    $name

)

Configuration Setup {
    Import-DscResource -ModuleName ComputerManagementDSC -ModuleVersion 5.2.0.0
    Import-DSCResource -ModuleName NetworkingDSC -ModuleVersion 6.1.0.0
    Import-DSCResource -ModuleName SQLServerDSC -ModuleVersion 12.1.0.0
    Import-DSCResource -ModuleName StorageDsc -ModuleVersion 4.1.0.0

    Node $allnodes.NodeName {
        LocalConfigurationManager {
            ConfigurationMode  = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
            ActionAfterReboot  = 'ContinueConfiguration'
            RefreshMode        = 'Push'
            DebugMode          = 'All'
        }

        Computer SetName {
            Name       = $node.CompName
            DomainName = $node.Domain
            Credential = $node.DomCreds
        }
    }
}

$DomPwd = ConvertTo-SecureString "Password!" -AsPlainText -Force
$DomCreds = New-Object System.Management.Automation.PSCredential ("PoShScooter\administrator", $DomPwd)

$configData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            CompName                    = 's2'
            Domain                      = 'Poshscooter'        
            PSDscAllowPlainTextPassword = $true
            DomCreds                    = $DomCreds
        }
    )
}
setup -ConfigurationData $configData

Start-DscConfiguration -Wait -Force -Path .\setup -Verbose

restart-computer -force