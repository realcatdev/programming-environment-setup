

$ErrorActionPreference = 'Stop'

function Write-Status {
    param([string]$Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Ensure-Command {
    param(
        [string]$Command,
        [string]$InstallHint
    )

    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        throw "$Command is required but was not found. $InstallHint"
    }
}

function Add-LineIfMissing {
    param(
        [string]$Line,
        [string]$Path
    )

    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    if (-not (Test-Path $Path)) {
        New-Item -ItemType File -Path $Path -Force | Out-Null
    }

    $existing = Get-Content -Path $Path -ErrorAction SilentlyContinue
    if ($existing -notcontains $Line) {
        Add-Content -Path $Path -Value $Line
    }
}

function Refresh-Path {
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [string]$Name = $Id
    )

    Write-Status "Installing $Name"
    winget install --id $Id --exact --accept-package-agreements --accept-source-agreements --silent
}

function Install-NpmGlobal {
    param([string]$PackageName)

    Write-Status "Installing npm package $PackageName"
    npm install -g $PackageName
}

Ensure-Command -Command 'winget' -InstallHint 'Install App Installer from Microsoft Store, then re-run this script.'

Write-Status 'Creating main folders'
$codeDir = Join-Path $HOME 'Code'
$projectsDir = Join-Path $codeDir 'projects'
$dotfilesDir = Join-Path $codeDir 'dotfiles'
New-Item -ItemType Directory -Force -Path $codeDir, $projectsDir, $dotfilesDir | Out-Null

Write-Status 'Installing core apps and tools with winget'
$packages = @(
    @{ Id = 'Git.Git'; Name = 'Git' },
    @{ Id = 'GitHub.GitLFS'; Name = 'Git LFS' },
    @{ Id = 'Curl.Curl'; Name = 'curl' },
    @{ Id = 'JanDeDobbeleer.OhMyPosh'; Name = 'oh-my-posh' },
    @{ Id = 'Gerardog.gsudo'; Name = 'gsudo' },
    @{ Id = 'Microsoft.PowerShell'; Name = 'PowerShell' },
    @{ Id = 'Microsoft.VisualStudioCode'; Name = 'Visual Studio Code' },
    @{ Id = 'Mozilla.Firefox'; Name = 'Firefox' },
    @{ Id = 'OpenJS.NodeJS.LTS'; Name = 'Node.js LTS' },
    @{ Id = 'Python.Python.3.12'; Name = 'Python 3.12' },
    @{ Id = 'Oracle.JavaRuntimeEnvironment'; Name = 'Java Runtime' },
    @{ Id = 'Oracle.JDK.21'; Name = 'JDK 21' },
    @{ Id = 'GoLang.Go'; Name = 'Go' },
    @{ Id = 'Rustlang.Rustup'; Name = 'Rustup' },
    @{ Id = 'RubyInstallerTeam.Ruby.3.4'; Name = 'Ruby' },
    @{ Id = 'PHP.PHP.8.4'; Name = 'PHP' },
    @{ Id = 'Composer.Composer'; Name = 'Composer' },
    @{ Id = 'Microsoft.DotNet.SDK.8'; Name = '.NET SDK 8' },
    @{ Id = 'PostgreSQL.PostgreSQL.16'; Name = 'PostgreSQL 16' },
    @{ Id = 'Redis.Redis'; Name = 'Redis' },
    @{ Id = 'dandavison.delta'; Name = 'delta' },
    @{ Id = 'BurntSushi.ripgrep.MSVC'; Name = 'ripgrep' },
    @{ Id = 'sharkdp.fd'; Name = 'fd' },
    @{ Id = 'junegunn.fzf'; Name = 'fzf' },
    @{ Id = 'sharkdp.bat'; Name = 'bat' },
    @{ Id = 'eza-community.eza'; Name = 'eza' },
    @{ Id = 'aristocratos.btop4win'; Name = 'btop4win' },
    @{ Id = 'HTTPie.HTTPie'; Name = 'HTTPie' },
    @{ Id = 'jqlang.jq'; Name = 'jq' },
    @{ Id = 'GnuPG.Gpg4win'; Name = 'Gpg4win' },
    @{ Id = '7zip.7zip'; Name = '7-Zip' },
    @{ Id = 'VideoLAN.VLC'; Name = 'VLC' },
    @{ Id = 'Watchman.Watchman'; Name = 'Watchman' },
    @{ Id = 'ajeetdsouza.zoxide'; Name = 'zoxide' },
    @{ Id = 'Starship.Starship'; Name = 'Starship' },
    @{ Id = 'Microsoft.WindowsTerminal'; Name = 'Windows Terminal' }
)

