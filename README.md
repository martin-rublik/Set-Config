# Set-Config
Quick'n'dirty way to edit XML config (e.g. Web.Config and Application.config) files.

## Installation
```powershell
Install-Module Set-Config
```

## Examples

### Example 1: Setting a certificate thumbprint in Web.config
```powershell
Set-Config -ConfigFileName web.config -XPath "/configuration/system.serviceModel/behaviors/serviceBehaviors/behavior/serviceCredentials/serviceCertificate" -Attribute "findValue" -Value "E483FA9FFA42F000A366773DD124CE532C31BC68"
```

### Example 2: Setting a certificate thumbprint in Web.config
```powershell
Set-Config -ConfigFileName web.config -XPath '/configuration/appSettings/add[@key="FileLogLevel"]' -Attribute "findValue" -Value "4"
```

### Example 3: Silent usage
```powershell
Set-Config -Confirm:$false -ConfigFileName web.config -XPath '/configuration/appSettings/add[@key="FileLogLevel"]' -Attribute "findValue" -Value "4"
```

## More information
Editing XML config files with powershell [blog post](https://martin.rublik.eu/2024/04/22/editing-XML-files.html).


