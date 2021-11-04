# Restart Servers
Performs restrart, IISReset or Only Healtcheck for all the servers in a sepcific location based on the role specified.  


# Table of Contents

- [Parameters Explained](#Parameters%20Explaiened)
- [Release Notes](#Release%20Notes)
- [Examples](#Examples)
- [Future Improvements](#Future%20Improvements)

# Parameters Explained
- InventoryPath: The Inventory database which is a psd1 file.
- Roles: Please specify the roles in Nonenode section in the PSD1 file specified in the InventoryPath - to perfom the operation.
- Location: Can be 'PROD' or 'ODM'
- Operation: Can be one of the followings. 'IISReset','Restart','HealthCheckOnly'
- LBWSeconds: Defaults to 60. This the Wait seconds after updating the load balancer configuration
- LBPath: Loadbalencer Config file defaults to 'c:\Inetpub\wwwroot\lbcheck\lbcheck.html'
- ThrottleLimit: Specifies how many servers at a time the operation should be perfomed. Defaults to 5. 

# Release Notes
1. Performs the following operations based on the psd1 file specified in the ***InventoryPath*** Parameter
1. Performs the operations with the credential information of the user running the script. 
1. Runs Async (Parallel processing) and restarts servers in batches specified in the ***ThrottleLimit*** parameter
1. Healtcheck Operation is automatically performed after IISReset or Restart Operations
1. Healtcheckonly Option is also available any time.
1. To Perform the operations for specific servers rather then the inventory file contains roles create a seperate dummy psd1 file maintaining the structure like below

```Powershell

@{
    NonNodeData =
    @{
        Roles               = @{
            Uygulama = @{

                Services = @{
                    'W3SVC' = @{State = 'Running'; BuiltInAccount = 'LocalSystem'; StartupType = 'Automatic'}
                    'IISADMIN' = @{State = 'Running'; BuiltInAccount = 'LocalSystem'; StartupType = 'Automatic'}
                }

            }
            
        }    
    }

    AllNodes =
    @(
        @{
            NodeName    = 'emreg-dsc.contoso.com'
            Role        = 'UYGULAMA'
            Location    = 'PROD'
        },
        @{
            NodeName    = 'emreg-sma.contoso.com'
            Role        = 'UYGULAMA'
            Location    = 'PROD'
        },
        @{
            NodeName    = 'emreg-om16ms1.contoso.com'
            Role        = 'UYGULAMA'
            Location    = 'PROD'
        },
        @{
            NodeName    = 'dc.contoso.com'
            Role        = 'DC'
            Location    = 'PROD'
        }
        
    )
}



```
# Examples

You may find below 3 example usages and outputs. 

First Example is Healtcheckonly mode in the is mode script runs in parallel and gatthers information using the inventory psdfile.

LBConfigured: Checks if Loadbalancer file exists.
LBState: if the file exists wthat is the status. 
Reachable: Ping status for the serer. IF it is pingable then our state is true else it is the ping status error code. 

```Powershell
     .\Restart-Servers.ps1 -InventoryPath C:\Repos\RestartServers\Data\Test.psd1 -Roles Uygulama -Location PROD -Operation HealthCheckOnly -LBPath 'c:\Inetpub\wwwroot\lbcheck\lbcheck.html' -ThrottleLimit 2 

    ServerName                Reachable MissingServices RunningServices   StoppedServices LBConfigured LBState                                                                               Date                
    ----------                --------- --------------- ---------------   --------------- ------------ -------                                                                               ----                
    emreg-sma.contoso.com          True IISADMIN        W3SVC                                    False Cannot find path 'C:\Inetpub\wwwroot\lbcheck\lbcheck.html' because it does not exist. 1/15/2020 4:40:14 AM
    emreg-dsc.contoso.com          True IISADMIN                          W3SVC                  False Cannot find path 'C:\Inetpub\wwwroot\lbcheck\lbcheck.html' because it does not exist. 1/15/2020 4:40:14 AM
    emreg-om16ms1.contoso.com      True                 {IISADMIN, W3SVC}                         True RUNNING!                                                                              1/15/2020 4:40:14 AM
```
To restart servers 2 at a time throttle limit is used in this example and set to 2. After restart a healtcheck is automatically performed.

```Powershell
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
```
Following example is IISreset.

```Powershell
    
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

```


# Future Improvements
1. Runas credential support
1. Better reporting (possibly to sql server)
1. Implement -whatif support
1. Add website control support

