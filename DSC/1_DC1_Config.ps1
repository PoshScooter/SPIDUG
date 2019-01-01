<#


https://blogs.technet.microsoft.com/ashleymcglone/2015/03/20/deploy-active-directory-with-powershell-dsc-a-k-a-dsc-promo/
#>
configuration NewDomain
{
    param
    (
        [Parameter(Mandatory)]
        [pscredential]$safemodeAdministratorCred,
        [Parameter(Mandatory)]
        [pscredential]$domainCred
    )

    Import-DscResource -ModuleName xActiveDirectory #-ModuleVersion '2.19.0.0'
    Import-DscResource -ModuleName ComputerManagementDSC #-ModuleVersion '5.2.0.0'
    Import-DscResource -ModuleName xSMBShare #-ModuleVersion '2.1.0.0'
    Import-DscResource -ModuleName networkingDSC #-ModuleVersion '6.1.0.0'
    Import-DscResource -ModuleName xdhcpserver #-ModuleVersion '2.0.0.0'
    Import-DscResource -ModuleName ActiveDirectoryCSDsc #-ModuleVersion '3.0.0.0'

    Node $AllNodes.Where{$_.Role -eq "Primary DC"}.Nodename
    {
        LocalConfigurationManager
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        Computer Rename {
            Name = $node.DCName
        }

        File ADFiles {
            DestinationPath = 'C:\NTDS'
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn = '[Computer]Rename'
        }

        WindowsFeature ADDSInstall {
            Ensure = "Present"
            Name = "AD-Domain-Services"
            DependsOn =  '[File]ADFiles'
        }

        # Optional GUI tools
        WindowsFeature ADDSTools {
            Ensure = "Present"
            Name = "RSAT-ADDS"
            DependsOn = '[file]ADFiles'
        }

        # No slash at end of folder paths
        xADDomain FirstDS {
            DomainName = $Node.DomainName
            DomainAdministratorCredential = $domainCred
            SafemodeAdministratorPassword = $safemodeAdministratorCred
            DatabasePath = 'c:\NTDS'
            LogPath = 'c:\NTDS'
            DependsOn = "[WindowsFeature]ADDSInstall","[File]ADFiles"
        }
        
        File DistroFolder {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = 'c:\distro\DSC-Resources'
        }

        xSmbShare CreateShare {
            DependsOn = '[xADDomain]FirstDS'
            Name = "Distro"
            Path = 'c:\distro'
            ReadAccess = 'Everyone'
        }

        IPAddress setIP {
            IPAddress = '192.168.244.1'
            AddressFamily = "IPv4"
            InterfaceAlias = 'Ethernet'
        }

        DefaultGatewayAddress GWaddress {
            DependsOn = '[ipaddress]setip'
            InterfaceAlias = 'ethernet'
            AddressFamily = 'IPv4'
            Address = '192.168.244.244'

        }

        DnsServerAddress SetDns {
            Address = '192.168.244.1', '8.8.8.8'
            DependsOn = '[IPAddress]setIP'
            interfacealias = 'ethernet'
            AddressFamily = 'IPv4'
        }
        
        WindowsFeature DHCP {
            Name = 'DHCP'
            Ensure = 'Present'
            IncludeAllSubFeature = $true
            DependsOn = '[DnsServerAddress]Setdns'
        }

        xDhcpServerScope Scope { 
            Ensure = 'Present'
            IPStartRange = '192.168.244.10' 
            IPEndRange = '192.168.244.254' 
            ScopeId = '192.168.244.0'
            Name = 'PoShScooter' 
            SubnetMask = '255.255.255.0' 
            LeaseDuration = '00:08:00' 
            State = 'Active' 
            AddressFamily = 'IPv4'
            DependsOn = @('[WindowsFeature]DHCP') 

        } 
 
        xDhcpServerOption Option { 
            Ensure = 'Present' 
            ScopeID = '192.168.244.0' 
            DnsDomain = 'poshscooter.com' 
            DnsServerIPAddress = '192.168.244.1','8.8.8.8' 
            AddressFamily = 'IPv4' 
            Router = '192.168.244.244'
            DependsOn = @('[WindowsFeature]DHCP') 

        } 
        xDhcpServerAuthorization AuthDHCP {
            Ensure = 'Present'
            IPAddress = '192.168.244.1'
            DnsName = 'DC1.poshscooter.com'
            DependsOn = @('[windowsfeature]Dhcp')
        }
    }
}

$ConfigData = @{
    AllNodes = @(
        @{
            Nodename = "localhost"
            DCName = 'DC1'
            Role = "Primary DC"
            DomainName = "PoshScooter.com"
            RetryCount = 20
            RetryIntervalSec = 30
            PsDscAllowPlainTextPassword = $true
        }
    )
}

$DomPwd = ConvertTo-SecureString "Password!" -AsPlainText -Force
$DomCreds = New-Object System.Management.Automation.PSCredential ("PoshScooter\administrator", $DomPwd)

write-verbose "Applying configuration DC1_Config"
NewDomain -ConfigurationData $ConfigData -safemodeAdministratorCred $DomCreds -domainCred $DomCreds



# Make sure that LCM is set to continue configuration after reboot
Set-DSCLocalConfigurationManager -Path .\NewDomain -Verbose -force

# Build the domain
Start-DscConfiguration -Wait -Force -Path .\NewDomain -Verbose

