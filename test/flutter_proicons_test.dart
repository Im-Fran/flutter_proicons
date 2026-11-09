import 'package:flutter/material.dart';
import 'package:flutter_proicons/flutter_proicons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

SvgPicture _picture(WidgetTester tester) =>
    tester.widget<SvgPicture>(find.byType(SvgPicture));

/// `categories.ts` of ProIcons 4.13.7.
const _upstreamCategories = {
  'Accents', 'Actions', 'Activities', 'Arrows', 'Business',
  'Communication & Cloud', 'Design', 'Development', 'Emojis', 'Files',
  'Food & Drink', 'Gestures', 'Layout', 'Logos & Brands', 'Math & Numbers',
  'Media', 'Miscellaneous', 'Nature', 'Objects', 'Organization',
  'Places & Transportation', 'Security', 'Shapes', 'Status',
  'System & Interface', 'Technology', 'Text', 'Weather', 'Window', //
};

void main() {
  group('ProIcon', () {
    testWidgets('inherits size, color and opacity from IconTheme', (
      tester,
    ) async {
      await tester.pumpWidget(
        const IconTheme(
          data: IconThemeData(size: 40, color: Color(0xFF123456), opacity: 0.5),
          child: ProIcon(ProIcons.airplane),
        ),
      );
      final picture = _picture(tester);
      expect(picture.width, 40);
      expect(picture.height, 40);
      expect(
        picture.colorFilter,
        ColorFilter.mode(
          const Color(0xFF123456).withValues(alpha: 0.5),
          BlendMode.srcIn,
        ),
      );
    });

    testWidgets('explicit size and color win over IconTheme', (tester) async {
      await tester.pumpWidget(
        const IconTheme(
          data: IconThemeData(size: 40, color: Color(0xFF123456)),
          child: ProIcon(ProIcons.add, size: 16, color: Color(0xFFFF0000)),
        ),
      );
      final picture = _picture(tester);
      expect(picture.width, 16);
      expect(
        picture.colorFilter,
        const ColorFilter.mode(Color(0xFFFF0000), BlendMode.srcIn),
      );
    });

    testWidgets('theme opacity multiplies the alpha of an explicit color', (
      tester,
    ) async {
      await tester.pumpWidget(
        const IconTheme(
          data: IconThemeData(size: 24, color: Color(0xFF000000), opacity: 0.5),
          child: ProIcon(ProIcons.add, color: Color(0x80FF0000)),
        ),
      );
      expect(
        _picture(tester).colorFilter,
        ColorFilter.mode(
          const Color(0x80FF0000).withValues(alpha: 0.5 * 128 / 255),
          BlendMode.srcIn,
        ),
      );
    });

    testWidgets('is excluded from semantics unless labeled', (tester) async {
      // Semantics with a label needs a text direction on older Flutter.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ProIcon(ProIcons.airplane),
        ),
      );
      expect(_picture(tester).excludeFromSemantics, isTrue);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ProIcon(ProIcons.airplane, semanticLabel: 'Vuelo'),
        ),
      );
      expect(_picture(tester).excludeFromSemantics, isFalse);
      expect(_picture(tester).semanticsLabel, 'Vuelo');
    });
  });

  group('catalog', () {
    test('has every icon and every upstream category', () {
      expect(proicons, hasLength(544));
      expect(ProIconCategory.values, hasLength(29));
      expect(
        ProIconCategory.values.map((c) => c.label).toSet(),
        _upstreamCategories,
      );
      expect(
        proicons.map((e) => e.category).toSet(),
        ProIconCategory.values.toSet(),
        reason: 'no empty category',
      );
    });

    test('has unique, non-empty names and SVGs', () {
      expect(proicons.map((e) => e.name).toSet(), hasLength(proicons.length));
      expect(
        proicons.map((e) => e.icon.svg).every((s) => s.startsWith('<svg')),
        isTrue,
      );
      expect(proicons.every((e) => e.name.isNotEmpty), isTrue);
    });

    test('keeps original names and descriptions', () {
      final names = proicons.map((e) => e.name);
      expect(names, containsAll(['Wi-Fi', 'X (Twitter)', 'Add Circle']));
      expect(proicons.firstWhere((e) => e.name == 'Add'), (
        name: 'Add',
        description: 'Plus, Create, New, Addition',
        category: ProIconCategory.actions,
        icon: ProIcons.add,
      ));
      expect(ProIconCategory.communicationCloud.label, 'Communication & Cloud');
    });

    testWidgets('all SVGs parse', (tester) async {
      await tester.runAsync(() async {
        for (final e in proicons) {
          await SvgStringLoader(e.icon.svg).loadBytes(null);
        }
      });
    });
  });
}
