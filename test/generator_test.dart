import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/generate.dart';

/// `flutter test` runs inside flutter_tester, so `dart` comes from the PATH.
Future<bool> _dartFormat(File file) async =>
    (await Process.run('dart', ['format', file.path])).exitCode == 0;

Object? _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync());

Map<String, Object?> _entry({String svg = '<svg></svg>'}) => {
  'description': '',
  'category': 'Actions',
  'icon': svg,
};

Matcher _fails(String containing) => throwsA(
  isA<GeneratorError>().having(
    (e) => e.message,
    'message',
    contains(containing),
  ),
);

void main() {
  late Directory tmp;
  late File out;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('proicons_test_');
    out = File('${tmp.path}/proicons.g.dart');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<List<IconSpec>> generate(Object? catalog, Object? lock) =>
      generateFile(
        out,
        catalog: catalog,
        lock: lock,
        tag: 't1',
        commit: 'c' * 40,
        hasSvg: (_) => true,
        format: _dartFormat,
      );

  group('dartName', () {
    test('lowerCamelCases words and punctuation', () {
      expect(dartName('Add'), 'add');
      expect(dartName('Add Circle'), 'addCircle');
      expect(dartName('Wi-Fi'), 'wiFi');
      expect(dartName('X (Twitter)'), 'xTwitter');
      expect(dartName('Logos & Brands'), 'logosBrands');
    });

    test('does not preserve acronyms', () {
      expect(dartName('PDF'), 'pdf');
      expect(dartName('PDF 2'), 'pdf2');
      expect(dartName('QR Code'), 'qrCode');
      expect(dartName('NodeJS'), 'nodejs');
    });

    test('avoids leading digits and reserved words', () {
      expect(dartName('3D Box'), 'i3dBox');
      expect(dartName('Class'), 'classIcon');
      expect(dartName('Switch'), 'switchIcon');
      expect(dartName('Hash Code'), 'hashCodeIcon');
      expect(dartName('Label'), 'labelIcon');
    });

    test('rejects names without letters or digits', () {
      expect(() => dartName('()'), _fails('Cannot derive'));
    });

    test('detects colliding identifiers', () {
      expect(identifiers(['Add Circle', 'Add Square']), hasLength(2));
      expect(
        () => identifiers(['Add Circle', 'Add-Circle']),
        _fails('both map to `addCircle`'),
      );
    });
  });

  group('dartLiteral', () {
    test('escapes quotes, backslashes, dollars and line breaks', () {
      expect(dartLiteral("a'b\$c\\d\ne\r\tf"), r"'a\'b\$c\\d\ne\r\tf'");
      expect(dartLiteral('\u0001'), r"'\u{1}'");
    });

    test('evaluates back to the original string', () async {
      const original = "<svg a='1' b=\"2\" c=\"\$x\\y\">\n\t\u0001é</svg>";
      final script = File('${tmp.path}/main.dart')
        ..writeAsStringSync(
          "import 'dart:io';\n"
          'void main() => stdout.write(${dartLiteral(original)});\n',
        );
      final res = await Process.run('dart', [script.path]);
      expect(res.stderr, '');
      expect(res.stdout, original);
    });
  });

  group('parseCatalog', () {
    test('sorts by name and follows deprecations one step', () {
      final icons = parseCatalog(
        _fixture('icons.json'),
        _fixture('icons.lock.json'),
      );
      expect(icons.map((i) => i.name), [
        '3D Box', 'Add', 'Class', 'Gone', 'Old', 'PDF 2', 'Tricky', 'Wi-Fi', //
        'X (Twitter)',
      ]);
      String? alt(String n) => icons.firstWhere((i) => i.name == n).alternative;
      expect(alt('Old'), 'Add');
      expect(alt('Gone'), isNull, reason: 'alternative is not in the catalog');
      expect(alt('Add'), isNull);
    });

    test('allows empty descriptions and keeps category labels', () {
      final icons = parseCatalog(
        _fixture('icons.json'),
        _fixture('icons.lock.json'),
      );
      expect(icons.firstWhere((i) => i.name == '3D Box').description, '');
      expect(icons.map((i) => i.category), contains('Logos & Brands'));
    });

    test('fails on invalid catalogs', () {
      final ok = _entry();
      expect(() => parseCatalog([], null), _fails('JSON object'));
      expect(() => parseCatalog({}, null), _fails('empty'));
      expect(() => parseCatalog({'A': 1}, null), _fails('must be an object'));
      expect(() => parseCatalog({' A': ok}, null), _fails('whitespace'));
      expect(() => parseCatalog({'Á': ok}, null), _fails('ASCII'));
      expect(
        () => parseCatalog({
          'A': {...ok, 'description': null},
        }, null),
        _fails('"description"'),
      );
      expect(
        () => parseCatalog({
          'A': {...ok, 'category': ' '},
        }, null),
        _fails('"category"'),
      );
      expect(
        () => parseCatalog({
          'A': {...ok}..remove('category'),
        }, null),
        _fails('"category"'),
      );
      expect(
        () => parseCatalog({'A': _entry(svg: '<div/>')}, null),
        _fails('<svg>'),
      );
    });

    test('fails on invalid lock metadata', () {
      final catalog = {'A': _entry()};
      expect(() => parseCatalog(catalog, []), _fails('JSON object'));
      expect(
        () => parseCatalog(catalog, {'deprecated': []}),
        _fails('"deprecated" must be an object'),
      );
      expect(
        () => parseCatalog(catalog, {
          'deprecated': {
            'A': {'version': '1'},
          },
        }),
        _fails('"alternative"'),
      );
    });
  });

  group('generated source', () {
    test('has a header, docs, deprecations and escaped literals', () async {
      await generate(_fixture('icons.json'), _fixture('icons.lock.json'));
      final text = out.readAsStringSync();
      expect(
        text,
        contains(
          '// Source: https://github.com/ProCode-Software/proicons @ t1 (${'c' * 40})',
        ),
      );
      expect(text, contains("enum ProIconCategory {"));
      expect(text, contains("logosBrands('Logos & Brands')"));
      expect(text, contains('static const wiFi ='));
      expect(text, contains('static const classIcon ='));
      expect(text, contains('static const i3dBox ='));
      expect(text, contains('icons/svg/x-twitter.svg)'));
      expect(
        text,
        contains(
          "@Deprecated('Use ProIcons.add instead.')\n  static const old =",
        ),
      );
      expect(text, isNot(contains('Missing')));
      expect(text, contains(r"Quote\'s"));
      expect(text, contains(r'\$a\\b'));
      expect(text, contains('Has \\[brackets\\], \\<tags\\> and newlines'));
    });

    test('is deterministic', () async {
      await generate(_fixture('icons.json'), _fixture('icons.lock.json'));
      final first = out.readAsStringSync();
      out.deleteSync();
      await generate(_fixture('icons.json'), _fixture('icons.lock.json'));
      expect(out.readAsStringSync(), first);
    });

    test('fails when a preview SVG does not exist', () {
      final icons = parseCatalog({'A': _entry()}, null);
      expect(
        () => generateSource(
          tag: 't',
          commit: 'c',
          icons: icons,
          hasSvg: (_) => false,
        ),
        _fails('a.svg does not exist'),
      );
    });

    test('fails on identifier collisions', () {
      expect(
        () => generate({'Add Circle': _entry(), 'Add-Circle': _entry()}, null),
        _fails('both map to `addCircle`'),
      );
    });
  });

  group('a failed generation keeps the previous file', () {
    setUp(() => out.writeAsStringSync('previous'));

    void expectUntouched() {
      expect(out.readAsStringSync(), 'previous');
      expect(tmp.listSync().map((e) => e.path), [out.path]);
    }

    test('on invalid metadata', () async {
      await expectLater(generate({}, null), _fails('empty'));
      await expectLater(
        generate({'A': _entry()}, {'deprecated': 1}),
        _fails('deprecated'),
      );
      expectUntouched();
    });

    test('when formatting fails', () async {
      await expectLater(
        generateFile(
          out,
          catalog: _fixture('icons.json'),
          lock: null,
          tag: 't1',
          commit: 'c' * 40,
          hasSvg: (_) => true,
          format: (_) async => false,
        ),
        _fails('dart format failed'),
      );
      expectUntouched();
    });

    test('when the formatted output is not what was generated', () async {
      await expectLater(
        generateFile(
          out,
          catalog: _fixture('icons.json'),
          lock: null,
          tag: 't1',
          commit: 'c' * 40,
          hasSvg: (_) => true,
          format: (f) async {
            f.writeAsStringSync('// GENERATED CODE\n');
            return true;
          },
        ),
        _fails('0 icon constants'),
      );
      expectUntouched();
    });
  });
}
