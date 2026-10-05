#!/usr/bin/env bash
# macOS system defaults: fast keys, no animations, quiet Finder/Dock, AeroSpace-friendly Spaces.
# Run by install.sh on macOS. Safe to re-run; no sudo. Some settings need a logout to apply.
set -euo pipefail

[[ "$(uname -s)" == Darwin ]] || { echo "macos/defaults.sh: not macOS, skipping" >&2; exit 0; }

# --- keyboard ------------------------------------------------------------------
# fastest repeat (1 = 15 ms; the Settings slider stops at 2) and shortest delay before it starts
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10
# holding a key repeats it (hjkl in Neovim) instead of popping up the accent picker
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Tab moves through every control in dialogs, not just text fields
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# --- typing: no text rewriting behind your back (code, commands, URLs) ------------
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain WebAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticTextCompletionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticInlinePredictionEnabled -bool false
defaults write NSGlobalDomain WebContinuousSpellCheckingEnabled -bool false

# --- animations: off or near-instant ---------------------------------------------
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false
defaults write NSGlobalDomain QLPanelAnimationDuration -float 0
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.finder DisableAllAnimations -bool true
# Reduce Motion also kills the Spaces slide (AeroSpace switches a lot). This domain is
# protected: it only sticks if the terminal has Full Disk Access, so don't fail without it.
if ! defaults write com.apple.universalaccess reduceMotion -bool true 2>/dev/null; then
  echo "reduce motion: not set (give the terminal Full Disk Access, or System Settings -> Accessibility -> Display)" >&2
fi

# --- dock: hidden, instant, out of the way ---------------------------------------
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 36
defaults write com.apple.dock minimize-to-application -bool true

# --- spaces: what AeroSpace's guide recommends ------------------------------------
# never reorder Spaces by recent use (AeroSpace's emulated workspaces rely on a fixed order)
defaults write com.apple.dock mru-spaces -bool false
# "Displays have separate Spaces" OFF: AeroSpace's guide says macOS is more stable this way
defaults write com.apple.spaces spans-displays -bool true
# Mission Control groups by app, so AeroSpace's hidden windows don't show up tiny
defaults write com.apple.dock expose-group-apps -bool true

# --- finder ----------------------------------------------------------------------
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# list view; search the current folder, not the whole Mac
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
defaults write com.apple.finder FXDefaultSearchScope -string SCcf
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# no .DS_Store litter on shares and thumb drives
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
# ~/Library is hidden by default; chflags is per-user, no sudo needed
chflags nohidden "$HOME/Library"

# --- screenshots -----------------------------------------------------------------
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string png
defaults write com.apple.screencapture disable-shadow -bool true

# --- save / print panels ---------------------------------------------------------
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
# new documents save to disk, not iCloud
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# --- siri / spotlight suggestions: local results only ---------------------------
defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true

# Menu bar hiding (_HIHideMenuBar) is deliberately untouched: sketchybar draws over that strip.

# --- apply -----------------------------------------------------------------------
for app in Dock Finder SystemUIServer cfprefsd; do
  killall "$app" >/dev/null 2>&1 || true
done
echo "macOS defaults applied. Log out and back in for keyboard, Spaces and Reduce Motion to fully take effect."
