function Get-AnsibleInventory {
    <#
.DESCRIPTION
Gets inventories defined in Ansible Tower.

.PARAMETER Description
Optional description of this inventory.

.PARAMETER HasActiveFailures
Flag indicating whether any hosts in this inventory have failed.

.PARAMETER HasInventorySources
Flag indicating whether this inventory has any external inventory sources.

.PARAMETER HostFilter
Filter that will be applied to the hosts of this inventory.

.PARAMETER InsightsCredential
Credentials to be used by hosts belonging to this inventory when accessing Red Hat Insights API.

.PARAMETER Kind
Kind of inventory being represented.

.PARAMETER Name
Name of this inventory.

.PARAMETER Organization
Organization containing this inventory.

.PARAMETER PendingDeletion
Flag indicating the inventory is being deleted.

.PARAMETER Variables
Inventory variables in JSON or YAML format.

.PARAMETER Id
The ID of a specific AnsibleInventory to get

.PARAMETER AnsibleTower
The Ansible Tower instance to run against.  If no value is passed the command will run against $Global:DefaultAnsibleTower.
#>
    [CmdletBinding(DefaultParameterSetname = 'PropertyFilter')]
    #[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "Global:DefaultAnsibleTower")]
    #[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "InsightsCredential")]
    param(
        [Parameter(Position = 2, ParameterSetName = 'PropertyFilter')]
        [String]$Description,

        [Parameter(ParameterSetName = 'PropertyFilter')]
        [switch]$HasActiveFailures,

        [Parameter(ParameterSetName = 'PropertyFilter')]
        [switch]$HasInventorySources,

        [Parameter(ParameterSetName = 'PropertyFilter')]
        [String]$HostFilter,

        [Parameter(ParameterSetName = 'PropertyFilter')]
        [Object]$InsightsCredential,

        [Parameter(ParameterSetName = 'PropertyFilter')]
        [ValidateSet('', 'smart')]
        [string]$Kind,

        [Parameter(Position = 1, ParameterSetName = 'PropertyFilter')]
        [String]$Name,

        [Parameter(Position = 3, ParameterSetName = 'PropertyFilter')]
        [Object]$Organization,

        [Parameter(ParameterSetName = 'PropertyFilter')]
        [switch]$PendingDeletion,

        [Parameter(ParameterSetName = 'PropertyFilter')]
        [String]$Variables,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ById')]
        [Int32]$Id,

        [Parameter(ParameterSetName = 'ById')]
        [Switch]$UseCache,

        $AnsibleTower = $Global:DefaultAnsibleTower
    )
    process {
        $Filter = @{}
        if ($PSBoundParameters.ContainsKey("Description")) {
            if ($Description.Contains("*")) {
                $Filter["description__iregex"] = $Description.Replace("*", ".*")
            }
            else {
                $Filter["description"] = $Description
            }
        }

        if ($PSBoundParameters.ContainsKey("HasActiveFailures")) {
            $Filter["has_active_failures"] = $HasActiveFailures
        }

        if ($PSBoundParameters.ContainsKey("HasInventorySources")) {
            $Filter["has_inventory_sources"] = $HasInventorySources
        }

        if ($PSBoundParameters.ContainsKey("HostFilter")) {
            if ($HostFilter.Contains("*")) {
                $Filter["host_filter__iregex"] = $HostFilter.Replace("*", ".*")
            }
            else {
                $Filter["host_filter"] = $HostFilter
            }
        }

        if ($PSBoundParameters.ContainsKey("InsightsCredential")) {
            switch ($InsightsCredential.GetType().Fullname) {
                "AnsibleTower.InsightsCredential" {
                    $Filter["insights_credential"] = $InsightsCredential.Id
                }
                "System.Int32" {
                    $Filter["insights_credential"] = $InsightsCredential
                }
                "System.String" {
                    $Filter["insights_credential__name"] = $InsightsCredential
                }
                default {
                    Write-Error "Unknown type passed as -InsightsCredential ($_).  Supported values are String, Int32, and AnsibleTower.InsightsCredential." -ErrorAction Stop
                    return
                }
            }
        }

        if ($PSBoundParameters.ContainsKey("Kind")) {
            if ($Kind.Contains("*")) {
                $Filter["kind__iregex"] = $Kind.Replace("*", ".*")
            }
            else {
                $Filter["kind"] = $Kind
            }
        }

        if ($PSBoundParameters.ContainsKey("Name")) {
            if ($Name.Contains("*")) {
                $Filter["name__iregex"] = $Name.Replace("*", ".*")
            }
            else {
                $Filter["name"] = $Name
            }
        }

        if ($PSBoundParameters.ContainsKey("Organization")) {
            switch ($Organization.GetType().Fullname) {
                "AnsibleTower.Organization" {
                    $Filter["organization"] = $Organization.Id
                }
                "System.Int32" {
                    $Filter["organization"] = $Organization
                }
                "System.String" {
                    $Filter["organization__name"] = $Organization
                }
                default {
                    Write-Error "Unknown type passed as -Organization ($_).  Supported values are String, Int32, and AnsibleTower.Organization." -ErrorAction Stop
                    return
                }
            }
        }

        if ($PSBoundParameters.ContainsKey("PendingDeletion")) {
            $Filter["pending_deletion"] = $PendingDeletion
        }

        if ($PSBoundParameters.ContainsKey("Variables")) {
            if ($Variables.Contains("*")) {
                $Filter["variables__iregex"] = $Variables.Replace("*", ".*")
            }
            else {
                $Filter["variables"] = $Variables
            }
        }

        if ($id) {
            $CacheKey = "inventory/$Id"
            $AnsibleObject = $AnsibleTower.Cache.Get($CacheKey)
            if ($UseCache -and $AnsibleObject) {
                Write-Debug "[Get-AnsibleInventory] Returning $($AnsibleObject.Url) from cache"
                $AnsibleObject
            }
            else {
                Invoke-GetAnsibleInternalJsonResult -ItemType "inventory" -Id $Id -AnsibleTower $AnsibleTower | ConvertToInventory -AnsibleTower $AnsibleTower
            }
        }
        else {
            Invoke-GetAnsibleInternalJsonResult -ItemType "inventory" -Filter $Filter -AnsibleTower $AnsibleTower | ConvertToInventory -AnsibleTower $AnsibleTower
        }
    }
}

