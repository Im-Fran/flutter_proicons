## What this changes

<!-- One or two sentences. What behaviour is different after this PR? -->

## Why

<!-- The problem being solved. Link the issue: Closes #123 -->

## How

<!-- The approach, and anything a reviewer would otherwise have to reverse-engineer. -->

## Testing

- [ ] `dart format --set-exit-if-changed .` passes
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] Ran the example (`cd example && flutter run -d chrome`) and checked the affected screens

<!-- If this touches the generator, say which upstream tag you ran it against and run `flutter test test_upstream`. -->

## Screenshots

<!-- Required for visual changes to the widget or the example. Light and dark mode. -->

## Checklist

- [ ] The PR title follows [Conventional Commits](https://www.conventionalcommits.org) (it becomes the squash commit)
- [ ] `lib/src/proicons.g.dart` was regenerated with `dart run tool/generate.dart`, not edited by hand
- [ ] New or changed behaviour is covered by a test
- [ ] No new dependencies beyond `flutter_svg`
- [ ] README or CHANGELOG updated if the public API or behaviour changed
