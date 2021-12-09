Copy-Item -Path '.\src\M3Helper.AnsibleTower.ps1' -Destination '.\src\M3Helper.AnsibleTower.psm1'

$manifest = @{ Path = '.\src\M3Helper.AnsibleTower.psd1'
RootModule = 'M3Helper.AnsibleTower.psm1'
Author = 'DERET Raphaël'
ModuleVersion = '2.0'
CompanyName = 'MIXTRIO'
Copyright = '(c) 2021 MIXTRIO DERET Raphaël. Tous droits réservés.'
Description = 'Module for interacting with Ansible Tower (http://www.ansible.com/tower)'
CmdletsToExport = 'Get-AnsibleGroup, Get-AnsibleInventory, Get-AnsibleJob, Get-AnsibleJobTemplate, Get-AnsibleOrganization, Get-AnsibleProject, Invoke-AnsibleJobTemplate, New-AnsibleOrganization, Wait-AnsibleJob'
}
New-ModuleManifest @manifest