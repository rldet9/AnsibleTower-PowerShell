AnsibleTower-PowerShell
=======================

Powershell cmdlets for interacting with Ansible Tower.

Example:
```
$userName = 'admin'
$password = ConvertTo-SecureString 'password' -AsPlainText -Force
$credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $password

Connect-AnsibleTower -Credential $credential -TowerUrl 'http://awx.araf.local.com' -Authorization 'xxxxxxxxxxxxxx' -DisableCertificateVerification -Verbose

$extraVars = @{
    title    = "Mr"
    firtname = "John"
    lastname = "DOE"
}

$job = Invoke-AnsibleJobTemplate -Name 'test_api' -Data $extraVars -Verbose | Wait-AnsibleJob -Interval 5 -Timeout 60 -Verbose
