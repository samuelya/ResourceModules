function Publish-AllMissingCarmlModules {
    param (
        [Parameter(Mandatory = $true)]
        [string] $ModulesFolderPath,

        [Parameter(Mandatory = $true)]
        [string] $BicepRegistryName,

        [Parameter(Mandatory = $true)]
        [string] $BicepRegistryRgName,

        [Parameter(Mandatory = $true)]
        [string] $bicepRegistryRgLocation,

        [Parameter(Mandatory = $false)]
        [bool] $PublishLatest = $true,

        [Parameter(Mandatory = $false)]
        [string] $NotMatch = 'custom'
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)

        # Load used functions
        . (Join-Path (Split-Path -Path $PSScriptRoot -Parent) 'resourcePublish' 'Get-PrivateRegistryRepositoryName.ps1')
        . (Join-Path (Split-Path -Path $PSScriptRoot -Parent) 'resourcePublish' 'Get-ModulesMissingFromPrivateBicepRegistry.ps1')
        . (Join-Path (Split-Path -Path $PSScriptRoot -Parent) 'resourcePublish' 'Publish-ModuleToPrivateBicepRegistry.ps1')

        Write-Host 'script:' (Join-Path (Split-Path -Path $PSScriptRoot -Parent) 'resourcePublish' 'Get-ModulesMissingFromPrivateBicepRegistry.ps1')

    }
    process {
        $paths = Get-ChildItem -Path $ModulesFolderPath -Recurse -Filter 'main.bicep' |


            Where-Object { $_.FullName -notmatch $NotMatch } |
            Select-Object FullName
        Write-Host 'script:' (Join-Path (Split-Path -Path $PSScriptRoot -Parent) 'resourcePublish' 'Get-ModulesMissingFromPrivateBicepRegistry.ps1')

        $paths | ForEach-Object -Parallel {

            . (Join-Path (Split-Path -Path $using:PSScriptRoot -Parent) 'resourcePublish' 'Get-PrivateRegistryRepositoryName.ps1')
            . (Join-Path (Split-Path -Path $using:PSScriptRoot -Parent) 'resourcePublish' 'Get-ModulesMissingFromPrivateBicepRegistry.ps1')
            . (Join-Path (Split-Path -Path $using:PSScriptRoot -Parent) 'resourcePublish' 'Publish-ModuleToPrivateBicepRegistry.ps1')

            Write-Host 'Working on' $_.FullName

            Write-Verbose 'Invoke Get-ModulesMissingFromPrivateBicepRegistry with' -Verbose

            $missingInputObject = @{
                TemplateFilePath    = $_.FullName
                BicepRegistryName   = $using:BicepRegistryName
                BicepRegistryRgName = $using:BicepRegistryRgName
                PublishLatest       = $using:PublishLatest
            }

            $missingModules = Get-ModulesMissingFromPrivateBicepRegistry @missingInputObject
            $missingModules = $missingModules | Where-Object { $_.TemplateFilePath -notmatch '.json' }

            $modulesToPublish = @()

            foreach ($missingModule in $missingModules) {
                if ($modulsToPublish.TemplateFilePath -notcontains $missingModule.TemplateFilePath) {
                    $modulesToPublish += $missingModule
                }
            }
            foreach ($moduleToPublish in $modulesToPublish) {
                $RelPath = (($moduleToPublish.TemplateFilePath).Split('/modules/')[-1]).Split('/main.')[0]
                Write-Host "##[group]$(' - [{0}] [{1}]' -f $RelPath, $moduleToPublish.Version)"
            }
            #################
            ##   Publish   ##
            #################
            foreach ($moduleToPublish in $modulesToPublish) {
                $RelPath = (($moduleToPublish.TemplateFilePath).Split('/modules/')[-1]).Split('/main.')[0]
                Write-Host "##[group]$(' - [{0}] [{1}]' -f $RelPath, $moduleToPublish.Version)"

                $functionInput = @{
                    TemplateFilePath    = $moduleToPublish.TemplateFilePath
                    BicepRegistryName   = $using:bicepRegistryName
                    BicepRegistryRgName = $using:bicepRegistryRgName
                    ModuleVersion       = $moduleToPublish.Version
                }

                Write-Verbose 'Invoke Publish-ModuleToPrivateBicepRegistry with ' -Verbose

                Publish-ModuleToPrivateBicepRegistry @functionInput -Verbose -ErrorAction Continue

            }
        }

    }

}
