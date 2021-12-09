#using System.Runtime.Caching.MemoryCache
using namespace System.Runtime.Caching

class Tower {
    Tower() {
        Write-Verbose "New instance Tower class..."
        $this.Endpoints = @{}
        $this.Cache = New-Object System.Runtime.Caching.MemoryCache("AnsibleTower")
    }

    [string]$AnsibleUrl
    [string]$TowerApiUrl
    #[Token]$Token
    [PSObject]$Token
    [DateTime]$TokenExpiration
    [User]$Me
    [Hashtable]$Endpoints
    [string]ToString() {
        try {
            return (New-Object System.Uri ($this.AnsibleUrl)).Authority
        }
        catch {
            return "";
        }
    }
    #[System.Runtime.Caching.MemoryCache]$Cache
    $Cache
}

class User {
    User() {
        Write-Verbose "New instance User class..."
    }

    [int] $id
    [string] $type
    [string] $url
    [string] $username
    [string] $first_name
    [string] $last_name
    [string] $email
    [bool] $is_superuser
    [bool] $is_system_auditor
    [string] $ldap_dn
    [string] $external_account
    [DateTime] $created
    [Tower]$AnsibleTower
}

class Organization {
    [int] $id
    [string] $type
    [string] $url
    [DateTime] $created
    [DateTime] $modified
    [string] $name
    [string] $description
    [Tower] $AnsibleTower

    [string] ToString() {
        return $this.name
    }
}

class Token {
    [string] $access_token
    [string] $token_type
    [Int64] $expires_in
    [string] $refresh_token
    [string] $scope
}

class JobTemplate {
    [int] $id
    [string] $name
    [string] $type 
    [string] $url
    [DateTime] $created
    [string] $description
    [string] $job_type
    [object] $inventory
    [object] $project
    [string] $playbook
    [object] $credential
    [object] $cloud_credential
    [int] $forks
    [string] $limit
    [int] $verbosity
    [string] $extra_vars
    [string] $job_tags
    [string] $host_config_key
    [bool] $ask_variables_on_launch
    [Tower] $AnsibleTower
}

class Job {
    [int] $id
    [string] $type
    [string] $url
    [Tower] $AnsibleTower
    [string] $controller_node
    [DateTime] $created
    [string] $description
    [double] $elapsed
    [string] $execution_node
    [string] $extra_vars
    [bool] $failed
    [DateTime] $finished
    [int] $forks
    [object] $instance_group
    [object] $inventory
    [string] $job_explanation
    [string] $job_tags
    [object] $job_template
    [string] $job_type
    [string] $launch_type
    [string] $limit
    [string] $name
    [string] $playbook
    [object] $project
    [string] $result_stdout
    [string] $scm_revision
    [string] $skip_tags
    [DateTime] $started
    [string] $status
    [int] $unified_job_template
    [int] $verbosity
}

class Inventory {
    [int] $id
    [string] $type
    [string] $url
    [DateTime] $created
    [DateTime] $modified
    [string] $name
    [string] $description
    [int] $organization
    [string] $variables
    [bool] $has_active_failures
    [int] $total_hosts
    [int] $hosts_with_active_failures
    [int] $total_groups
    [int] $groups_with_active_failures
    [bool] $has_inventory_sources
    [int] $total_inventory_sources
    [int] $inventory_sources_with_failures
    [Hashtable]$groups
    [Tower] $AnsibleTower

    [string] ToString() {
        return $this.name
    }
}

class Group {
    [int] $id
    [string] $type
    [string] $url
    [DateTime] $created
    [DateTime] $modified
    [string] $name
    [string] $description
    [object] $inventory
    [Hashtable] $variables
    [bool] $has_active_failures
    [int] $total_hosts
    [int] $hosts_with_active_failures
    [int] $total_groups
    [int] $groups_with_active_failures
    [bool] $has_inventory_sources
    [Tower] $AnsibleTower
}

class Project {
    [int] $id
    [string] $type
    [string] $url
    [DateTime] $created
    [DateTime] $modified
    [string] $name
    [string] $description
    [string] $local_path
    [string] $scm_type
    [string] $scm_url
    [string] $scm_branch
    [bool] $scm_clean
    [bool] $scm_delete_on_update
    [object] $credential
    [DateTime] $last_job_run
    [bool] $last_job_failed
    [bool] $has_schedules
    [object] $next_job_run
    [string] $status
    [bool] $scm_delete_on_next_update
    [bool] $scm_update_on_launch
    [int] $scm_update_cache_timeout
    [bool] $last_update_failed
    [string] $last_updated
    [Tower] $AnsibleTower
    [string] ToString() {
        return $this.name
    }
}
