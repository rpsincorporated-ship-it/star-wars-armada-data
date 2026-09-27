# Star Wars Armada Data

Structured JSON data and local image assets for **Star Wars: Armada** cards.

This repository is an unofficial community-maintained reference dataset. It is built for app/database use, collection tools, list builders, preservation work, and card lookup utilities.

## Release

Current release:

```text
2025.01-final-complete-images
```

The release uses the original repository-style layout:

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

## Included Data

The database includes structured records for:

- Ship cards
- Squadron cards
- Upgrade cards
- Objective cards included in this data set
- Official Armada card data through the final AMG/FFG Armada state used for the 2025.01 final release

The data is stored as JSON under `data/`.

## Included Images

Card images are stored under `image/` and referenced from each card record using its `image` field.

Current image-reference audit:

```text
Missing image fields: 0
Broken image references: 0
Image references containing .json folder names: 0
Physical image folders named *.json: 0
Duplicate-name shared image issues: 0
```

Image paths use clean folder names, for example:

```text
image/ship-card/galactic-republic/acclamator-ii-class-assault-ship.png
image/squadron-card/galactic-empire/darth-vader.png
image/upgrade-card/commander/darth-vader.png
image/upgrade-card/officer/darth-vader.png
```

When a name appears on more than one card instance, each instance has its own image file. For example, squadron Darth Vader and upgrade Darth Vader records do not share the same image file.

## Data Format Notes

- JSON files are intended to be strict JSON and should not require app-specific preprocessing.
- Image paths are relative to the `image/` folder.
- Upgrade image paths use the upgrade slot folder without `.json` in the folder name.
- Duplicate card names may appear when Armada has multiple separate cards for the same character or ship title. Those records should remain separate and should use separate images.

## Testing

Install dependencies and run:

```bash
npm test
```

The test command runs ESLint against the JSON data files.

## Corrections

Corrections are welcome. Please include clear source references for data changes.

For image changes, include the source/provenance of the image and make sure the image matches the exact card instance represented by the JSON record.

## References

- Original repository: https://github.com/rkbodenner/star-wars-armada-data
- Armada Wiki: https://starwars-armada.fandom.com/
- X-Wing data schema inspiration: https://github.com/guidokessels/xwing-data

## Copyright, Trademark, and Reference-Only Notice

This repository is an unofficial community reference dataset for Star Wars: Armada. It is not affiliated with, endorsed by, sponsored by, or approved by Lucasfilm Ltd., Disney, Atomic Mass Games, Fantasy Flight Games, Asmodee, or any related rights holder.

Star Wars, Star Wars: Armada, all related names, card text, artwork, logos, characters, ships, factions, and other game materials are copyright and/or trademarks of their respective owners. Card images and card text are included only as a non-commercial reference aid for players, collectors, judges, developers, and preservation of game data.

Public availability of an image or card scan does not mean the material is public domain or freely licensed for redistribution. If you are a rights holder and want a file, image, card text entry, or reference removed or corrected, please open an issue or contact the repository owner. The project will promptly review and remove or replace disputed material.

Do not use this repository as a substitute for owning official products, official rules documents, or publisher materials. For official game information, rules, trademarks, copyrights, and organized play documents, refer to the official publisher and rights-holder sources.
