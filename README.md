# Star Wars Armada Data

Structured JSON data and local PNG image assets for **Star Wars: Armada** cards.

This repository is an unofficial community reference database for Armada card data, app integrations, collection tools, list builders, and preservation work.

## Release

Current release:

```text
2025.01-final-complete-images
```

Release package:

```text
star-wars-armada-data-2025.01-final-complete-images-v12.zip
```

SHA256:

```text
51075F53748748542FF8F7E973778CF485413FB60EA6A1CBD0491C86E09BAA52
```

## Repository Layout

```text
data/
image/
.eslintrc.js
.gitignore
LICENSE
README.md
package-lock.json
package.json
```

Card and reference data lives under `data/`.

Image files live under `image/`.

## Included Data

The database includes structured records for:

- Ship cards
- Squadron cards
- Upgrade cards
- Objective cards
- Damage cards
- Reference cards

Final release audit:

```text
Data JSON files: 191
Database entries: 544
Image files: 633
JSON parse errors: 0
JSON files with UTF-8 BOM: 0
Wrapper objects: 0
Missing image fields: 0
Broken image references: 0
Image references with .json folder: 0
Unsafe absolute/parent image paths: 0
Non-PNG image references: 0
Non-PNG files: 0
Physical .json image folders: 0
Shared image path entries: 0
Shared image hash entries: 0
```

## Images

Every database entry has:

- An `image` field
- A local app-resolvable path under `image/`
- A `.png` image file
- A unique image path
- A unique image file hash

Example paths:

```text
image/ship-card/galactic-republic/acclamator-ii-class-assault-ship.png
image/squadron-card/galactic-empire/darth-vader.png
image/upgrade-card/commander/darth-vader.png
image/upgrade-card/officer/darth-vader.png
image/objective-card/advanced-gunnery.png
```

The database avoids old image folder paths such as:

```text
upgrade-card/officer.json/example.png
```

The corrected path style is:

```text
upgrade-card/officer/example.png
```

## Unique Images Per Entry

Each database entry has a unique image path and unique image file content. This includes cards with the same or similar names across different card types, factions, versions, or roles.

Examples:

- Darth Vader squadron, commander, officer, and boarding-team upgrade entries use separate images.
- Anakin Skywalker squadron variants and commander upgrade use separate images.
- Ahsoka Tano Galactic Republic officer and Rebel Alliance officer use separate images.
- Reserve Hangar Deck current and printed records use separate images.
- Objective cards use separate images per entry.

## Text Fallback Fields

Every record includes text fallback fields so an app can show useful card information when image display is disabled.

Each record includes:

```text
display-text
text-fallback
```

`display-text` is a simple text string for quick app display.

`text-fallback` is a structured object containing available fields such as:

- Label
- Family
- Category
- Faction
- Points
- Slots
- Keywords
- Traits
- Stats
- Rules text sections
- Setup text
- Special rules
- End-of-round text
- End-of-game text

## Data Format Notes

- JSON files are strict JSON.
- JSON files are UTF-8 without BOM.
- Image paths are relative to the `image/` folder.
- Image files are PNG.
- Image paths do not require absolute local paths.
- Image paths do not use parent-directory traversal such as `../`.
- Duplicate card names can exist when Armada has multiple real cards for the same character, ship title, or card name. Those records should stay separate and should use separate images.

## Testing

Install dependencies and run:

```bash
npm test
```

The test command runs ESLint against the JSON data files.

## Corrections

Corrections are welcome.

For data corrections, include clear source references.

For image corrections, include the source/provenance of the image and make sure the image matches the exact card instance represented by the JSON record.

When adding or changing records, preserve:

- Valid strict JSON
- Local resolvable PNG image paths
- Unique image files per database entry
- `display-text`
- `text-fallback`

## References

- Original repository: https://github.com/rkbodenner/star-wars-armada-data
- Armada Wiki: https://starwars-armada.fandom.com/
- X-Wing data schema inspiration: https://github.com/guidokessels/xwing-data

## Copyright, Trademark, and Reference-Only Notice

This repository is an unofficial community reference dataset for Star Wars: Armada. It is not affiliated with, endorsed by, sponsored by, or approved by Lucasfilm Ltd., Disney, Atomic Mass Games, Fantasy Flight Games, Asmodee, or any related rights holder.

Star Wars, Star Wars: Armada, all related names, card text, artwork, logos, characters, ships, factions, and other game materials are copyright and/or trademarks of their respective owners. Card images and card text are included only as a non-commercial reference aid for players, collectors, judges, developers, and preservation of game data.

Public availability of an image or card scan does not mean the material is public domain or freely licensed for redistribution. If you are a rights holder and want a file, image, card text entry, or reference removed or corrected, please open an issue or contact the repository owner. The project will promptly review and remove or replace disputed material.

Do not use this repository as a substitute for owning official products, official rules documents, or publisher materials. For official game information, rules, trademarks, copyrights, and organized play documents, refer to the official publisher and rights-holder sources.
