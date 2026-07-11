# Free Them All

A small quality-of-life mod for OpenMW that removes the repetitive process of freeing slaves one by one.

Simply free one slave using the normal **"go free"** dialogue option and the mod will automatically free the remaining eligible slaves nearby.

The vanilla dialogue, keys, and gameplay remain unchanged.

## Features

- Uses the vanilla **"go free"** dialogue.
- Automatically frees nearby eligible slaves.
- Preserves vanilla gameplay and immersion.
- Quest-sensitive slaves are excluded to preserve quest progression.
- OpenMW Lua implementation (no ESP required).
- Includes an in-game settings page.

## Compatibility

The mod is designed to preserve vanilla quest behavior.

The following NPCs are intentionally excluded from automatic batch freeing:

- Eleedal-Lei
- Dahleena

These NPCs should be freed manually as intended by the original game.

## Requirements

- OpenMW 0.49 or newer (tested on OpenMW 0.49+).

## Installation

1. Copy the mod into your OpenMW mods directory.
2. Add the folder as a `data=` path in `openmw.cfg`.
3. Enable `FreeThemAll.omwscripts`.
4. Launch the game.

## Settings

The mod includes an in-game settings page where you can:

- Enable or disable the mod.
- (Future versions may include additional options.)

## Design Philosophy

This mod intentionally keeps the vanilla experience intact.

Rather than replacing the existing slave freeing mechanic, it simply extends it by automatically freeing nearby eligible slaves after a successful vanilla release.

No new dialogue options, spells, or hotkeys are added.

## Credits

Created by Hoskope.

Built using the OpenMW Lua scripting API.