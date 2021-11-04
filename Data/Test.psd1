@{
    NonNodeData =
    @{
        Roles               = @{
            Uygulama = @{
                WindowsFeaturestoAdd = @("Web-Server","Web-WebServer","Web-Common-Http","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Redirect","Web-DAV-Publishing","Web-Health","Web-Http-Logging","Web-Custom-Logging","Web-Log-Libraries","Web-ODBC-Logging","Web-Request-Monitor","Web-Http-Tracing","Web-Performance","Web-Stat-Compression","Web-Dyn-Compression","Web-Security","Web-Filtering","Web-Basic-Auth","Web-CertProvider","Web-Client-Auth","Web-Digest-Auth","Web-Cert-Auth","Web-IP-Security","Web-Url-Auth","Web-Windows-Auth","Web-App-Dev","Web-Net-Ext","Web-Net-Ext45","Web-AppInit","Web-ASP","Web-Asp-Net","Web-Asp-Net45","Web-CGI","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Includes","Web-WebSockets","Web-Mgmt-Tools","Web-Mgmt-Console","Web-Mgmt-Compat","Web-Metabase","Web-Lgcy-Mgmt-Console","Web-Lgcy-Scripting","Web-WMI","Web-Scripting-Tools","Web-Mgmt-Service","NET-HTTP-Activation","NET-Non-HTTP-Activ","NET-Framework-45-ASPNET","NET-WCF-HTTP-Activation45","NET-WCF-MSMQ-Activation45","NET-WCF-Pipe-Activation45","NET-WCF-TCP-Activation45","MSMQ","MSMQ-Services","MSMQ-Server","MSMQ-Directory","MSMQ-HTTP-Support","MSMQ-Triggers","MSMQ-Multicasting","MSMQ-Routing","Windows-Defender-Features","Windows-Defender","Windows-Defender-Gui","WAS","WAS-Process-Model","WAS-NET-Environment","WAS-Config-APIs")
                WindowsFeaturestoRemove = @()
                Services = @{
                    'W3SVC' = @{State = 'Running'; BuiltInAccount = 'LocalSystem'; StartupType = 'Automatic'}
                    'IISADMIN' = @{State = 'Running'; BuiltInAccount = 'LocalSystem'; StartupType = 'Automatic'}
                }
                WebApplications = @('Test','test2','test3')
            }
            
        }    
    }

    AllNodes =
    @(
        @{
            NodeName    = 'emreg-web01.contoso.com'
            Role        = 'UYGULAMA'
            Location    = 'PROD'
        },
        @{
            NodeName    = 'emreg-web02.contoso.com'
            Role        = 'UYGULAMA'
            Location    = 'PROD'
        },
        @{
            NodeName    = 'emreg-web03.contoso.com'
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
