#using System.Runtime.Caching.MemoryCache

$script:AnsibleUrl = $null;
$script:TowerApiUrl = $null;
$script:AnsibleCredential = $null;

#Dot-source/Load the other powershell scripts
#Get-ChildItem "*.ps1" -path $PSScriptRoot | Where-Object {$_.Name -notmatch "tests|Build|Default"} |  ForEach-Object { . $_.FullName }
. $PSScriptRoot\M3Helper.AnsibleTower.class.ps1
Get-ChildItem "*.ps1" -Path $PSScriptRoot/InternalFunctions | Where-Object {$_.Name -notmatch "tests"} |  ForEach-Object { . $_.FullName }
Get-ChildItem "*.ps1" -Path $PSScriptRoot/ExportedFunctions | Where-Object {$_.Name -notmatch "tests"} |  ForEach-Object { . $_.FullName }

Add-Type -AssemblyName System.Runtime.Caching
$Script:CachePolicy = New-Object System.Runtime.Caching.CacheItemPolicy -Property @{
    SlidingExpiration = [System.Timespan]"0:02:00"
}

function Disable-CertificateVerification {
    <#
    .SYNOPSIS
    Disables Certificate verification. Use this when using Tower with 'troublesome' certificates, such as self-signed.
    #>

    # Danm you here-strings for messing up my indendation!!
    Add-Type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;

    public class NoSSLCheckPolicy : ICertificatePolicy {
        public NoSSLCheckPolicy() {}
        public bool CheckValidationResult(
            ServicePoint sPoint, X509Certificate cert,
            WebRequest wRequest, int certProb) {
            return true;
        }
    }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = new-object NoSSLCheckPolicy
}

function Join-AnsibleUrl {
    <#
    .SYNOPSIS
    Joins url parts together into a valid Tower url.

    .PARAMETER Parts
    Url parts that will be joined together.

    .EXAMPLE
    Join-AnsibleUrl 'https://tower.domain.com','api','v1','job_templates'

    .OUTPUTS
    Combined url with a trailing slash.
    #>
    param(
        [string[]]$Parts
    )

    $AnsibleUrl = (($Parts | Where-Object { $_ } | ForEach-Object { $_.trim('/').trim() } | Where-Object { $_ }) -join '/') + '/'
    return $AnsibleUrl
}

function Get-AnsibleResourceUrl {
    <#
    .SYNOPSIS
    Gets the url part for a Tower API resource of function.

    .PARAMETER Resource
    The resource name to get the API url for.

    .EXAMPLE
    Get-AnsibleResourceUrl 'job_templates'
    Returns: "/api/v1/job_templates/"

    .OUTPUTS
    API url part for the specified resource, e.g. "/api/v1/job_templates/"
    #>
    #[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "Global:DefaultAnsibleTower")]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Resource,

        $AnsibleTower = $Global:DefaultAnsibleTower
    )

    $result = $AnsibleTower.Endpoints

    if (!$result) {
        throw "Failed to access the Tower api list";
    }
    if (!$result.$Resource) {
        throw ("Failed to find the url for resource [{0}]" -f $Resource);
    }

    return $result.$Resource;
}

function Invoke-GetAnsibleInternalJsonResult {
    #[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "Global:DefaultAnsibleTower")]
    param(
        [Parameter(Mandatory = $true)]
        $ItemType,

        $Id,
        $ItemSubItem,

        $Filter = @{},

        [Int32]$MaxResults = [Int32]::MaxValue,

        $AnsibleTower = $Global:DefaultAnsibleTower
    )

    $me = Test-AnsibleTower -AnsibleTower $AnsibleTower
    if (!$me) {
        throw "You need to connect first, use Connect-AnsibleTower";
    }

    $ItemApiUrl = Get-AnsibleResourceUrl $ItemType -AnsibleTower $AnsibleTower

    if ($id) {
        $ItemApiUrl = Join-AnsibleUrl $ItemApiUrl, $id
    }

    if ($ItemSubItem) {
        $ItemApiUrl = Join-AnsibleUrl $ItemApiUrl, $ItemSubItem
    }

    $RemainingResults = $MaxResults

    Write-Verbose ("Invoke-GetAnsibleInternalJsonResult: Invoking url [{0}]" -f $ItemApiUrl);
    #    $invokeResult = Invoke-AnsibleRequest -FullPath $ItemApiUrl -AnsibleTower $AnsibleTower -QueryParameters $Filter
    do {
        $invokeResult = Invoke-AnsibleRequest -FullPath $ItemApiUrl -AnsibleTower $AnsibleTower -QueryParameters $Filter
        if ($invokeResult.id) {
            Write-Output $invokeResult
        }
        elseif ($invokeResult.results) {
            if ($InvokeResult.Results.Count -gt $RemainingResults) {
                $InvokeResult.Results | Select-Object -First $RemainingResults
            }
            else {
                $InvokeResult.Results
            }
            $RemainingResults -= $InvokeResult.Results.Count
        }
        $ItemApiUrl = $InvokeResult.Next
        #Don't add filter query string after the first run
        $Filter = @{}
    } while ($ItemApiUrl -and $RemainingResults -gt 0)
}

