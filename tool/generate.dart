// Generates lib/src/proicons.g.dart from the official ProIcons repository.
//
//   dart run tool/generate.dart [tag]
//
// Everything comes from one shallow git checkout of the tag: the catalog
// (`icons/icons.json`, which embeds the SVGs and the categories), the
// deprecation metadata (`icons/icons.lock.json`) and the preview SVG files.
// Nothing is read from a mutable source, so the tag alone fixes the output.
//
// The generated file is only replaced after the new one was written to a
// temporary file, formatted and checked, so a failed run leaves the previous
// catalog untouched.
import 'dart:convert';
import 'dart:io';

const _repo = 'https://github.com/ProCode-Software/proicons';
const _rawBase = 'https://raw.githubusercontent.com/ProCode-Software/proicons';
const _licenseNotice = 'MIT, Copyright (c) 2025 ProCode';
const defaultTag = '4.13.7';

/// Commits the default tag is known to point to. A tag that moved is an error.
const pinnedCommits = {'4.13.7': '1477ebca7e618e57bfd7ffc478843d5aa9eb5b95'};

/// Identifiers a generated static member or enum value cannot use: Dart
/// reserved words plus members inherited from Object and Enum, and the
/// `label` field of the category enum.
const _reserved = {
  'assert', 'await', 'break', 'case', 'catch', 'class', 'const', 'continue',
  'default', 'do', 'else', 'enum', 'extends', 'false', 'final', 'finally',
  'for', 'if', 'in', 'is', 'new', 'null', 'rethrow', 'return', 'super',
  'switch', 'this', 'throw', 'true', 'try', 'var', 'void', 'while', 'with',
  'yield', //
  'hashCode', 'runtimeType', 'toString', 'noSuchMethod', 'values', 'index',
  'name', 'label',
};

/// A failure that should be reported to the user without a stack trace.
class GeneratorError implements Exception {
  GeneratorError(this.message);
  final String message;
  @override
  String toString() => message;
}

Never _fail(String message) => throw GeneratorError(message);

/// One validated entry of `icons/icons.json`.
class IconSpec {
  IconSpec({
    required this.name,
    required this.description,
    required this.category,
    required this.svg,
    this.alternative,
  });

  final String name;
  final String description;
  final String category;
  final String svg;

  /// Name of the icon that replaces this one, when upstream deprecated it and
  /// the replacement exists in the catalog.
  final String? alternative;
}

Future<void> main(List<String> args) async {
  if (args.length > 1) {
    stderr.writeln('usage: dart run tool/generate.dart [tag]');
    exitCode = 64;
    return;
  }
  final tag = args.isEmpty ? defaultTag : args.first;
  Directory? checkout;
  try {
    checkout = await Directory.systemTemp.createTemp('proicons_');
    final commit = await _checkout(tag, checkout);
    String read(String path) {
      final file = File('${checkout!.path}/$path');
      if (!file.existsSync()) _fail('$path is missing in $_repo@$tag.');
      return file.readAsStringSync();
    }

    final out = File.fromUri(
      Platform.script.resolve('../lib/src/proicons.g.dart'),
    );
    final icons = await generateFile(
      out,
      catalog: _decode(read('icons/icons.json'), 'icons/icons.json'),
      lock: _decode(read('icons/icons.lock.json'), 'icons/icons.lock.json'),
      tag: tag,
      commit: commit,
      hasSvg: (slug) =>
          File('${checkout!.path}/icons/svg/$slug.svg').existsSync(),
    );
    stdout.writeln(
      'Wrote ${out.path}: ${icons.length} icons, '
      '${icons.map((i) => i.category).toSet().length} categories '
      '($tag, ${commit.substring(0, 7)}).',
    );
  } on GeneratorError catch (e) {
    stderr.writeln('error: ${e.message}');
    exitCode = 1;
  } on FileSystemException catch (e) {
    stderr.writeln('error: ${e.message} ${e.path ?? ''}');
    exitCode = 1;
  } finally {
    // Also runs on errors, so no temporary checkout is left behind.
    if (checkout != null && checkout.existsSync()) {
      await checkout.delete(recursive: true);
    }
  }
}

