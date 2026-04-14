#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This script is for macOS only."
  exit 1
fi

append_if_missing() {
  local line="$1"
  local file="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  if ! grep -qxF "$line" "$file" 2>/dev/null; then
    echo "$line" >> "$file"
  fi
}

if ! command -v xcode-select >/dev/null 2>&1; then
  echo "xcode-select is required but was not found."
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install || true
  echo "Finish the Command Line Tools install, then run this script again."
  exit 0
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  echo "Homebrew was not found after installation."
  exit 1
fi

brew update
brew upgrade

brew install \
  git git-lfs curl wget gnu-tar make unzip zip \
  zsh \
  ripgrep fd fzf \
  bat eza btop tldr \
  jq yq httpie \
  openssh \
  sqlite \
  git-delta tig \
  just entr \
  direnv \
  p7zip \
  watchman \
  pinentry \
  gnupg \
  coreutils \
  findutils \
  gnu-sed \
  gawk \
  pkg-config \
  cmake ninja meson \
  llvm \
  openssl readline xz zlib bzip2 libffi ncurses \
  node \
  python \
  openjdk@21 \
  go \
  rust \
  ruby \
  php composer \
  dotnet \
  postgresql@16 redis \
  ffmpeg \
  fnm \
  font-fira-code

brew install --cask \
  visual-studio-code \
  firefox

git lfs install

append_if_missing 'eval "$(direnv hook zsh)"' "$HOME/.zshrc"
append_if_missing 'umask 022' "$HOME/.zshrc"
append_if_missing 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc"
append_if_missing 'export PATH="$(brew --prefix)/opt/openjdk@21/bin:$PATH"' "$HOME/.zshrc"
append_if_missing 'eval "$(fnm env --use-on-cd --shell zsh)"' "$HOME/.zshrc"
append_if_missing 'export SHELL="$(which zsh)"' "$HOME/.zprofile"

if command -v locate.updatedb >/dev/null 2>&1; then
  sudo locate.updatedb || true
fi

sudo mkdir -p /etc/paths.d
if [ ! -f /etc/paths.d/openjdk ]; then
  echo "$(brew --prefix)/opt/openjdk@21/bin" | sudo tee /etc/paths.d/openjdk >/dev/null
fi

sudo mkdir -p /etc/paths.d
if [ ! -f /etc/paths.d/dotnet ]; then
  echo "$(brew --prefix)/share/dotnet" | sudo tee /etc/paths.d/dotnet >/dev/null
fi

brew services start postgresql@16 || true
brew services start redis || true

mkdir -p "$HOME/Code" "$HOME/Code/projects" "$HOME/Code/dotfiles"

git config --global init.defaultBranch main

DESKTOP_DIR="$HOME/Desktop"
mkdir -p "$DESKTOP_DIR"
DESKTOP_FILE="$DESKTOP_DIR/dev-next-steps.txt"

cat > "$DESKTOP_FILE" <<'EOF'
==============================
DEV SETUP - NEXT STEPS
==============================

Welcome.
This guide explains what you just set up, why it matters, and where your files should go.

First, copy the .continue folder into your home directory.

--------------------------------
1. Restart or open a new terminal
--------------------------------

Do this first.

Why:
Some changes do not fully apply until you start a fresh shell session.
That includes things like your shell, PATH changes, and tool initialization.

--------------------------------
2. The big picture
--------------------------------

You now have a machine set up for coding.

But a good setup is not only about installing apps.
It is also about keeping your files organized so things are easy to find and easy to understand later.

The main idea is:

- projects and repositories go in one main coding folder
- system config files stay where macOS expects them
- backup copies of config files go in a dedicated dotfiles folder

--------------------------------
3. Your main coding folder
--------------------------------

This setup created:

~/Code

The ~ symbol means your home folder.

So:

~/Code

means:

the folder named Code inside your home folder

This is where your coding-related folders should go.

A good structure looks like this:

~/Code
  |- vscode-settings
  |- dotfiles
  |- projects
  |  |- my-first-project
  |  |- another-project

What each one is for:

~/Code/vscode-settings
- shared editor settings

~/Code/dotfiles
- backup copies of your personal config files

~/Code/projects
- your actual coding projects

This helps keep your computer from turning into random folders everywhere.

--------------------------------
4. What Git is
--------------------------------

Git is a tool that tracks changes to files.

It helps you:
- save versions of your work
- go back if something breaks
- see what changed
- work with another person without guessing who changed what

Simple way to think about it:
Git is version history for your code and configs.

--------------------------------
5. What GitHub is
--------------------------------

GitHub is a website where Git repositories can live online.

It helps you:
- back up your work
- share work with another person
- move your work between computers

Simple way to think about it:
GitHub is the online home for your Git repositories.

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

You need a GitHub account before you can:
- use shared repositories easily
- upload your own dotfiles later

--------------------------------
7. Tell Git who you are
--------------------------------

Run these commands in the terminal:

git config --global user.name "Your Name"
git config --global user.email "you@example.com"

What this means:

git config
- changes Git settings

--global
- applies this for your whole user account on this computer

user.name
- the name Git puts on your commits

