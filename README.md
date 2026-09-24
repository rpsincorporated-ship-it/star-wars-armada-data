# Star Wars Armada Data

Structured JSON data and packaged image assets for **Star Wars: Armada** cards.

This release is the certified `2025.01-final` build. The archive is laid out like the original repository:

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

## What Data Is Included?

Card text and structured data are included for:

- Ships
- Squadrons
- Upgrades
- Objectives for non-campaign play
- Damage cards
- Reference cards
- Cards through Wave 8, including SSD, Starhawk, Onager, and Rebellion in the Rim
- Errata through Armada FAQ version 5.1.1

Images are included under `image/` for the packaged card image library.

## Image Availability

Most packaged image references point to files under `image/`.

Some records intentionally use:

```json
"image-status": "card-image-not-packaged"
```

That means the card identity is known and the data record is included, but the exact card-front image is not packaged in this release.

For this release, eight Rebellion in the Rim squadron card images are intentionally not packaged:

- Hondo Ohnaka
- IG-88B
- Kanan Jarrus
- Lando Calrissian
- Malee Hurra
- Mart Mattin
- Moralo Eval
- Tel Trevura

Those records retain their generic `squadron-image` references where available and are marked with `image-status: card-image-not-packaged` instead of adding unapproved exact card-front artwork.

## What Is Not Included?

- Campaign objectives from Corellian Conflict or Rebellion in the Rim
- Images for some cards prior to Rebellion in the Rim and Wave 8
- Exact card-front images that are not cleared for redistribution
- Rules text that is not printed on cards
- Rules clarifications from FAQ documents that are not card errata

## Release Certification

This release was certified through Milestone `35.7a.7`.

Certification summary:

- Production JSON files audited: `191`
- Files under `image/`: `384`
- Historical ESLint gate: `PASSED`
- Release certification: `STRICT_GRANTED`
- UTF-8 BOM normalization completed before final release packaging
- Final release archive uses the original repository-style top-level layout

Release asset:

```text
star-wars-armada-data-2025.01-final.zip
```

SHA256:

```text
7464DFF9D4C7026EA541DC20B0D18E3C39BA5AF8DCF9A31C63329767C2916086
```

## Testing

Install dependencies and run:

```bash
npm test
```

The test command runs ESLint against the JSON data files.

## Corrections

Corrections are welcome. Please submit pull requests with clear source references for any data changes.

For image additions, include provenance and redistribution status. Do not add card-front images unless they are cleared for redistribution.

## References

- Original repository: https://github.com/rkbodenner/star-wars-armada-data
- X-Wing data schema inspiration: https://github.com/guidokessels/xwing-data
- Armada FAQ 5.1.1: https://images-cdn.fantasyflightgames.com/filer_public/a8/52/a8529093-17c3-439b-8710-04f2de309e67/armada_faq_v511-compressed.pdf
- Star Wars Armada Wiki: https://starwars-armada.fandom.com/

## Legal

All Star Wars: Armada images, card text, names, and related intellectual property are Copyright and Trademark Lucasfilm Ltd. and/or their respective rights holders.

This repository is an unofficial structured data project and is not affiliated with, endorsed by, or sponsored by Lucasfilm Ltd., Fantasy Flight Games, Atomic Mass Games, or Asmodee.