Object? _decode(String text, String what) {
  try {
    return jsonDecode(text);
  } on FormatException catch (e) {
    _fail('$what is not valid JSON: ${e.message}');
  }
}

/// Shallow-clones [tag] into [into] and returns the commit it points to.
Future<String> _checkout(String tag, Directory into) async {
  // Rejects option-like values before they reach git.
  if (!RegExp(r'^[0-9A-Za-z][0-9A-Za-z._-]*$').hasMatch(tag)) {
    _fail('"$tag" is not a valid tag name.');
  }
  final clone = await Process.run('git', [
    'clone', '--quiet', '--depth', '1', '--branch', tag, _repo, into.path, //
  ]);
  if (clone.exitCode != 0) {
    _fail('git clone of $_repo@$tag failed:\n${clone.stderr}');
  }
  final head = await Process.run('git', ['-C', into.path, 'rev-parse', 'HEAD']);
  final commit = (head.stdout as String).trim();
  if (head.exitCode != 0 || !RegExp(r'^[0-9a-f]{40}$').hasMatch(commit)) {
    _fail('Could not resolve the commit of $tag:\n${head.stderr}');
  }
  final expected = pinnedCommits[tag];
  if (expected != null && expected != commit) {
    _fail(
      'Tag $tag points to $commit, expected $expected. Upstream moved the tag.',
    );
  }
  return commit;
}

/// Validates the decoded `icons.json` and `icons.lock.json` and returns the
/// entries sorted by name.
///
/// Only entries of `icons.json` become icons. The `aliases` of the lock file
/// are ignored on purpose, and `deprecated` entries are followed exactly one
/// step: the alternative is used only if it is itself a catalog entry.
List<IconSpec> parseCatalog(Object? catalog, Object? lock) {
  if (catalog is! Map) {
    _fail('icons.json must be a JSON object keyed by icon name.');
  }
  if (catalog.isEmpty) _fail('icons.json is empty.');

  Object? deprecated;
  if (lock != null) {
    if (lock is! Map) _fail('icons.lock.json must be a JSON object.');
    deprecated = lock['deprecated'];
    if (deprecated != null && deprecated is! Map) {
      _fail('icons.lock.json: "deprecated" must be an object.');
    }
  }
  final alternatives = <String, String>{};
  if (deprecated is Map) {
    for (final MapEntry(:key, :value) in deprecated.entries) {
      if (value is! Map || value['alternative'] is! String) {
        _fail(
          'icons.lock.json: deprecated "$key" needs a string "alternative".',
        );
      }
      alternatives['$key'] = value['alternative'] as String;
    }
  }

  final icons = <IconSpec>[];
  for (final MapEntry(:key, :value) in catalog.entries) {
    final name = key as String;
    if (name.trim().isEmpty || name != name.trim()) {
      _fail('Icon name "$name" is empty or has surrounding whitespace.');
    }
    if (name.runes.any((r) => r > 0x7e || r < 0x20)) {
      _fail('Icon name "$name" must be printable ASCII.');
    }
    if (value is! Map) _fail('"$name": entry must be an object.');
    final description = value['description'];
    final category = value['category'];
    final svg = value['icon'];
    if (description is! String) {
      _fail('"$name": "description" must be a string.');
    }
    if (category is! String || category.trim().isEmpty) {
      _fail('"$name": "category" must be a non-empty string.');
    }
    if (svg is! String ||
        !svg.trim().startsWith('<svg') ||
        !svg.trim().endsWith('</svg>')) {
      _fail('"$name": "icon" must be an <svg> element.');
    }
    final alt = alternatives[name];
    icons.add(
      IconSpec(
        name: name,
        description: description,
        category: category,
        svg: svg.trim(),
        alternative: alt != null && alt != name && catalog.containsKey(alt)
            ? alt
            : null,
      ),
    );
  }
  return icons..sort((a, b) => a.name.compareTo(b.name));
}

