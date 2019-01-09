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
}