Function Invoke-PostAnsibleInternalJsonResult {
    #[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "Global:DefaultAnsibleTower")]
    param(
        [Parameter(Mandatory = $true)]
        $ItemType,

        $itemId,
        $ItemSubItem,
        $InputObject,

        $AnsibleTower = $Global:DefaultAnsibleTower
    )
    $me = Test-AnsibleTower -AnsibleTower $AnsibleTower
    if (!$me) {
        throw "You need to connect first, use Connect-AnsibleTower";
    }

    $ItemApiUrl = Get-AnsibleResourceUrl $ItemType -AnsibleTower $AnsibleTower

    if ($itemId) {
        $ItemApiUrl = Join-AnsibleUrl $ItemApiUrl, $itemId
    }

    if ($ItemSubItem) {
        $ItemApiUrl = Join-AnsibleUrl $ItemApiUrl, $ItemSubItem
    }
    $Body = @{ }
    if ($InputObject) {
        $Body["Body"] = $InputObject | ConvertTo-Json -Depth 99
    }

    Write-Verbose ("Invoke-PostAnsibleInternalJsonResult: Invoking url [{0}]" -f $params.Uri);
    Invoke-AnsibleRequest -FullPath $ItemApiUrl -AnsibleTower $AnsibleTower -Method POST @Body
    #return Invoke-RestMethod @params
}

Function Invoke-PutAnsibleInternalJsonResult {
    Param (
        [Parameter(mandatory = $true)]
        $ItemType,

        [Parameter(mandatory = $true)]
        $InputObject,

        [Parameter(mandatory = $true)]
        $AnsibleTower
    )

    $me = Test-AnsibleTower -AnsibleTower $AnsibleTower
    if (!$me) {
        throw "You need to connect first, use Connect-AnsibleTower";
    }
    $ItemApiUrl = Get-AnsibleResourceUrl $ItemType  -AnsibleTower $AnsibleTower

    $id = $InputObject.id

    $ItemApiUrl = Join-AnsibleUrl $ItemApiUrl, $id

    $Request = @{
        FullPath       = $ItemApiUrl
        Method         = "PUT"
        #Body = [Newtonsoft.Json.JsonConvert]::SerializeObject($InputObject)
        $AnsibleObject = [System.Web.Script.Serialization.JavaScriptSerializer]::new().Serialize($InputObject)
        
        AnsibleTower   = $AnsibleTower
    }
    return Invoke-AnsibleRequest @Request
}

function Invoke-AnsibleRequest {
    [CmdletBinding()]
    #[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "Global:DefaultAnsibleTower")]
    param(
        $AnsibleTower = $Global:DefaultAnsibleTower,
        [Parameter(ParameterSetName = "relpath")]
        $RelPath,
        [Parameter(ParameterSetName = "fullpath")]
        $FullPath,
        $Method = "GET",
        [HashTable]$QueryParameters,
        $Body,
        $ContentType = "application/json"
    )
    if ($PSBoundParameters.ContainsKey("RelPath")) {
        $Uri = Join-AnsibleUrl $AnsibleTower.TowerApiUrl, $RelPath
    }
    if ($PSBoundParameters.ContainsKey("FullPath")) {
        $Uri = $AnsibleTower.AnsibleUrl.TrimEnd("/") + "/" + $FullPath.TrimStart("/")
    }
    if ($PSBoundParameters.ContainsKey("QueryParameters") -and $QueryParameters.Count -gt 0) {
        $QueryString = [System.Web.HttpUtility]::ParseQueryString("")
        $QueryParameters.Keys | ForEach-Object {
            $QueryString.Add($_, $QueryParameters[$_])
        }
        $Uri = $Uri + "?" + $QueryString.ToString()
    }
    $Headers = @{
        "Authorization" = "Bearer $($AnsibleTower.Token.access_token)"
    }
    $IRMArgs = @{ }
    if ($PSBoundParameters.ContainsKey("Body")) {
        $IRMARgs["Body"] = $Body
    }
    Invoke-RestMethod -Method $Method -Uri $Uri -ContentType $ContentType -Headers $Headers @IRMArgs
}