foreach ($package in $packages) {
    try {
        Install-WingetPackage -Id $package.Id -Name $package.Name
    }
    catch {
        Write-Warning "Failed to install $($package.Name): $($_.Exception.Message)"
    }
}

Refresh-Path

if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Status 'Configuring Git defaults'
    git lfs install | Out-Null
    git config --global init.defaultBranch main
}

if (Get-Command npm -ErrorAction SilentlyContinue) {
    try {
        Install-NpmGlobal -PackageName 'pnpm'
    }
    catch {
        Write-Warning "Failed to install pnpm: $($_.Exception.Message)"
    }
}

if (-not (Get-Command fnm -ErrorAction SilentlyContinue)) {
    try {
        Write-Status 'Installing fnm'
        winget install --id Schniz.fnm --exact --accept-package-agreements --accept-source-agreements --silent
        Refresh-Path
    }
    catch {
        Write-Warning "Failed to install fnm: $($_.Exception.Message)"
    }
}

Write-Status 'Setting up PowerShell profile'
$profilePath = $PROFILE.CurrentUserAllHosts
Add-LineIfMissing -Path $profilePath -Line 'Invoke-Expression (&starship init powershell)'
Add-LineIfMissing -Path $profilePath -Line 'Invoke-Expression (& { (zoxide init powershell | Out-String) })'
Add-LineIfMissing -Path $profilePath -Line '$env:Path = "$HOME\\.local\\bin;$env:Path"'

Write-Status 'Creating Desktop guide'
$desktopDir = [Environment]::GetFolderPath('Desktop')
$desktopFile = Join-Path $desktopDir 'dev-next-steps.txt'

@'
==============================
DEV SETUP - NEXT STEPS
==============================

Welcome.
This guide explains what you just set up, why it matters, and where your files should go.

First, copy the .continue folder into your home directory.

--------------------------------
1. Restart or sign out
--------------------------------

Do this first.

Why:
Some changes do not fully apply until you start a fresh session.
That includes things like your shell, terminal behavior, and some app integrations.

--------------------------------
2. The big picture
--------------------------------

You now have a machine set up for coding.

But a good setup is not only about installing apps.
It is also about keeping your files organized so things are easy to find and easy to understand later.

The main idea is:

- projects and repositories go in one main coding folder
- live app settings stay where Windows apps expect them
- backup copies of config files go in a dedicated dotfiles folder

--------------------------------
3. Your main coding folder
--------------------------------

This setup created:

%USERPROFILE%\Code

This is where your coding-related folders should go.

A good structure looks like this:

%USERPROFILE%\Code
  |- vscode-settings
  |- dotfiles
  |- projects
  |  |- my-first-project
  |  |- another-project

What each one is for:

%USERPROFILE%\Code\vscode-settings
- shared editor settings

%USERPROFILE%\Code\dotfiles
- backup copies of your personal config files

%USERPROFILE%\Code\projects
- your actual coding projects

--------------------------------
4. What Git is
--------------------------------

Git is a tool that tracks changes to files.

It helps you:
- save versions of your work
- go back if something breaks
- see what changed
- work with another person without guessing who changed what

--------------------------------
5. What GitHub is
--------------------------------

GitHub is a website where Git repositories can live online.

It helps you:
- back up your work
- share work with another person
- move your work between computers

--------------------------------
6. Make a GitHub account
--------------------------------

If you do not already have one:

Go to:
https://github.com

Then:
- click Sign up
- create an account
- verify your email
- stay signed in in your browser

--------------------------------
7. Tell Git who you are
--------------------------------

Run these commands in PowerShell:

