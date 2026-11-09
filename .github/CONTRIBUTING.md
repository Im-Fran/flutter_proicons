# Contributing to flutter_proicons

Thanks for being here. `flutter_proicons` is a small Flutter package that
turns the [ProIcons](https://github.com/ProCode-Software/proicons) icons into
Dart constants. Most of its code is generated, and the guidelines below are
mostly about keeping it that way.

## Ground rules

These are the constraints the package is built around. A change that breaks one
of them will not be merged, however useful it is:

- **The icon artwork comes from upstream.** Icons are never drawn or edited
  here. Requests for new or different icons belong in
  [ProCode-Software/proicons](https://github.com/ProCode-Software/proicons).
- **Generated code is never edited by hand.** `lib/src/proicons.g.dart` is
  produced by `tool/generate.dart`. Change the generator and regenerate.
- **Icons stay `const` and tree-shakeable.** Each icon is a `static const`, so a
  release build only contains the icons the app references.
- **The only dependency is `flutter_svg`.** A new dependency needs a strong
  reason.

## Getting set up

You need Flutter 3.35 or newer and `git`:

```sh
git clone https://github.com/Im-Fran/flutter_proicons.git
cd flutter_proicons
flutter pub get
(cd example && flutter pub get)
```

Everyday commands:

| Command | What it does |
| --- | --- |
| `dart format .` | Format the code |
| `flutter analyze` | Analyze the package and the example |
| `flutter test` | Run the tests |
| `dart run tool/generate.dart [tag]` | Regenerate the icons from an upstream tag (needs `git` and network) |
| `flutter test test_upstream` | Check that the committed catalog is what the generator produces (needs `git` and network) |
| `cd example && flutter run -d chrome` | Run the icon gallery |
| `dart pub publish --dry-run` | Check what would be published |

CI runs the format check, `flutter analyze`, `flutter test` (on the minimum and
the latest stable Flutter), a publish dry run and a release build of the
example, so all of them must pass before a PR can land.

## Where things live

```
lib/flutter_proicons.dart       ProIcon widget, ProIconData and ProIconEntry
lib/src/proicons.g.dart         generated: icons, categories, proicons list
tool/generate.dart              reads the upstream catalog and generates the code
test/                           widget, catalog and generator tests, with small fixtures
test_upstream/                  regeneration check against upstream (network)
example/                        web gallery of every icon, one tab per category, with search
```

## Updating the icons

`dart run tool/generate.dart [tag]` shallow-clones the upstream tag and reads
`icons/icons.json` (names, descriptions, categories and SVGs) and
`icons/icons.lock.json` (deprecations) from that same checkout. The default tag
and its commit are pinned in `tool/generate.dart`; to move to a new release,
change both there, regenerate, and update the README, the CHANGELOG and the
catalog counts in the tests. The output is deterministic, so running it twice
produces no diff, and a failed run leaves `lib/src/proicons.g.dart` unchanged.

Generator changes need a test with a small fixture in `test/fixtures/`.

## Branches and commits

Branch off `dev`, which is the default branch:

```sh
git checkout dev && git pull
git checkout -b feat/search-by-category
```

Commits follow [Conventional Commits](https://www.conventionalcommits.org),
written in the imperative. PRs are squash-merged, so the PR title becomes the
commit message:

```
feat: add a semanticLabel default for icon-only buttons
fix(tool): fail when two icons map to the same identifier
docs: explain how categories are resolved
```

Common types here: `feat`, `fix`, `refactor`, `docs`, `test`, `build`, `ci`,
`chore`.

## Opening a pull request

1. Make sure format, analysis and tests pass.
2. Push your branch and open a PR against `dev`.
3. Fill in the PR template, and attach screenshots for anything visual, in light
   and dark mode.
4. Keep the PR focused. Unrelated cleanups belong in their own PR.

## Releasing (maintainers)

1. Bump `version` in `pubspec.yaml` and add its entry to `CHANGELOG.md`, in a PR.
2. Tag the merge commit without a `v` prefix: `git tag 1.2.3 && git push origin 1.2.3`.
3. The tag runs CI and then waits for approval of the `pub.dev` environment.
   Approve it from the workflow run page to publish. The one-time pub.dev and
   GitHub setup this needs is described in the header of
   `.github/workflows/publish.yml`.

## Reporting bugs and requesting features

Use the [issue templates](https://github.com/Im-Fran/flutter_proicons/issues/new/choose).
A minimal snippet that reproduces the problem, with the icon you used, is what
makes the difference between a guess and a fix.

Security vulnerabilities go through [SECURITY.md](SECURITY.md) instead, never a
public issue.

## Code of Conduct

Taking part in this project means following the
[Code of Conduct](CODE_OF_CONDUCT.md).
