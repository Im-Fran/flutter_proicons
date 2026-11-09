<div align="center">

# flutter_proicons

**ProIcons for Flutter: 544 SVG icons in 29 categories, generated from the official repository.**

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

</div>

---

## Description

[ProIcons](https://procode-software.github.io/proicons/) is an open source icon set on a 24×24 grid. `flutter_proicons` brings its icons to Flutter as ready-to-use constants and a `ProIcon` widget that behaves like Flutter's own `Icon`.

The code is not written by hand: `tool/generate.dart` reads the catalog of a ProIcons release and generates every icon constant. Updating to a new upstream release is one command.

This is an unofficial wrapper. It is not affiliated with or endorsed by ProCode.

## Features

- **544 icons** — `ProIcons`, one `const` per icon.
- **Works like `Icon`** — `ProIcon` takes its size, color and opacity from the ambient `IconTheme`, and is excluded from semantics unless you give it a `semanticLabel`.
- **Tree-shakeable** — each icon is a `static const`, so only the icons you reference end up in a release build.
- **29 categories** — `ProIconCategory` and the `proicons` list (with names and descriptions) let you build galleries and search without maintaining your own index.
- **Documented in the IDE** — every constant has a doc comment with its category, description and a preview image.
- **Offline** — icons are Dart constants; nothing is fetched at runtime.
- **Regenerable** — one script rebuilds everything from any upstream tag.

## Requirements

- Flutter `>=3.35.0`
- Dart `^3.9.0`

Icons are rendered with [`flutter_svg`](https://pub.dev/packages/flutter_svg), which is pulled in automatically.

## Installation

```bash
flutter pub add flutter_proicons
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_proicons/flutter_proicons.dart';

const ProIcon(ProIcons.add);

const ProIcon(
  ProIcons.airplane,
  size: 32,
  color: Colors.blue,
  semanticLabel: 'Vuelo',
);

IconButton(
  icon: const ProIcon(ProIcons.search),
  onPressed: () {},
);
```

Without `size` or `color`, the icon uses the ambient `IconTheme`, so it follows the icon theme set by widgets such as `IconButton` and `AppBar`. The theme's opacity multiplies the alpha of the color.

### `ProIconData` is not `IconData`

Flutter's `IconData` points to a glyph of an icon font. `ProIconData` holds the SVG itself, so `ProIcons` constants only work with `ProIcon`, not with `Icon` or any API that expects an `IconData`. Wrap them in `ProIcon` where a widget is expected, as in `IconButton(icon: const ProIcon(...))`. There is no font to register.

### Icon names

Upstream names are converted to `lowerCamelCase` identifiers:

| Upstream name | Constant |
| --- | --- |
| `Add` | `ProIcons.add` |
| `Add Circle` | `ProIcons.addCircle` |
| `Wi-Fi` | `ProIcons.wiFi` |
| `X (Twitter)` | `ProIcons.xTwitter` |
| `PDF 2` | `ProIcons.pdf2` |
| `NodeJS` | `ProIcons.nodejs` |

Every word is lowercased and then capitalized, so acronyms are not preserved. Punctuation separates words, a name that would start with a digit gets an `i` prefix (`3D Box` → `i3dBox`), and Dart reserved words get an `Icon` suffix (`Class` → `classIcon`). The generator fails if two names map to the same identifier.

### Browsing by category

`proicons` is a list with every icon, its description and its category:

```dart
final actions = proicons.where((e) => e.category == ProIconCategory.actions);

for (final e in actions) {
  print('${e.name} (${e.category.label}): ${e.description}');
  // e.icon is ready to pass to ProIcon
}
```

Names, descriptions and category labels are exactly the upstream ones, including spaces and `&` (`Logos & Brands`). Descriptions may be empty.

> Referencing `proicons` keeps **all** icons in your build, because the list points to every one of them. If you only need a few icons, reference them directly through `ProIcons` and they alone are kept.

The 29 categories are: Accents, Actions, Activities, Arrows, Business, Communication & Cloud, Design, Development, Emojis, Files, Food & Drink, Gestures, Layout, Logos & Brands, Math & Numbers, Media, Miscellaneous, Nature, Objects, Organization, Places & Transportation, Security, Shapes, Status, System & Interface, Technology, Text, Weather and Window.

### Aliases and deprecations

Only entries of upstream's `icons/icons.json` become constants. The aliases that the JavaScript packages resolve (`Plus` → `Add`, `Close` → `Cancel`, ...) are not part of the Dart API, and no alias is resolved recursively: some upstream aliases point to missing icons or to each other.

Icons that upstream deprecated stay available. When the deprecation metadata names an alternative that exists in the catalog, the constant is annotated with `@Deprecated` (for example `ProIcons.book2`, use `ProIcons.book`). Deprecated entries without a usable alternative are not annotated.

### Customization limits

The icons are drawn exactly as published upstream, with their original geometry and stroke width. `ProIcon` only changes size and color. Options of the official JavaScript packages such as `strokeWidth`, corner radius, line caps and joins, or changes to filled elements are **not** implemented, so this package does not have full parity with them.

### Example app

[`example/`](example) is a gallery of every icon with one tab per category and a search box (name and description). It follows the system light or dark theme and targets the web:

```bash
cd example
flutter run -d chrome
```

The gallery uses the full `proicons` list on purpose, so its build contains every icon.

## Source and updating the icons

The icons come from [ProCode-Software/proicons](https://github.com/ProCode-Software/proicons) tag [`4.13.7`](https://github.com/ProCode-Software/proicons/releases/tag/4.13.7) (commit `1477ebca7e618e57bfd7ffc478843d5aa9eb5b95`). The version is never bumped silently: it changes only when `tool/generate.dart` and this README are updated together.

`lib/src/proicons.g.dart` is generated. Do not edit it by hand; regenerate it instead:

```bash
dart run tool/generate.dart          # ProIcons 4.13.7
dart run tool/generate.dart 4.13.8   # any upstream tag (without a `v` prefix)
```

The script needs `git` and network access. It:

1. Shallow-clones the tag and, for the default tag, checks that it points to the pinned commit.
2. Reads `icons/icons.json` (names, descriptions, categories and SVGs) and `icons/icons.lock.json` (deprecations) from that checkout, and checks that the preview SVG of every icon exists.
3. Validates the data, sorts it by name and generates the code in a temporary file.
4. Formats and checks that file, and only then replaces `lib/src/proicons.g.dart`.

Nothing is read from a mutable source, so the tag alone determines the output, which is identical for the same Dart version. If anything fails, the script exits with an error and the previous catalog is left untouched.

## Tests

```bash
flutter test                  # offline
flutter test test_upstream    # regenerates from upstream and compares (network)
```

The offline tests cover the widget (theme inheritance, explicit overrides, semantics), the catalog (544 icons, 29 categories, every SVG parses) and the generator, using small fixtures (name conversion, escaping, invalid metadata, deterministic output, and keeping the previous file when a run fails).

## Contributing

Issues and pull requests are welcome. Icon artwork comes from upstream, so changes to the icons themselves belong in [ProCode-Software/proicons](https://github.com/ProCode-Software/proicons). Setup, commands and the pull request flow are in [CONTRIBUTING.md](.github/CONTRIBUTING.md), and everyone taking part follows the [Code of Conduct](.github/CODE_OF_CONDUCT.md).

## Security

Please report vulnerabilities privately instead of opening a public issue. See [SECURITY.md](.github/SECURITY.md).

## License and attributions

Distributed under the MIT license, see [LICENSE](LICENSE).

- The icons are © 2025 ProCode, published under the MIT license in [ProCode-Software/proicons](https://github.com/ProCode-Software/proicons) ([license](https://raw.githubusercontent.com/ProCode-Software/proicons/4.13.7/LICENSE)). Their notice is preserved in `LICENSE` and in the header of the generated file.
- The `ProIcon` widget and the generator are adapted from [flutter_majesticons](https://github.com/Im-Fran/flutter_majesticons), by the same author (MIT).
- Rendering is done by [`flutter_svg`](https://pub.dev/packages/flutter_svg) (MIT).

---

<div align="center">
  <a href="https://franciscosolis.cl">
    <img src="https://cdn.franciscosolis.cl/brand/svg/fs-mark.svg" alt="FranciscoSolis E.I.R.L." width="40" height="40">
  </a>
  <br>
  <sub>Built by <a href="https://franciscosolis.cl"><strong>FranciscoSolis E.I.R.L.</strong></a></sub>
  <br>
  <sub>© 2026 FranciscoSolis E.I.R.L. — MIT</sub>
</div>
