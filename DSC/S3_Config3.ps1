$name = 's3'
Configuration Setup {
    Import-DscResource -ModuleName ComputerManagementDSC -ModuleVersion 5.2.0.0
    Import-DSCResource -ModuleName NetworkingDSC -ModuleVersion 6.1.0.0
    Import-DSCResource -ModuleName SQLServerDSC -ModuleVersion 12.1.0.0
    Import-DSCResource -ModuleName StorageDsc -ModuleVersion 4.1.0.0

    Node $allnodes.NodeName {

        # https://github.com/PowerShell/SqlServerDsc/blob/dev/Examples/Resources/SqlSetup/2-InstallNamedInstanceSingleServer.ps1

        #region Install prerequisites for SQL Server
        WindowsFeature 'NetFramework35' {
            Name      = 'NET-Framework-Core'
            Source    = '\\DC1\Distro\sources\sxs' # Assumes built-in Everyone has read permission to the share and path.
            Ensure    = 'Present'
            
        }

        WindowsFeature 'NetFramework45' {
            Name      = 'NET-Framework-45-Core'
            Ensure    = 'Present'
            DependsOn = '[WindowsFeature]NetFramework35'
        }

        <#Removing due to time constraints on the build.

        Package ssms {
            Name      = "Microsoft SQL Server Management Studio - 17.9.1"
            Path      = "\\DC1\Distro\Packages\ssms\SSMS-Setup-ENU.exe"
            Ensure    = 'Present'
            LogPath   = "$($env:TEMP)\ssms.log"
            ProductId = ''
            Arguments = '/install /QUIET /norestart'
            DependsOn = '[SqlSetup]InstallDefaultInstance'
        } #>


        #endregion Install prerequisites for SQL Server

        #region Install SQL Server
        SqlSetup 'InstallDefaultInstance' {
            InstanceName         = 'MSSQLSERVER'
            Features             = 'SQLENGINE'
            SQLCollation         = 'SQL_Latin1_General_CP1_CI_AS'
            SecurityMode         = 'SQL'
            SAPwd                = $node.SqlAdministratorCredential
            AgtSvcAccount        = $node.SqlAgentServiceCredential
            SQLSysAdminAccounts  = $node.SqlInstallCredential.UserName
            InstallSharedDir     = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir  = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir          = 'C:\Program Files\Microsoft SQL Server'
            InstallSQLDataDir    = 'C:\MSSQL\Data'
            SQLUserDBDir         = 'C:\MSSQL\Data'
            SQLUserDBLogDir      = 'C:\MSSQL\Data'
            SQLTempDBDir         = 'C:\MSSQL\Data'
            SQLTempDBLogDir      = 'C:\MSSQL\Data'
            SQLBackupDir         = 'C:\MSSQL\Backup'
            SourcePath           = 'd:\'
            UpdateEnabled        = 'False'
            ForceReboot          = $false
            PsDscRunAsCredential = $SqlInstallCredential
            DependsOn            = '[WindowsFeature]NetFramework35', '[WindowsFeature]NetFramework45'
        }

        SqlServerNetwork 'ChangeTcpIpOnDefaultInstance'
        {
            InstanceName         = 'MSSQLSERVER'
            ProtocolName         = 'Tcp'
            IsEnabled            = $true
            RestartService       = $true
            PsDscRunAsCredential = $SystemAdministratorAccount
        }
        #endregion Install SQL Server
    }
}

$DomPwd = ConvertTo-SecureString "Password!" -AsPlainText -Force
$DomCreds = New-Object System.Management.Automation.PSCredential ("PoShScooter\administrator", $DomPwd)

$saCreds = New-Object System.Management.Automation.PSCredential ("PoShScooter\administrator", $DomPwd)

$configData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'
            CompName                    = $name
            Domain                      = 'PoShScooter'
            SqlAdministratorCredential  = $saCreds
            SqlInstallCredential        = $DomCreds
            PSDscAllowPlainTextPassword = $true
            DomCreds                    = $DomCreds
        }
    )
}


setup -ConfigurationData $configData

Start-DscConfiguration -Wait -Force -Path .\setup -Verbose
