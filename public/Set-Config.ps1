function Set-Config
{
<#	
.SYNOPSIS
	Edit a XML config. 
 
.DESCRIPTION
	This script is used for editing attributes in XML docs. 

.PARAMETER ConfigFileName
	XML config file.
	
.PARAMETER XPath
	Element XPath string, currently supported only in following two forms:
	
	Simple e.g. /path/to/element
	Single key/value query e.g. /path/to/element[@key=value]		

.PARAMETER Attribute
	Attribute name

.PARAMETER Value
	Attribute value
	
.PARAMETER InnerText
	Inner element text

.EXAMPLE
	Set-Config -ConfigFileName web.config -XPath "/configuration/system.serviceModel/behaviors/serviceBehaviors/behavior/serviceCredentials/serviceCertificate" -Attribute "findValue" -Value "E483FA9FFA42F000A366773DD124CE532C31BC68"

	Changes the serviceCertificate thumbprint
	
.EXAMPLE
	Set-Config -ConfigFileName "C:\inetpub\WebTest\web.config" -XPath '/configuration/appSettings/add[@key="FederationMetadataLocation"]' -Attribute "value" -Value "https://someserver.com/MetaData"
	
	Changes metadata URI to https://someserver.com/MetaData
	
.NOTES   
	Author     : Martin Rublik (martin.rublik@bspc.sk)
	Created    : 03/31/2016
	Version    : 1.0

	
	Changelog:
	V 1.0 (2016-03-31) - intial version

	License:
	The MIT License (MIT)

	Copyright (c) 2016 Martin Rublik

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
#>
[cmdletbinding(ConfirmImpact = 'High', SupportsShouldProcess=$true)]
param(
	[Parameter(Mandatory=$true)]
    [string]$ConfigFileName,
	[Parameter(Mandatory=$true)][string]$XPath,
    [string]$Attribute,
    [string]$Value,
    [string]$InnerText
)

	$config = new-object System.Xml.XmlDocument
	try
	{
		$p = Resolve-Path -LiteralPath $ConfigFileName | select -ExpandProperty Path
        if ((-not $p)-or($p.Count -gt 1))
        {
            throw "Error identifying config file: $ConfigFileName"
        }
        $ConfigFileName=$p

        Write-Verbose "Loading: $ConfigFileName"
		$config.Load($ConfigFileName); 
		
		try
		{
			Write-Verbose "Editing: $XPath"
			
			$node = $config.SelectSingleNode($XPath);
			$originalXML = "N/A"
			if ($node -ne $null)
			{
				$originalXML = $node.OuterXML
			}
			
			# Check if node exists
			if ($node -eq $null)
			{
				Write-Warning "Element: $XPath does not exist, creating structure"
				try
				{
					# Create the node path					
					# https://stackoverflow.com/questions/1757065/java-splitting-a-comma-separated-string-but-ignoring-commas-in-quotes
					$nodes = $XPath -split '/(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)' | %{ if (-not [string]::IsNullOrEmpty($_.ToString().Trim())){$_}}
					$path = '/'
					$nodes | foreach {
						$nextElement = $_;
						
						$nextPath=$path+$nextElement;
						
						# // is not valid XPath
						if ($nextPath.ToString().Equals('//'))
						{
							$path=$nextPath;
							# break;
							return;
						}
						
						$currNode=$null
						Write-Verbose "Selecting $nextPath"						
						$currNode=$config.SelectSingleNode($nextPath);
						if ($currNode -eq $null)
						{
							
                            if ($path -ne '/')
                            {
                                $path=$path.TrimEnd('/');
                            }

							$currNode = $config.SelectSingleNode($path);
							
							# process $nextElement parse [@key=value]
							$attr=$null
							$val=$null
							
							if ($nextElement.IndexOf('[') -ge 0)
							{
								$attrVal=$nextElement.Substring($nextElement.IndexOf('['));
								if (!$attrVal.EndsWith(']'))
								{
									throw "Incorrect key value $attrVal! Missing ']'";
								}
								# remove []
								$attrVal=$attrVal.TrimStart('[').TrimEnd(']');
								
								if (! $attrVal.StartsWith('@'))
								{
									throw "Incorrect key value $attrVal! Missing '@'";
								}
								# remove @
								$attrVal=$attrVal.Trim('@')
								# split	
								$attr=$attrVal.Split("=",2)[0];

								if ($attrVal.IndexOf('=') -ge 0)
								{
									$val=$attrVal.Split("=",2)[1];
									
									# trim ' or "
									if ($val.StartsWith("'"))
									{
										if (!$val.EndsWith("'"))
										{
											throw "Incorrect value $attrVal! Missing '";
										}
										$val=$val.Trim("'");
									}else
									{
										if ($val.StartsWith('"'))
										{
											if (!$val.EndsWith('"'))
											{
												throw "Incorrect value $attrVal!";
											}
											$val=$val.Trim('"');
										}else
										{
											throw "Incorrect value $attrVal!"
										}									
									}									
								}
								
								$nextElement=$nextElement.Remove($nextElement.IndexOf('['));
							}
							
							Write-Verbose "Creating element: $nextElement @ $path";							
							$childNode = $config.CreateNode("element",$nextElement,"");							
							if ($attr -ne $null)
							{
								$xmlAttribute = $config.CreateAttribute($attr);
								if ($val -ne $null)
								{
									$xmlAttribute.Value = $val;
								}
								Write-Verbose "Appending attribute $attr with value $val";
								$childNode.Attributes.Append($xmlAttribute) | Out-Null
							}
							$currNode.AppendChild($childNode) | Out-Null
							
						}
						$path=$nextPath+'/';
					}
				
				}catch
				{	
					throw "Error creating $XPath structure. "+$_.Exception.Message
				}
			}
			
			$node = $config.SelectSingleNode($XPath);

			# Check if attribute exists
			if (![string]::IsNullOrEmpty($Attribute))
			{
				if ( $node.$Attribute -eq $null)
				{
					Write-Verbose "Creating attribute: $Attribute @ $XPath";
					$xmlAttribute = $config.CreateAttribute($Attribute);

					$node.Attributes.Append($xmlAttribute) | Out-Null
				}
				# Set the value
				Write-Verbose "Setting $Attribute to $Value @ $XPath"
				$config.SelectSingleNode($XPath).$Attribute=$Value
			}
			
			if (![string]::IsNullOrEmpty($InnerText))
			{
				Write-Verbose "Setting InnerText to $InnerText @ $XPath"
				$config.SelectSingleNode($XPath).InnerText=$InnerText
			}
			
			try
			{
				if ($PSCmdlet.ShouldProcess("$ConfigFileName","Save/Overwrite"))
				{
					Write-Verbose "Saving $ConfigFileName"
					$config.Save($ConfigFileName)
				}else
				{
					Write-Host "What if: --- original value ---"
					Write-Host "What if: $($originalXML)"
					Write-Host "What if: --- is about to be changed to ---"
					Write-Host "What if: $($config.SelectSingleNode($XPath).OuterXML)"
					Write-Host "What if: ---"
					Write-Host "What if: Saving $ConfigFileName..."
				}
			}catch
			{
				throw "Error saving $ConfigFileName"
			}

		}catch
		{
			throw $_.Exception
		}

	}catch
	{
		throw $_.Exception
	}
}