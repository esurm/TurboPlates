# TurboPlates

Lightweight nameplate addon, built from scratch for WoW 3.3.5a (w/ Ascension API).

## Features

- Threat-based coloring with tank/DPS/off-tank mode support
- Smooth nameplate stacking to prevent overlap
- Name display inside health bar option
- Spell highlight system with customizable glow effects
- Buff and debuff display on nameplates
- Whitelist/blacklist filtering
- Dispellable buff highlighting
- TurboDebuffs (BigDebuffs port) integration for priority aura tracking
- HHTD (Healers have to Die) integration
- Personal Resource Bar customization
- Arena enemy numbering
- "Targeting me" indicator for arenas
- Totem nameplates with icon display modes
- Quest objective tracking on nameplates
- Execute range indicator
- Profile import/export

## Installation

1. Download and extract to `Interface\AddOns\TurboPlates`
2. Restart the game

## Usage

Type `/tp` or `/turboplates` to open the options panel, or use the minimap button.

## Configuration

Settings are organized into tabs:

- **General** - Friendly plates, PvP options and more
- **Nameplate Style** - Dimensions, textures, scale etc.
- **Nameplate Texts** - Font, name format, health values, level display
- **Colors** - Health, threat, tank mode colors
- **Castbars** - Castbar appearance and highlight spells
- **Debuffs/Buffs** - Aura filtering and display
- **Personal Bar** - Your own nameplate settings
- **Combo Points** - Style and colors
- **TurboDebuffs** - Priority debuff tracking
- **Plate Stacking** - Overlap prevention settings
- **Profiles** - Import/export configuration

## Dependencies

Includes the following libraries:
- LibStub
- CallbackHandler-1.0
- LibCustomGlow-1.0
- LibDeflate
- AceSerializer-3.0
- LibSharedMedia-3.0
