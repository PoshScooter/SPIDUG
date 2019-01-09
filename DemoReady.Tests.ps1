Describe "Checking config" {
    $vms = Get-VM DC1, S1, S2, S3
    it "Should have running VMs" {
        $vms.state.count | should -be 4
    }

    it "confirm checkpoints" {
        foreach ($vm in $vms) {
            $vm.ParentCheckpointName | Should -Match "DEMO READY"
        }
    }
    Context "Domain checks" {
        $locpwd = ConvertTo-SecureString "Password!" -AsPlainText -Force
        $domCreds = New-Object System.Management.Automation.PSCredential ("poshscooter\administrator", $locpwd)
        $x = Invoke-Command -VMName DC1 -Credential $domCreds { 
            Get-ADComputer -Filter *
        }
        it "Domain should be not have S3 in it" {
            ($x.DNSHostName.Where{ $_ -match 's3' }).count | should -be 0
        }

        it "Domain should only have 3 objects in it" {
            $x.DNSHostName.count | should -be 3
        }
    }
}