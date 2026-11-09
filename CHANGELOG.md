## 0.1.1

- Add the iOS platform to the example app and exclude `ios/**` from its analyzer.
- Repository maintenance only (CI, security and community files); no changes to the icons or the public API.

## 0.1.0

- Initial version, generated from [ProIcons 4.13.7](https://github.com/ProCode-Software/proicons/releases/tag/4.13.7) (commit `1477ebca7e618e57bfd7ffc478843d5aa9eb5b95`).
- 544 icons in 29 categories as `ProIcons` constants.
- `ProIcon` widget that follows `IconTheme`, like Flutter's `Icon`.
- `ProIconCategory`, `ProIconEntry` and the `proicons` list to browse the catalog by category, name and description.
- Icons that upstream deprecated with an alternative are marked `@Deprecated`.
- `tool/generate.dart` to regenerate the icons from an upstream tag.
