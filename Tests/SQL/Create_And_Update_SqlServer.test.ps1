
$dbName = "Db" + (Get-Random)

New-SQLDatabase -DatabaseName $dbName -ComputerName localhost 

$connectionString = "Data Source=$env:ComputerName;Initial Catalog=$dbName;Integrated Security=SSPI;"

#Add-SqlTable -DatabasePath $randomDatabasePath -UseSQLite -TableName "TestTable" -Column a,b -KeyType Sequential

$inputObjs = @()
$inputObjs += New-Object PSObject -Property @{
    "a" = Get-Random
    "B" = Get-Random
} 
$o = New-Object PSObject -Property @{
    "a" = Get-Random
    "B" = Get-Random
}
$o.pstypenames.clear()
$o.pstypenames.add('a')
$inputObjs += $o 
$inputObjs |
    Update-Sql -TableName "TestTable" -Force -connectionStringOrSetting $connectionString

$dbobjs = Select-SQL -FromTable TestTable -ConnectionStringOrSetting $connectionString

$dbobjs |
    Add-Member NoteProperty B (Get-Random) -Force -PassThru |
    Update-Sql -TableName "TestTable" -ConnectionStringOrSetting $connectionString

Select-SQL -FromTable TestTable -ConnectionStringOrSetting $connectionString




Remove-SQL -TableName TestTable -Where "RowKey = '$($dbobjs[0].RowKey.Trim())' "  -ConnectionStringOrSetting $connectionString -Confirm:$false



#Remove-Item -Path $randomDatabasePath