function Test-AnsibleTower {
    [CmdletBinding()]
    #[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "Global:DefaultAnsibleTower")]
    param(
        $AnsibleTower = $Global:DefaultAnsibleTower
    )
    if ($AnsibleTower.TokenExpiration.AddMinutes(30) -lt [DateTime]::Now) {
        #Renew
    }
    else {
        if (!$AnsibleTower.Me) {
            $meResult = Invoke-AnsibleRequest -AnsibleTower $AnsibleTower -RelPath 'me'
            if (!$meResult -or !$meResult.results) {
                throw "Could not authenticate to Tower";
            }
            #$AnsibleTower.Me = [AnsibleTower.JsonFunctions]::ParseToUser((ConvertTo-Json ($meResult.results | Select-Object -First 1)));
            $serializer = [System.Web.Script.Serialization.JavaScriptSerializer]::new()
            $AnsibleTower.Me = $serializer.Deserialize((ConvertTo-Json ($meResult.results | Select-Object -First 1)), [User])
        }
    }

    $AnsibleTower.Me
}

function Connect-AnsibleTower {
    <#
    .SYNOPSIS
    Connects to the Tower API and returns the user details.

    .PARAMETER Credential
    Credential to authenticate with at the Tower API.

    .PARAMETER TowerUrl
    Url of the Tower host, e.g. https://ansible.mydomain.local

    .PARAMETER DisableCertificateVerification
    Disables Certificate verification. Use when Tower responds with 'troublesome' certificates, such as self-signed.

    .EXAMPLE
    Connect-AnsibleTower -Credential (Get-Credential) -TowerUrl 'https://ansible.domain.local'

    User is prompted for credentials and then connects to the Tower host at 'https://ansible.domain.local'. User details are displayed in the output.

    .EXAMPLE
    $me = Connect-AnsibleTower -Credential $myCredential -TowerUrl 'https://ansible.domain.local' -DisableCertificateVerification

    Connects to the Tower host at 'https://ansible.domain.local' using the credential supplied in $myCredential. Any certificate errors are ignored.
    User details beloning to the specified credential are in the $me variable.
    #>
    #[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "Global:DefaultAnsibleTower")]
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Credential()]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $true)]
        [string]$TowerUrl,

        [Parameter(Mandatory = $true)]
        [string]$Authorization,

        [Switch]$DisableCertificateVerification
    )

    if ($DisableCertificateVerification) {
        Disable-CertificateVerification;
    }

    if ($TowerUrl -match "/api") {
        throw "Specify the URL without the /api part"
    }

    try {
        Write-Verbose "Determining current Tower API version url..."
        $TestUrl = Join-AnsibleUrl $TowerUrl, 'api'
        Write-Verbose "TestUrl=$TestUrl"
        $result = Invoke-RestMethod -Uri $TestUrl -ErrorAction Stop
        if (!$result.current_version) {
            throw "Could not determine current version of Tower API";
        }
        $TowerApiUrl = Join-AnsibleUrl $TowerUrl, $result.current_version
    }
    catch {
        throw ("Could not connect to Tower api url: " + $_.Exception.Message);
    }


    $PATUri = Join-AnsibleUrl $TowerApiUrl, 'users', $Credential.Username, 'personal_tokens'
    #$Authorization = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Credential.Username):$($Credential.GetNetworkCredential().Password)"))
    $Body = @{
        description = "AnsibleTower-Powershell"
        application = $null
        scope       = "write"
    }
    Write-Verbose "Logging in to Tower..."
    try {
        $Response = Invoke-RestMethod -Uri $PATUri -Method POST -Headers @{ Authorization = "Basic $Authorization" } -ContentType "application/json" -Body (ConvertTo-Json $Body)
        #$Token = New-Object AnsibleTower.Token -Property @{
        $Token = New-Object Token -Property @{
            access_token = $Response.Token
            token_type   = $Response.Type
            scope        = $Response.Scope
        }
        #$Tower = New-Object AnsibleTower.Tower -Property @{
        $Tower = New-Object Tower -Property @{
            AnsibleUrl      = $TowerUrl
            TowerApiUrl     = $TowerApiUrl
            Token           = [PSObject]$Token
            TokenExpiration = [DateTime]$Response.Expires
            Endpoints       = @{}
            Me              = $null
        }
        $Tower.Me = Test-AnsibleTower -AnsibleTower $Tower
        $Endpoints = Invoke-AnsibleRequest -RelPath "/" -AnsibleTower $Tower
        $Endpoints | Get-Member -MemberType NoteProperty | ForEach-object {
            $Tower.Endpoints.Add($_.Name, $Endpoints."$($_.Name)")
        }
        #TODO: if ! -notdefault
        #[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
        $Global:DefaultAnsibleTower = $Tower
    }
    catch {
        Write-Error -Message ("Could not authenticate: " + $_.Exception.Message) -Exception $_.Exception
    }

    # Connection and login success.

    $script:AnsibleUrl = $TowerUrl;
    $script:TowerApiUrl = $TowerApiUrl;
    $script:AnsibleCredential = $Credential;

    return $Tower;
}