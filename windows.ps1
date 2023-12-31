#Install WinGet
#Based on this gist: https://gist.github.com/crutkas/6c2096eae387e544bd05cde246f23901
$hasPackageManager = Get-AppPackage -name 'Microsoft.DesktopAppInstaller'
if (!$hasPackageManager -or [version]$hasPackageManager.Version -lt [version]"1.10.0.0") {
    "Installing winget Dependencies"
    Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'

    $releases_url = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $releases = Invoke-RestMethod -uri $releases_url
    $latestRelease = $releases.assets | Where { $_.browser_download_url.EndsWith('msixbundle') } | Select -First 1

    "Installing winget from $($latestRelease.browser_download_url)"
    Add-AppxPackage -Path $latestRelease.browser_download_url
}
else {
    "winget already installed"
}

#Configure WinGet
Write-Output "Configuring winget"

#winget config path from: https://github.com/microsoft/winget-cli/blob/master/doc/Settings.md#file-location
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json";
$settingsJson = 
@"
    {
        // For documentation on these settings, see: https://aka.ms/winget-settings
        "experimentalFeatures": {
          "experimentalMSStore": true,
        }
    }
"@;
$settingsJson | Out-File $settingsPath -Encoding utf8


#Install New apps
Write-Output "Installing Apps"
$apps = @(
    <# General Applications #>
    @{name = "CPUID.CPU-Z" }, 
    @{name = "Discord.Discord" },
    @{name = "ElectronicArts.EADesktop" }.
    @{name = "EpicGames.EpicGamesLauncher" }.
    @{name = "Google.Chrome" },
    @{name = "Logitech.GHUB" },
    @{name = "Nvidia.GeForceExperience" },
    @{name = "Spotify.Spotify" },
    @{name = "SteelSeries.GG" },
    @{name = "Ubisoft.Connect" },
    @{name = "Valve.Steam" },

    <# Productivity Applications #>
    @{name = "Microsoft.Office" },
    @{name = "Microsoft.Teams.Preview" },
    @{name = "SlackTechnologies.Slack" },

    <# Miscellaneous Applications #>
    @{name = "Bitwarden.Bitwarden" },

    <# Developer Languages #>
    @{name = "Anaconda.Miniconda3" },
    @{name = "Microsoft.DotNet.SDK.7" },
    @{name = "OpenJS.NodeJS.LTS" },

    <# Developer Tooling #>
    @{name = "Docker.DockerDesktop" },
    @{name = "GitHub.GitHubDesktop" },
    @{name = "Microsoft.PowerShell" },
    @{name = "Microsoft.VisualStudioCode" },
    @{name = "Microsoft.WindowsTerminal" },
    @{name = "Postman.Postman" },

    <# Azure Tooling #>
    @{name = "Microsoft.AzureCLI" },
    @{name = "Microsoft.Azure.CosmosEmulator" },
    @{name = "Microsoft.AzureDataStudio" },
    @{name = "Microsoft.Azure.StorageEmulator" },
    @{name = "Microsoft.Azure.StorageExplorer" }
);
Foreach ($app in $apps) {
    $listApp = winget list --exact -q $app.name --accept-source-agreements 
    if (![String]::Join("", $listApp).Contains($app.name)) {
        Write-host "Installing:" $app.name
        if ($app.source -ne $null) {
            winget install --exact --silent $app.name --source $app.source --accept-package-agreements
        }
        else {
            winget install --exact --silent $app.name --accept-package-agreements
        }
    }
    else {
        Write-host "Skipping Install of " $app.name
    }
}

#Setup WSL
# wsl --install