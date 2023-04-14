md c:\temp
tasklist > c:\temp\tasklist.txt
PowerShell.exe -nologo -command "Get-Process" > PowerShell.Get.Process.plain.txt
PowerShell.exe -nologo -command "Get-Process | ConvertTo-JSON" > c:\temp\PowerShell.Get.Process.json
