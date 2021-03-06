function New-SQLDatabase
{
    <#
    .Synopsis
        Creates a new SQL database
    .Description
        Creates a database in SQL server, SQL azure, SQLCompact, or Sqlite
    .Example
        New-SqlDatabase "Test DB"
    .Example
        New-SqlDatabase "Test DB" -ComputerName TheSqlServer
    .Link
        Select-SQL
    .Link
        Update-SQL
    #>
    [CmdletBinding(DefaultParameterSetName='SqlServer')]
    [OutputType([Nullable])]
    param(
    # The name of the new database
    [Parameter(Mandatory=$true,ParameterSetName='SqlServer',ValueFromPipelineByPropertyName=$true)]
    [Parameter(Mandatory=$true,ParameterSetName='MySql',ValueFromPipelineByPropertyName=$true)]
    [string]
    $DatabaseName,

    # The name of the SQL server.  By default, the local machine
    [Parameter(ParameterSetName='SqlServer',ValueFromPipelineByPropertyName=$true)]
    [Alias('CN')]
    [string]
    $ComputerName = $env:COMPUTERNAME,

    # If set, will use MySql to connect to the database    
    [Parameter(Mandatory=$true,ParameterSetName='MySql')]
    [Switch]
    $UseMySql,
    
    # The path to MySql's .NET connector.  If not provided, MySql will be loaded from Program Files        
    [Parameter(ParameterSetName='MySql')]
    [string]    
    $MySqlPath,

    # The log folder for the database
    [Parameter(ParameterSetName='SqlServer')]    
    [string]
    $DatabaseLogFolder,

    # The log folder for the database
    [Parameter(ParameterSetName='SqlServer')]    
    [string]
    $DatabaseDataFolder,

    # The initial size of the database.  By default, 10mb
    [Parameter(ParameterSetName='SqlServer')]       
    [uint32]
    $InitialDatabaseSize = 10mb,

    # The maximum size of the database
    [Parameter(ParameterSetName='SqlServer')]       
    [uint32]
    $MaximumDatabaseSize,

    # The initial size of  the database logs.  By default, this is 1mb
    [Parameter(ParameterSetName='SqlServer')]       
    [uint32]
    $InitialLogSize = 1mb,

    # The size at which the log files will grow.  By default, this is 1mb
    [Parameter(ParameterSetName='SqlServer')]       
    [uint32]
    $LogFileGrowth =1mb,

    # The size at which the database will grow.  By default, this is 5mb
    [Parameter(ParameterSetName='SqlServer')]       
    [uint32]
    $DatabaseGrowth =5mb,

    # The maximum log size
    [Parameter(ParameterSetName='SqlServer')]       
    [uint32]
    $MaximumLogSize,

    # If set, will not generate any core SQL server statistical information
    [Parameter(ParameterSetName='SqlServer')]       
    [Alias('NoStats')]
    [Switch]
    $NoStat,

    # If set, will keep a log of all transactions to the database
    [Parameter(ParameterSetName='SqlServer')]       
    [Switch]
    $KeepTransactionLog,

    # If set, will output the SQL, but will not run the command
    [Parameter(ParameterSetName='SqlServer')]       
    [Switch]
    $OutputSQL,

    # If set, will create a SQLite database
    [Parameter(Mandatory=$true,ParameterSetName='Sqlite')]
    [Alias('UseSqlLite')]
    [Switch]
    $UseSqlite,

    # The path to SQLite. If not set, will import SQLite from program files
    [Parameter(ParameterSetName='Sqlite')]    
    [string]
    $SqlitePath,
    
    # If set, will use SQL compact
    [Parameter(Mandatory=$true,ParameterSetName='SqlCompact')]    
    [Switch]
    $UseSqlCompact,
    
    # The path the SQL compact.  If not provided, SQL compact will be loaded from the GAC.
    [Parameter(ParameterSetName='SqlCompact')]    
    [string]
    $SqlCompactPath,
            
    # The path to the database file.
    [Parameter(Mandatory=$true,ParameterSetName='SqlCompact')]
    [Parameter(Mandatory=$true,ParameterSetName='Sqlite')]
    [string]
    $DatabasePath,

    # A connection string or a setting containing a connection string.    
    [Alias('ConnectionString', 'ConnectionSetting')]
    [string]$ConnectionStringOrSetting
       
    )

    process {
        if ($PSBoundParameters.ConnectionStringOrSetting) {
            if ($ConnectionStringOrSetting -notlike "*;*") {
                $ConnectionString = Get-SecureSetting -Name $ConnectionStringOrSetting -ValueOnly
            } else {
                $ConnectionString =  $ConnectionStringOrSetting
            }
            $script:CachedConnectionString = $ConnectionString
        } elseif ($ComputerName) {
            $connectionString = "Data Source=$ComputerName;Initial Catalog=Master;Integrated Security=SSPI;"
        } elseif ($script:CachedConnectionString){
            $ConnectionString = $script:CachedConnectionString
        } else {
            $ConnectionString = ""
        }


        if ($UseSQLCompact) {
            #Region Create SQL Compact DB
            if (-not ('Data.SqlServerCE.SqlCeConnection' -as [type])) {
                if ($SqlCompactPath) {
                    $resolvedCompactPath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($SqlCompactPath)
                    $asm = [reflection.assembly]::LoadFrom($resolvedCompactPath)
                } else {
                    $asm = [reflection.assembly]::LoadWithPartialName("System.Data.SqlServerCe")
                    
                }
                $null = $asm
            }
            

            $fullCreatePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DatabasePath)
            $sqlEngine = New-Object Data.SqlServerCE.SqlCeEngine "Data Source=$fullCreatePath"
            $sqlEngine.CreateDatabase()
            #endregion Create SQL Compact DB
        } elseif ($UseSqlite) {
            #region Create SQL lite DB
            if (-not ('Data.Sqlite.SqliteConnection' -as [type])) {
                if ($sqlitePath) {
                    $resolvedLitePath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($sqlitePath)
                    $asm = [reflection.assembly]::LoadFrom($resolvedLitePath)
                } else {
                    $asm = [Reflection.Assembly]::LoadFrom("$env:ProgramFiles\System.Data.SQLite\2010\bin\System.Data.SQLite.dll")
                }
                $null = $asm
            }
                
            $fullCreatePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DatabasePath)
            [Data.Sqlite.SQliteConnection]::CreateFile($fullCreatePath)
            #endregion Create SQL lite DB
        } elseif ($useMySql) {
            if (-not ('MySql.Data.MySqlClient.MySqlConnection' -as [type])) {
                if (-not $mySqlPath) {
                    $programDir = if (${env:ProgramFiles(x86)}) {
                        ${env:ProgramFiles(x86)}
                    } else {
                        ${env:ProgramFiles} 
                    }
                    $mySqlPath = Get-ChildItem "$programDir\MySQL\Connector NET 6.7.4\Assemblies\"| 
                        Where-Object { $_.Name -like "*v*" } | 
                        Sort-Object { $_.Name.Replace("v", "") -as [Version] } -Descending |
                        Select-object -First 1 | 
                        Get-ChildItem -filter "MySql.Data.dll" | 
                        Select-Object -ExpandProperty Fullname
                }
                $asm = [Reflection.Assembly]::LoadFrom($MySqlPath)
                $null = $asm
                    
            }
            $sqlConnection = New-Object MySql.Data.MySqlClient.MySqlConnection "$ConnectionString"
            $sqlConnection.Open()
            $cmd = $sqlConnection.CreateCommand()
            $cmd.CommandText = "CREATE Database $DatabaseName"
            $null = $cmd.ExecuteNonQuery()
        } else {
            #region Create SQL server database
            $sqlConnection = New-Object Data.SqlClient.SqlConnection "$connectionString"
            $sqlConnection.Open()

            $cmd = $sqlConnection.CreateCommand()

            $dbStorage = if ($DatabaseDataFolder) {
@"
    ON PRIMARY ( 
        NAME = N'$($DatabaseName)', 
        FILENAME = N'$($DataBaseDataFolder.TrimEnd("\") + "\"+  "$databaseName.MDF")', 
        SIZE = $($InitialDatabaseSize / 1mb)MB , 
        MAXSIZE = $(if ($maximumDataBaseSize) { $maximumDataBaseSize } else  { "UNLIMITED"  } ), 
        FILEGROWTH = $($DatabaseGrowth / 1mb)MB)

"@            

            } else {
""
}
            
            $logstorage = if ($DatabaseLogFolder) { @"
    LOG ON ( 
        NAME = N'${DataBaseName}_Log', 
        FILENAME = N'$($DataBaseLogFolder.TrimEnd("\") + "\" +"$databaseName.LDF" )',
        SIZE = $($InitialLogSize / 1mb)MB,
        MAXSIZE = $(if ($MaximumLogSize) { $MaximumLogSize } else { "UNLIMITED" }), 
        FILEGROWTH = $($LogFileGrowth / 1mb)MB)
"@} else { "" } 
              
            $cmd.CommandText = @"

CREATE DATABASE [$DatabaseName]
    CONTAINMENT = NONE
    $dbStorage
    $logstorage
    


"@
            if ($OutputSQL) {
                $cmd.CommandText
            } else {
            
            $null = $cmd.ExecuteNonQuery()
            }
                $(if ((-not $keeptransactionLog) -and (-not $OutputSQL)) {
                    $cmd.CommandText =  "
        ALTER DATABASE [$DatabaseName] SET RECOVERY SIMPLE 
"
            $null = $cmd.ExecuteNonQuery()
        
    })
    $(if (-not $NoStat) {
$cmd.CommandText = "
        ALTER DATABASE [$DatabaseName] SET AUTO_CREATE_STATISTICS ON 
"}
            $null = $cmd.ExecuteNonQuery()

)

                
            $sqlConnection.Close()
            $sqlConnection.Dispose()
            #endregion Create SQL server database
        }
    }
} 
 