/// `Add Circle` -> `addCircle`, `Wi-Fi` -> `wiFi`, `PDF 2` -> `pdf2`.
///
/// Splits on anything that is not an ASCII letter or digit, lowercases every
/// word and capitalizes all but the first, so acronyms are not preserved
/// (`NodeJS` -> `nodejs`). A leading digit gets an `i` prefix and reserved
/// words get an `Icon` suffix.
String dartName(String name) {
  final parts = name.split(RegExp('[^a-zA-Z0-9]+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) _fail('Cannot derive an identifier from "$name".');
  var id =
      parts.first.toLowerCase() +
      parts
          .skip(1)
          .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
          .join();
  if (RegExp('^[0-9]').hasMatch(id)) id = 'i$id';
  return _reserved.contains(id) ? '${id}Icon' : id;
}

/// [dartName] for every name, failing if two collapse into the same identifier.
Map<String, String> identifiers(Iterable<String> names) {
  final ids = <String, String>{};
  final owner = <String, String>{};
  for (final name in names) {
    final id = dartName(name);
    final clash = owner[id];
    if (clash != null) _fail('"$name" and "$clash" both map to `$id`.');
    owner[id] = name;
    ids[name] = id;
  }
  return ids;
}

/// [value] as a single-quoted Dart string literal.
String dartLiteral(String value) {
  final b = StringBuffer("'");
  for (final r in value.runes) {
    b.write(switch (r) {
      0x5c => r'\\',
      0x27 => r"\'",
      0x24 => r'\$',
      0x0a => r'\n',
      0x0d => r'\r',
      0x09 => r'\t',
      < 0x20 || 0x7f => '\\u{${r.toRadixString(16)}}',
      _ => String.fromCharCode(r),
    });
  }
  return (b..write("'")).toString();
}

/// [value] as one line of doc comment text.
String _doc(String value) => value
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim()
    .replaceAllMapped(RegExp(r'[\[\]<>\\]'), (m) => '\\${m[0]}');

/// `Add Circle` -> `add-circle`: the file name upstream uses in `icons/svg`.
String svgSlug(String name) => name
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');

/// Validates the decoded upstream files and replaces [out] with the generated
/// code. Throws a [GeneratorError], leaving [out] untouched, if anything fails.
Future<List<IconSpec>> generateFile(
  File out, {
  required Object? catalog,
  required Object? lock,
  required String tag,
  required String commit,
  required bool Function(String slug) hasSvg,
  Future<bool> Function(File file) format = _dartFormat,
}) async {
  final icons = parseCatalog(catalog, lock);
  final source = generateSource(
    tag: tag,
    commit: commit,
    icons: icons,
    hasSvg: hasSvg,
  );
  await writeChecked(out, source, iconCount: icons.length, format: format);
  return icons;
}

/// Returns the unformatted contents of `proicons.g.dart`.
///
/// [hasSvg] tells whether `icons/svg/<slug>.svg` exists in the checkout, so
/// the preview URL of every constant is known to resolve.
String generateSource({
  required String tag,
  required String commit,
  required List<IconSpec> icons,
  required bool Function(String slug) hasSvg,
}) {
  if (icons.isEmpty) _fail('There are no icons to generate.');
  final ids = identifiers(icons.map((i) => i.name));
  final labels = (icons.map((i) => i.category).toSet().toList()..sort());
  final catIds = identifiers(labels);
  for (final i in icons) {
    if (!hasSvg(svgSlug(i.name))) {
      _fail(
        '"${i.name}": icons/svg/${svgSlug(i.name)}.svg does not exist in $tag.',
      );
    }
  }
  String catId(IconSpec i) => 'ProIconCategory.${catIds[i.category]}';

  final b = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Regenerate with: dart run tool/generate.dart $tag')
    ..writeln('// Source: $_repo @ $tag ($commit)')
    ..writeln('// License: $_licenseNotice')
    // The `proicons` list references deprecated constants; older analyzers
    // report that even inside the same library.
    ..writeln('// ignore_for_file: deprecated_member_use_from_same_package')
    ..writeln()
    ..writeln("part of '../flutter_proicons.dart';")
    ..writeln()
    ..writeln('/// Icon categories, as defined by ProIcons.')
    ..writeln('enum ProIconCategory {');
  for (final label in labels) {
    b.writeln('/// ${_doc(label)}\n${catIds[label]}(${dartLiteral(label)}),');
  }
  b
    ..writeln(';')
    ..writeln()
    ..writeln('const ProIconCategory(this.label);')
    ..writeln()
    ..writeln('/// Name of the category as written upstream.')
    ..writeln('final String label;')
    ..writeln('}')
    ..writeln()
    ..writeln('/// The ${icons.length} ProIcons $tag.')
    ..writeln('///')
    ..writeln(
      '/// Pass them to [ProIcon]. Unused icons are tree-shaken from release builds.',
    )
    ..writeln('abstract final class ProIcons {');
  for (final i in icons) {
    final doc = _doc(i.description);
    b
      ..writeln(
        '/// `${_doc(i.name)}` in [${catId(i)}]${doc.isEmpty ? '.' : ': $doc'}',
      )
      ..writeln('///')
      ..writeln(
        '/// ![${_doc(i.name)}]($_rawBase/$tag/icons/svg/${svgSlug(i.name)}.svg)',
      );
    final alt = i.alternative;
    if (alt != null) {
      b.writeln(
        '@Deprecated(${dartLiteral('Use ProIcons.${ids[alt]} instead.')})',
      );
    }
    b.writeln(
      'static const ${ids[i.name]} = ProIconData(${dartLiteral(i.svg)});\n',
    );
  }
  b
    ..writeln('}')
    ..writeln()
    ..writeln(
      '/// Every icon with its description and category, for galleries and search.',
    )
    ..writeln('///')
    ..writeln(
      '/// Referencing this list keeps **all** icons in your build. To ship only the',
    )
    ..writeln(
      '/// ones you use, reference the constants of [ProIcons] directly.',
    )
    ..writeln('const List<ProIconEntry> proicons = [');
  for (final i in icons) {
    b.writeln(
      '(name: ${dartLiteral(i.name)}, description: ${dartLiteral(i.description)}, '
      'category: ${catId(i)}, icon: ProIcons.${ids[i.name]}),',
    );
  }
  return (b..writeln('];')).toString();
}

/// Runs `dart format` on [file] and returns whether it succeeded.
Future<bool> _dartFormat(File file) async {
  final res = await Process.run(Platform.resolvedExecutable, [
    'format',
    file.path,
  ]);
  if (res.exitCode != 0) stderr.write(res.stderr);
  return res.exitCode == 0;
}

/// Writes [source] to [out] only if it formats and passes a sanity check.
///
/// The work happens in a temporary sibling of [out], which is renamed over it
/// last and removed on any failure. [format] is a parameter for the tests.
Future<void> writeChecked(
  File out,
  String source, {
  required int iconCount,
  Future<bool> Function(File file) format = _dartFormat,
}) async {
  out.parent.createSync(recursive: true);
  final tmp = File('${out.path}.tmp.dart');
  try {
    tmp.writeAsStringSync(source);
    if (!await format(tmp)) {
      _fail('dart format failed; ${out.path} was not changed.');
    }
    final formatted = tmp.readAsStringSync();
    final constants = RegExp(
      r'^\s*static const \w+ = ProIconData\(',
      multiLine: true,
    ).allMatches(formatted).length;
    if (!formatted.startsWith('// GENERATED CODE') || constants != iconCount) {
      _fail(
        'The formatted output has $constants icon constants, expected $iconCount; '
        '${out.path} was not changed.',
      );
    }
    tmp.renameSync(out.path);
  } finally {
    if (tmp.existsSync()) tmp.deleteSync();
  }
}