user.email
- the email Git puts on your commits

Use the name and email you want connected to your work.

--------------------------------
8. Open VS Code
--------------------------------

Run:

code

This opens your code editor.

A code editor is the app where you write and edit code.

--------------------------------
9. Install VS Code extensions
--------------------------------

Extensions are extra features you add to the editor.
VS Code is like a blank canvas. You can add lots of tools to it.

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
- hide all pages in the extension besides 'home'

Todo Tree
- finds TODO comments in your code and shows them in a list

Continue
- runs our AI features in VS Code (autocomplete, ai chat, etc.)
- reference https://docs.continue.dev/ide-extensions/quick-start to set-up or ask your system admin

--------------------------------
10. Enable Settings Sync
--------------------------------

In VS Code:
- click the profile icon in the bottom left
- click Turn on Settings Sync
- sign in with your own GitHub account or Microsoft account

Why:
This backs up your own editor setup, such as:
- settings
- extensions
- keybinds

This is for your own account.
It does not replace the shared setup repo below.

--------------------------------
11. Shared settings with your partner
--------------------------------

You both want your editor to behave the same way.

That is what this repo is for:

realcatdev/vscode-settings

First, move into your coding folder:

cd ~/Code

What this command means:
cd = change directory
It moves you into a folder.

Now download the shared settings repo:

git clone https://github.com/realcatdev/vscode-settings.git

What this means:
git clone = download a GitHub repository onto your computer

This creates:

~/Code/vscode-settings

Now move into it:

cd vscode-settings

Install the shared extensions:

cat extensions.txt | xargs -n 1 code --install-extension

What this does:
- cat extensions.txt = reads the file
- | = sends that output into the next command
- xargs -n 1 = takes one line at a time
- code --install-extension = installs one extension

So this command installs the extensions listed in that file one by one.

Apply the shared settings:

cp settings.json ~/Library/Application\ Support/Code/User/settings.json

What this means:
cp = copy a file

This copies the shared VS Code settings into the place where VS Code actually reads its settings.

After this, your editor and your partner's editor should be much closer to matching.

--------------------------------
12. What dotfiles are
--------------------------------

Dotfiles are configuration files.

They control how your tools behave.

Examples:
~/.zshrc
(example config folder in ~/.config)

These are the real files your system actually uses.

A dotfiles folder or dotfiles repository is not the live config itself.
It is your saved copy and backup of those files.

That is why your dotfiles should live in:

~/Code/dotfiles

and not in random places.

--------------------------------
13. Create your dotfiles folder
--------------------------------

Run:

cd ~/Code/dotfiles
git init

What these commands mean:

cd ~/Code/dotfiles
moves you into that folder

git init
starts a Git repository in the current folder

That means this folder can now track versions of your config backups.

--------------------------------
14. Copy your config files into dotfiles
--------------------------------

Run:

cp ~/.zshrc .
# copy any relevant ~/.config folders you use

What this means:

cp = copy
-r = copy a folder and everything inside it
. = the current folder

So these commands copy:
- your Zsh config
- any relevant config folders from ~/.config

into:

~/Code/dotfiles

Important:
Your real config still lives in:
- ~/.zshrc
- ~/.config

The dotfiles folder is your saved copy.

--------------------------------
15. Save your dotfiles with Git
--------------------------------

Run:

git add .
git commit -m "my setup"

What this means:

git add .
- tells Git to include everything in the current folder

git commit
- saves a snapshot in Git history

-m "my setup"
- gives that snapshot a message

So this creates a saved version of your dotfiles backup.

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

What these mean:

git branch -M main
- renames your current branch to main

git remote add origin ...
- tells Git where the online GitHub repository is

git push -u origin main
- uploads your local files and history to GitHub

Now your dotfiles are backed up online.

--------------------------------
17. Restore dotfiles later
--------------------------------

On another computer, replace YOURNAME with your GitHub username and run:

git clone https://github.com/YOURNAME/dotfiles.git ~/Code/dotfiles
cp ~/Code/dotfiles/.zshrc ~/
# copy any saved ~/.config folders back into ~/.config/

This does two things:
- downloads your saved config backup
- copies the files back into the real places your system uses

--------------------------------
18. Good file habits
--------------------------------

Try to follow this rule:

Projects and repositories go in:
~/Code

Projects you actively build should usually go in:
~/Code/projects

Live config files stay where the system expects them, such as:
~/.zshrc
~/.config

Backup copies of those configs go in:
~/Code/dotfiles

This structure will save you a lot of confusion later.

--------------------------------
19. Finder
--------------------------------

This setup uses Finder, which is the built-in macOS file manager.

It is the app you use to browse folders visually.

You can use it to open:
- Home
- Code
- Desktop
- Downloads

You can launch it by:
- clicking the Finder icon in the Dock
- or searching for Finder with Spotlight

A good example:
- open Finder
- open your Code folder
- open your projects folder
- open a project folder
- right click
- choose New Terminal at Folder if enabled, or open Terminal and cd into that folder

Done.
EOF

echo "Done. Open a new terminal, then follow the Desktop guide at:"
echo "$DESKTOP_FILE"