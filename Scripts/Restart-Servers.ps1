<#
.SYNOPSIS
    Restarts/IISreset or Healtchecks servers based on the .PSD1 file located in the Inventory path
.DESCRIPTION
    Restarts/IISreset or Healtchecks servers based on the .PSD1 file located in the Inventorty path
.EXAMPLE
     .\Restart-Servers.ps1 -InventoryPath C:\Repos\RestartServers\Data\Test.psd1 -Roles Uygulama -Location PROD -Operation HealthCheckOnly -LBPath 'c:\Inetpub\wwwroot\lbcheck\lbcheck.html' -ThrottleLimit 2 

    ServerName                Reachable MissingServices RunningServices   StoppedServices LBConfigured LBState                                                                               Date                
    ----------                --------- --------------- ---------------   --------------- ------------ -------                                                                               ----                
    emreg-sma.contoso.com          True IISADMIN        W3SVC                                    False Cannot find path 'C:\Inetpub\wwwroot\lbcheck\lbcheck.html' because it does not exist. 1/15/2020 4:40:14 AM
    emreg-dsc.contoso.com          True IISADMIN                          W3SVC                  False Cannot find path 'C:\Inetpub\wwwroot\lbcheck\lbcheck.html' because it does not exist. 1/15/2020 4:40:14 AM
    emreg-om16ms1.contoso.com      True                 {IISADMIN, W3SVC}                         True RUNNING!                                                                              1/15/2020 4:40:14 AM

.EXAMPLE
    .\Restart-Servers.ps1 -InventoryPath C:\Repos\RestartServers\Data\Test.psd1 -Roles Uygulama -Location PROD -Operation Restart -LBPath 'c:\Inetpub\wwwroot\lbcheck\lbcheck.html' -ThrottleLimit 2 
    ------------------------------------
    Restart Summary
    ------------------------------------


    ServerName                RestartDuration RestartStatus                                                                                                      LBExist LastLBStatus
    ----------                --------------- -------------                                                                                                      ------- ------------
    emreg-dsc.contoso.com                   1 Cannot wait for the local computer to restart. The local computer is ignored when the Wait parameter is specified.   False             
    emreg-sma.contoso.com                  36 True                                                                                                                 False             
    emreg-om16ms1.contoso.com              92 True                                                                                                                  True RUNNING!    


    ------------------------------------
    Helthcheck Summary
    ------------------------------------


    ServerName                Reachable MissingServices RunningServices   StoppedServices LBConfigured LBState                                                                               Date                
    ----------                --------- --------------- ---------------   --------------- ------------ -------                                                                               ----                
    emreg-dsc.contoso.com          True IISADMIN                          W3SVC                  False Cannot find path 'C:\Inetpub\wwwroot\lbcheck\lbcheck.html' because it does not exist. 1/15/2020 4:59:40 AM
    emreg-om16ms1.contoso.com      True                 {IISADMIN, W3SVC}                         True RUNNING!                                                                              1/15/2020 4:59:40 AM
    emreg-sma.contoso.com          True IISADMIN        W3SVC                                    False Cannot find path 'C:\Inetpub\wwwroot\lbcheck\lbcheck.html' because it does not exist. 1/15/2020 4:59:41 AM


    .EXAMPLE
    .\Restart-Servers.ps1 -InventoryPath C:\Repos\RestartServers\Data\Test.psd1 -Roles Uygulama -Location PROD -Operation IISReset -LBPath 'c:\Inetpub\wwwroot\lbcheck\lbcheck.html' -ThrottleLimit 2 
    ------------------------------------
    IISReset Summary
    ------------------------------------


    ServerName                ISResetDuration IISResetStatus LBExist LastLBStatus
    ----------                --------------- -------------- ------- ------------
    emreg-dsc.contoso.com                               True   False             
    emreg-sma.contoso.com                               True   False             
    emreg-om16ms1.contoso.com                           True    True RUNNING!    

    ------------------------------------
    Helthcheck Summary
    ------------------------------------

    ServerName                Reachable MissingServices RunningServices   StoppedServices LBConfigured LBState                                                                               Date                
    ----------                --------- --------------- ---------------   --------------- ------------ -------                                                                               ----                
    emreg-sma.contoso.com          True IISADMIN        W3SVC                                    False Cannot find path 'C:\Inetpub\wwwroot\lbcheck\lbcheck.html' because it does not exist. 1/15/2020 5:07:02 AM
    emreg-om16ms1.contoso.com      True                 {IISADMIN, W3SVC}                         True RUNNING!                                                                              1/15/2020 5:07:03 AM
    emreg-dsc.contoso.com          True IISADMIN                          W3SVC                  False Cannot find path 'C:\Inetpub\wwwroot\lbcheck\lbcheck.html' because it does not exist. 1/15/2020 5:07:03 AM