git config --global user.name "Your Name"
git config --global user.email "you@example.com"

Use the name and email you want connected to your work.

--------------------------------
8. Open VS Code
--------------------------------

Run:

code

This opens your code editor.

--------------------------------
9. Install VS Code extensions
--------------------------------

In VS Code:
- click the Extensions icon on the left
- search for and install these:

REMOVE: GitHub Copilot Chat

Live Share
- lets two people work in the same coding session

Prettier
- formats code so it stays neat and consistent

ESLint
- points out common JavaScript and TypeScript problems

GitLens
- makes Git information easier to understand inside VS Code
- hide all pages in the extension besides home

Todo Tree
- finds TODO comments in your code and shows them in a list

Continue
- runs AI features in VS Code
- reference https://docs.continue.dev/ide-extensions/quick-start to set it up or ask your system admin

--------------------------------
10. Enable Settings Sync
--------------------------------

In VS Code:
- click the profile icon in the bottom left
- click Turn on Settings Sync
- sign in with your own GitHub account or Microsoft account

--------------------------------
11. Shared settings with your partner
--------------------------------

Move into your coding folder:

cd $HOME\Code

Download the shared settings repo:

git clone https://github.com/realcatdev/vscode-settings.git

This creates:

$HOME\Code\vscode-settings

Move into it:

cd vscode-settings

Install the shared extensions:

Get-Content .\extensions.txt | ForEach-Object { code --install-extension $_ }

Apply the shared settings:

Copy-Item .\settings.json $env:APPDATA\Code\User\settings.json -Force

--------------------------------
12. What dotfiles are
--------------------------------

Dotfiles are configuration files.

They control how your tools behave.

Examples:
- PowerShell profile
- Windows Terminal settings
- app config folders in AppData

These are the real files your system actually uses.

A dotfiles folder or dotfiles repository is not the live config itself.
It is your saved copy and backup of those files.

--------------------------------
13. Create your dotfiles folder
--------------------------------

Run:

cd $HOME\Code\dotfiles
git init

--------------------------------
14. Copy your config files into dotfiles
--------------------------------

Run examples like:

Copy-Item $PROFILE.CurrentUserAllHosts .
Copy-Item $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json . -ErrorAction SilentlyContinue

Important:
Your real config still lives in its normal system locations.
The dotfiles folder is your saved copy.

--------------------------------
15. Save your dotfiles with Git
--------------------------------

Run:

git add .
git commit -m "my setup"

--------------------------------
16. Upload your dotfiles to GitHub
--------------------------------

In your browser:
- go to GitHub
- click New repository
- name it dotfiles
- create it without adding files

Then replace YOURNAME with your GitHub username and run:

git branch -M main
git remote add origin https://github.com/YOURNAME/dotfiles.git
git push -u origin main

--------------------------------
17. Restore dotfiles later
--------------------------------

On another computer, replace YOURNAME with your GitHub username and run:

git clone https://github.com/YOURNAME/dotfiles.git $HOME\Code\dotfiles
Copy-Item $HOME\Code\dotfiles\Microsoft.PowerShell_profile.ps1 $PROFILE.CurrentUserAllHosts -Force

--------------------------------
18. Good file habits
--------------------------------

Try to follow this rule:

Projects and repositories go in:
%USERPROFILE%\Code

Projects you actively build should usually go in:
%USERPROFILE%\Code\projects

Live config files stay where the system expects them.

Backup copies of those configs go in:
%USERPROFILE%\Code\dotfiles

--------------------------------
19. File Explorer
--------------------------------

This setup uses File Explorer.

You can use it to open:
- Home
- Code
- Desktop
- Downloads

You can launch it by:
- pressing Win + E
- or searching for File Explorer

A good example:
- open File Explorer
- open your Code folder
- open your projects folder
- open a project folder
- click the address bar
- type powershell
- press Enter

Now PowerShell opens in the correct place automatically.

--------------------------------

Done.
'@ | Set-Content -Path $desktopFile -Encoding UTF8

Write-Host ''
Write-Host 'Done. Restart your system, then follow the Desktop guide at:' -ForegroundColor Green
Write-Host $desktopFile -ForegroundColor Yellow