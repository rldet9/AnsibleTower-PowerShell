. $PSScriptRoot\M3Helper.AnsibleTower.ps1

$userName = 'admin'
$password = ConvertTo-SecureString 'srvW03arf' -AsPlainText -Force
$credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $password

$me = Connect-AnsibleTower -Credential $credential -TowerUrl 'http://awx.araf.local.com' -Authorization 'YWRtaW46c3J2VzAzYXJm' -DisableCertificateVerification -Verbose

$org = Get-AnsibleOrganization -Name 'ART' -Verbose
$org

#New-AnsibleOrganization -Name 'TEST' -Description 'Test PowerShell'

$extraVars = @{
    title    = "Mr"
    firtname = "Raphael"
    lastname = "DERET"
}

$job = Invoke-AnsibleJobTemplate -Name 'test_api' -Data $extraVars -Verbose | Wait-AnsibleJob -Interval 5 -Timeout 60 -Verbose
$job