#>
[CmdletBinding(SupportsShouldProcess = $True)]
Param(
    [Parameter(Mandatory = $True)]
    [ValidateScript({test-path -Path $_ -PathType 'Leaf'})]
    [string]$InventoryPath,
    [Parameter(ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
    [string[]]$Roles,
    [Parameter(Mandatory = $True)]
    [ValidateSet('PROD','ODM')]
    [string]$Location,
    [Parameter(Mandatory = $True)]
    [ValidateSet('IISReset','Restart','HealthCheckOnly')]
    [String]$Operation,
    [int32]$LBWSeconds = 60,
    [string]$LBPath = 'c:\Inetpub\wwwroot\lbcheck\lbcheck.html',
    [int32]$ThrottleLimit=5
)
Process 
{
    Function Get-Servers     
    {

        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $true)]
            [Hashtable]$Inventory,
            [Parameter(Mandatory = $true)]
            [string]$Role,
            [Parameter(Mandatory = $true)]
            [string]$Location

        )
        $Inventory.AllNodes.Where({$_.Role -eq $Role -and $_.Location -eq $Location }).NodeNAme

    }
    Function Get-WebApplications     
    {

        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $true)]
            [Hashtable]$Inventory,
            [Parameter(Mandatory = $true)]
            [string]$Role

        )
        $Inventory.NonNodedata.Roles.$Role.WebApplications

    }
    
    Workflow Test-Servers
        {

            [CmdletBinding()]
            Param(

                [int32]$ThrottleLimit,
                [Parameter(Mandatory = $True)]
                [string[]]$Servers,
                [Parameter(Mandatory = $True)]
                [Hashtable]$Inventory,
                [Parameter(Mandatory = $True)]
                [string]$Role,
                [Parameter(Mandatory = $True)]
                [string]$LBPath

            )

            foreach -parallel -throttlelimit $ThrottleLimit ($Server in $Servers)
            {
                Write-Verbose "[$(Get-Date -Format G)] Working on $Server"
                try 
                {
                    $PingTest = Test-Connection  -ComputerName $Server -ErrorAction Stop -count 1
                    
                }
                catch 
                {
                    $PingERror=$_
                }
                Finally
                {
                    $PingResult = [PSCustomObject]@{
                    PingStatus = if ($PingError) {$PingError.ErrorRecord} else {$PingTest.StatusCode}
                    ServerName = $Server
                    }
                    Write-verbose "$PingResult"
                }

                if ($PingResult.PingStatus -eq 0)
                {
                    $Services = $Inventory.NonNodeData.Roles.$Role.Services.Keys  
                    
                    $ServicesResult = foreach ($Service in $Services) 
                    {
                        try 
                        {
                        
                        $ServiceResult = Get-Service -Name $Service -PSComputerName $Server -ErrorAction Stop
                        
                        }
                        catch 
                        {
                        
                        $ServiceError = $_ 
                        
                        }
                        finally 
                        {
                            [PSCustomObject]@{
                    
                            Name = $Service
                            DisplayName = if (!$ServiceError) {$ServiceResult.DisplayName} else {'N/A'}
                            Status = if ($ServiceError) {$ServiceError.ErrorRecord} else {$ServiceResult.Status}
                            StartType = if (!$ServiceError) {$ServiceResult.StartType} else {'N/A'}
                            Server = $Server
                            }
                            $ServiceError = $null
                        }
                            
                    }
                        $MissingServices = ($ServicesResult | Where-Object {$_.Status -match 'Cannot\sfind\sany\sService\swith\sservice\sname'}).Name
                        $RunningServices = ($ServicesResult | Where-Object {$_.Status -eq 'Running'}).Name
                        $StoppedServices = ($ServicesResult | Where-Object {$_.Status -eq 'Stopped'}).Name


                    try {
                        $Content = Get-Content -PSComputerName $Server -Path $LBPath -ErrorAction Stop
                        }
                        Catch{
                        
                        $ContentError = $_ 
                        
                        
                        }
                        Finally {
                            $LBInfo = [PSCustomObject]@{
                        
                            LBStatus = if($Content) {$Content} else {$ContentError.ErrorRecord}
                            Server = $Server
                            
                        
                            }

                    # get Web applications
                    $WebApplications = $Inventory.NonNodedata.Roles.$Role.WebApplications 

                    Write-verbose "Checking $($WebApplications -join ',') on $server"
                    
                    $WebApplicationStatus = inlinescript {
                        Set-Location $PSHOME
                        Import-module WebAdministration -Verbose:$false
                        Write-verbose "Getting WebApplications on $($env:ComputerName) "
                        $WebApplicationStats = foreach ($WebApplication in $Using:WebApplications) {
                            try                
                            {
                                $WebApplicationObject = Get-WebApplication -Name $WebApplication -ErrorAction stop 
                                $WebApplicationStat =  (Get-WebAppPoolState -Name ($WebApplicationObject.ApplicationPool)).Value                  
                            }
                            Catch 
                            {
                                $WebApplicationStat = 'Missing'
                            
                            }
                            Finally {
                            
                            @{$WebApplication = $WebApplicationStat}
                            Write-Verbose "Server: $($env:computerName), WebApplication: $WebApplication, State = $WebApplicationStat"
                            }                     
                        
                            
                        }
        
                        $MissingWebApplications =  ($WebApplicationStats.Where({$_.Values -eq 'Missing'})).Keys -join ','
                        $StoppedWebApplications =  ($WebApplicationStats.Where({$_.Values -eq 'Stopped'})).Keys -join ','
                        
                        if (-not $WebApplicationStats.Where({$_.Values -ne 'Started'})) {
                        
                           # add back to load balancer
                           $WebApplicationState = 'Healthy'
                        
                        
                        } else {
                        
                            $WebApplicationState = 'Unhealthy'
                        Write-Verbose "There are missing or not started Web applications. Not adding this server back to load balancer. $(if($MissingWebApplications){"`nMissingWebApplications: $MissingWebApplications"}) $(if($StoppedWebApplications){"`nStoppedWebApplications: $StoppedWebApplications"})"
                            
                        }
                    
                        [PSCustomObject]@{
        
                            'WebApplicationState' = $WebApplicationState
                            'MissingWebApplications' = if ($MissingWebApplications) {$MissingWebApplications} else {'N/A'}
                            'StoppedWebApplications' = if ($StoppedWebApplications) {$StoppedWebApplications} else {'N/A'}
                            'Server' = $server
                        }
                    
                    } -PSComputerName $Server
                    
                    
                    [PSCustomObject]@{
                    
                        ServerName              =   $Server
                        Reachable               =   $PingResult.PingStatus
                        WebApplications         =   $WebApplicationStatus.WebApplicationState
                        MissingWebApplications  =   $WebApplicationStatus.MissingWebApplications
                        StoppedWebApplications  =   $WebApplicationStatus.StoppedWebApplications
                        MissingServices         =   $MissingServices
                        RunningServices         =   $RunningServices
                        StoppedServices         =   $StoppedServices
                        LBConfigured            =   $LBinfo.LBStatus -match '(^Running\!$)|(^Running$)'
                        LBState                 =   $LBInfo.LBStatus
                        Date                    =   Get-Date
        
                    }
    
                }
                            
            
            }
            

        }
        }
    Workflow Restart-Servers {

        Param(
        [Parameter(Mandatory=$true)]
        [String[]]$Servers,
        [Parameter(Mandatory=$true)]
        [string]$LBPath,
        [Parameter(Mandatory=$true)]
        [int32]$LBWSeconds,
        [Parameter(Mandatory=$true)]
        [int32]$ThrottleLimit
        )
        
        Foreach -Parallel -throttlelimit $ThrottleLimit ($Server in $Servers){
            Write-Verbose "[$(Get-date -Format G)]Restart server operation started on $Server"
            $Start = Get-Date
            $LBExist = Test-Path -path $LBPath -PSComputerName $Server
            if ($LBExist) {
                    Set-content -Value 'RUNNING' -Path $LBPath -PSComputerName $Server -verbose:$False
                    Start-Sleep -Seconds $LBWSeconds
            }
            
            try {
                
                Restart-Computer -PSComputerName $Server -wait -Force -ErrorAction Stop
                $RestartStatus = $true
            }
            
            catch {                    
                   
                $RestartStatus = $_.ErrorRecord
            
            }
            
            # If load balancer file exists and all the web applications are started add the server back to loadbalancer
            if ($LBExist) {
                    Set-content -Value 'RUNNING!' -Path $LBPath -PSComputerName $Server
                    $LastLBStatus = Get-Content -Path $LBPath -PSComputerName $Server
            }
                
            $Duration = inlinescript {
                        [Math]::Round(((Get-Date) - $Using:Start).TotalSeconds)
            }

            [PSCustomObject]@{
                    
                    ServerName = $Server
                    RestartDuration = $Duration
                    RestartStatus = $RestartStatus
                    LBExist = $LBExist
                    LastLBStatus = $LastLBStatus
            
                    }
                
                }
            
            }
        Workflow Reset-IISServers {
            Param(
                [Parameter(Mandatory=$true)]
                [String[]]$Servers,
                [Parameter(Mandatory=$true)]
                [string]$LBPath,
                [Parameter(Mandatory=$true)]
                [int32]$LBWSeconds,
                [Parameter(Mandatory=$true)]
                [int32]$ThrottleLimit,
                [Parameter(Mandatory=$true)]
                [string[]]$WebApplications


            )
                Foreach -Parallel -throttlelimit $ThrottleLimit ($Server in $Servers){
                    Write-Verbose "[$(Get-date -Format G)]IISreset operation started on $Server"
                    $Start = Get-Date
                    $LBExist = Test-Path -path $LBPath -PSComputerName $Server
                    if ($LBExist) {
                        Set-content -Value 'RUNNING' -Path $LBPath -PSComputerName $Server -Verbose:$false
                        Write-Verbose "Set the content to 'RUNNING' on $Server. Sleeping $LBWseconds seconds."
                        Start-Sleep -Seconds $LBWSeconds
                    }
                    
                    try {
                   
                        InlineScript {
                    
                            Invoke-Expression 'iisreset.exe /noforce | Out-Null'
                        
                        } -PSComputerName $server -ErrorAction Stop
                        Write-Verbose "IISReset completed on $Server"
                        $ResetStatus = $true
                       
                    }
                    catch {
                        $ResetStatus = $_.ErrorRecord
                        Write-Verbose "IIS reset failed due to error: $($_.Exception.Message)"
                    }
                   
                    # get web applications status and set $WebAppStat to $true
                    
                    $WebApplicationStatus = InlineScript {

                        Set-Location $PSHOME
                        Import-Module WebAdministration -Verbose:$false

                    Write-verbose "Working on web applications: $($Using:WebApplications -join ',')"
                        $WebApplicationState =  Foreach ($WebApplication in $using:WebApplications) {
                        Write-verbose "Getting status of $WebApplication"
                        Try {
                        $WebApplicationIntance = Get-WebApplication -Name $WebApplication -ErrorAction Stop
                        $WebAppPool = $WebApplicationIntance.ApplicationPool
                        
                        $status = (Get-WebAppPoolState -Name  $WebAppPool -ErrorAction Stop).Value
                        Write-Verbose "$WebAppool is the application pool of $($WebApplicationIntance.Name) and its state is $Status"
                        }
                        
                        Catch {

                            $Status = 'Missing'

                        }
                        Finally {
                        [PSCustomObject]@{
                        WebApplication = $WebApplication
                        Status = $Status
                        }
                        }
                    }
                        -Not($WebApplicationState.Status -contains 'stopped')    

                    } -PSComputerName $server

                    Write-Verbose "WebApplications Health on $Server is $WebApplicationStatus"
                    # add to load balancer if all web applications are started    
                    if ($LBExist -and $WebApplicationStatus) {
                        Set-content -Value 'RUNNING!' -Path $LBPath -PSComputerName $Server -Verbose:$false
                        $LastLBStatus = Get-Content -Path $LBPath -PSComputerName $Server
                    
                    } else {

                        $LastLBStatus = Get-Content -Path $LBPath -PSComputerName $Server

                    }
                    
                    $Duration = inlinescript {
                        [Math]::Round(((Get-Date) - $Using:Start).TotalSeconds)
                    }
                    [PSCustomObject]@{
                        
                        ServerName = $Server
                        IISResetDuration = $Duration
                        IISResetStatus  = $ResetStatus
                        LBExist = $LBExist
                        LastLBStatus = $LastLBStatus
                        LBAdded = $WebApplicationStatus
                
                        }
                    
                    }
                
                }
