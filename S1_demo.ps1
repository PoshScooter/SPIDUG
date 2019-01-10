
# run DbcCheck to see the current status ON S!
Invoke-DbcCheck -SqlInstance s1 -ComputerName s1 -Tags Instance

Invoke-DbcCheck -SqlInstance s2 -ComputerName s2 -Tags Instance

Invoke-DbcCheck -SqlInstance s3 -ComputerName s3 -Tags Instance




# Restore a database from backup easily 
Restore-DbaDatabase -SqlInstance s2 -SqlCredential sa -Path \\dc1\Distro\backups\ -DatabaseName northwind


# full migration!
Start-DbaMigration -Source S1 -Destination S3 -BackupRestore -SharedPath \\dc1\distro\backups

# check the config
Invoke-DbcCheck -SqlInstance s3 -ComputerName s3 -Tags Instance




# want to just copy 1 DB?
Copy-DbaDatabase -Source s1 -Destination s2 -Database Adventureworks2014

# what is a task you do regularly to your servers??