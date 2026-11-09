# Security Policy

## Supported versions

Only the latest version published on
[pub.dev](https://pub.dev/packages/flutter_proicons) receives fixes. Fixes
land on `dev` and go out in the next release; older versions are not patched.

| Version | Supported |
| --- | --- |
| Latest release | ✅ |
| Anything older | ❌ |

## Reporting a vulnerability

**Please do not open a public issue for a security problem.**

Report it privately through GitHub:
[**Report a vulnerability**](https://github.com/Im-Fran/flutter_proicons/security/advisories/new)
(repository → **Security** → **Advisories** → **Report a vulnerability**).

Helpful things to include:

- What the issue is, and what an attacker gets out of it.
- Steps to reproduce, or a proof of concept.
- The `flutter_proicons` version, and the Flutter and Dart versions.
- Whether it affects the published package, the generator
  (`tool/generate.dart`) or the release workflow.

What to expect:

- An acknowledgement within a few days.
- An assessment and a plan once the report is confirmed.
- A fix in the next release, with credit in the advisory unless you would
  rather not be named.

Please give a reasonable window for a fix before disclosing publicly.

## Scope

The package is small by design, and that shapes what counts:

- It is pure Dart: icons are `const` SVG strings and one widget. There is no
  native code and no platform channel.
- It makes **no network requests** at runtime.
- Its only dependency is [`flutter_svg`](https://pub.dev/packages/flutter_svg),
  which renders the icons.

In scope, for example: a way to make the package execute code or reach the
network, a problem in how the generator (`tool/generate.dart`) handles the SVGs
or the upstream files it reads, or a flaw in the release workflow that lets someone
other than the maintainer publish to pub.dev.

Out of scope: vulnerabilities in Flutter, Dart or `flutter_svg` themselves
(report them to those projects), and the artwork of the icons, which comes from
[ProIcons](https://github.com/ProCode-Software/proicons).