function AddInventoryGroups {
    param(
        $Inventory
    )
    $Groups = Invoke-GetAnsibleInternalJsonResult -ItemType "inventory" -Id $Inventory.Id -ItemSubItem "groups" -AnsibleTower $Inventory.AnsibleTower
    #$Inventory.Groups = New-Object "System.Collections.Generic.List[Group]"
    $Inventory.Groups = @{}
    foreach ($Group in $Groups) {
        $GroupObj = Get-AnsibleGroup -Id $Group.Id -AnsibleTower $Inventory.AnsibleTower -UseCache
        $Inventory.Groups.Add($GroupObj.id, $GroupObj)
    }
    $Inventory
}

function ConvertToInventory {
    param(
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        $InputObject,

        [Parameter(Mandatory = $true)]
        $AnsibleTower
    )
    process {
        #$JsonString = ConvertTo-Json $InputObject
        #$AnsibleObject = [AnsibleTower.JsonFunctions]::ParseToinventory($JsonString)
        $serializer = [System.Web.Script.Serialization.JavaScriptSerializer]::new()
        $AnsibleObject = $serializer.Deserialize((ConvertTo-Json ($InputObject)), [Inventory])
        $AnsibleObject.AnsibleTower = $AnsibleTower
        $CacheKey = "inventory/$($AnsibleObject.Id)"
        Write-Debug "[Get-AnsibleInventory] Caching $($AnsibleObject.Url) as $CacheKey"
        $AnsibleTower.Cache.Add($CacheKey, $AnsibleObject, $Script:CachePolicy) > $null
        #Add to cache before filling in child objects to prevent recursive loop
        $AnsibleObject = AddInventoryGroups $AnsibleObject
        Write-Debug "[Get-AnsibleInventory] Returning $($AnsibleObject.Url)"
        $AnsibleObject
    }
}