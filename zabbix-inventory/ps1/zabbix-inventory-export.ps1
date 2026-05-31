# Configuration
$ZabbixUrl = "https://book.zabbix.the/api_jsonrpc.php"
$Token = "19e223d425836f369afb6586acdd828227b252b1d28c61af2c3599959c6acf87"

# enable old tls 1.2 to be compatible with PowerShell 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Headers
$Headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type"  = "application/json-rpc"
}

# JSON-RPC request body
$Body = @{
    jsonrpc = "2.0"
    method  = "host.get"
    params  = @{
        output = @("name", "inventory")
        selectInventory = @(
            "os_short",
            "serialno_a",
            "model",
            "hw_arch",
            "poc_1_screen",
            "date_hw_install"
        )
        
        searchInventory = @{
            os = " "
        }

    }
    id = 1
} | ConvertTo-Json -Depth 10

# Execute API call
$Response = Invoke-RestMethod `
    -Uri $ZabbixUrl `
    -Method Post `
    -Headers $Headers `
    -Body $Body `
    -UseBasicParsing `
    

$Table = $Response.result |
    Select-Object `
        name,
        @{Name='OS';Expression={$_.inventory.os_short}},
        @{Name='Architecture';Expression={$_.inventory.hw_arch}},
        @{Name='CPUs';Expression={$_.inventory.serialno_a}},
        @{Name='Model';Expression={$_.inventory.model}},
        @{Name='Agent';Expression={$_.inventory.poc_1_screen}},
        @{Name='Boot time';Expression={$_.inventory.date_hw_install}}

# Save as CSV
$Table | Export-Csv `
    -Path "C:\Temp\zabbix_hosts.csv" `
    -NoTypeInformation `
    -Encoding UTF8

# print sortable table on-the-fly
$Table | Out-GridView