#region Main

        $Inventory = Import-PowerShellDataFile -Path $InventoryPath
    
    Foreach  ($Role in $Roles)
    {
        Write-Verbose -Message "Working on $Role"
        $Servers  = Get-Servers -Inventory $Inventory -Role $Role -Location $Location
        $WebApplications = Get-WebApplications -Role $Role -Inventory $Inventory
        Switch ($Operation) 
        {
        'HealthCheckOnly'   {
                                Write-verbose "[$(Get-Date -Format G)]Starting HealthCheckOnly Mode for $($Servers.Count) servers."
                                Test-Servers -Inventory $Inventory -Servers $Servers -ThrottleLimit $ThrottleLimit -Role $Role -LBPAth $LBPath | Select-Object -Property ServerName, @{Name = 'Reachable';Expression={if($_.Reachable -eq 0){$True} else {$_.Reachable}}},MissingServices,RunningServices,StoppedServices,LBConfigured,LBState,WebApplications,MissingWebApplications,StoppedWebApplications,Date  #| Format-Table -AutoSize
                            }
        'Restart'           {
                                Write-verbose "[$(Get-Date -Format G)]Starting Restart Mode for $($Servers.Count) servers."
                                Write-OutPut "------------------------------------`nRestart Summary`n------------------------------------`n"
                                Restart-Servers -Servers $Servers -LBPath $LBPath -LBWSeconds $LBWSeconds -ThrottleLimit $ThrottleLimit | Select-Object -Property ServerName,RestartDuration,RestartStatus,LBExist,LastLBStatus | Format-Table -AutoSize
                                Write-OutPut "------------------------------------`nHelthcheck Summary`n------------------------------------`n"
                                Test-Servers -Inventory $Inventory -Servers $Servers -ThrottleLimit $ThrottleLimit -Role $Role -LBPAth $LBPath | Select-Object -Property ServerName, @{Name = 'Reachable';Expression={if($_.Reachable -eq 0){$True} else {$_.Reachable}}},MissingServices,RunningServices,StoppedServices,LBConfigured,LBState,Date | Format-Table -AutoSize
                                Write-verbose "[$(Get-Date -Format G)]Ended IISReset Mode for $($Servers.Count) servers."
                            }
        'IISReset'          {

                                Write-verbose "[$(Get-Date -Format G)]Starting IISReset Mode for $($Servers.Count) servers."
                                Write-OutPut "------------------------------------`nIISReset Summary`n------------------------------------`n"
                                Reset-IISServers -Servers $Servers -LBPath $LBPath -LBWSeconds $LBWSeconds -ThrottleLimit $ThrottleLimit -WebApplications $WebApplications | Select-Object -Property ServerName,LBAdded,IISResetDuration,IISResetStatus,LBExist,LastLBStatus | Format-Table -AutoSize
                                Write-OutPut "------------------------------------`nHelthcheck Summary`n------------------------------------`n"
                                Test-Servers -Inventory $Inventory -Servers $Servers -ThrottleLimit $ThrottleLimit -Role $Role -LBPAth $LBPath | Select-Object -Property ServerName, @{Name = 'Reachable';Expression={if($_.Reachable -eq 0){$True} else {$_.Reachable}}},MissingServices,RunningServices,StoppedServices,LBConfigured,LBState,WebApplications,MissingWebApplications,StoppedWebApplications,Date | Format-Table -AutoSize
                                Write-verbose "[$(Get-Date -Format G)]Ended IISReset Mode for $($Servers.Count) servers."

                            }
        }
    }
#endregion Main


        
}
