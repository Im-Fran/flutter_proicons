/// ProIcons for Flutter: SVG icons grouped by category.
///
/// ```dart
/// ProIcon(ProIcons.airplane)
/// ```
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

part 'src/proicons.g.dart';

/// The SVG source of a ProIcons icon, as found in [ProIcons].
///
/// Unlike Flutter's [IconData], which points to a glyph of an icon font, this
/// holds the whole SVG.
extension type const ProIconData(String svg) {}

/// An icon of the [proicons] catalog with its description and category.
typedef ProIconEntry = ({
  String name,
  String description,
  ProIconCategory category,
  ProIconData icon,
});

/// A ProIcons icon, sized and colored like Flutter's [Icon]: [size] and
/// [color] default to the ambient [IconTheme].
class ProIcon extends StatelessWidget {
  /// Creates an icon from [ProIcons].
  const ProIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  /// The icon to draw, e.g. `ProIcons.airplane`.
  final ProIconData icon;

  /// Width and height of the icon. Defaults to [IconThemeData.size].
  final double? size;

  /// Color of the icon. Defaults to [IconThemeData.color].
  final Color? color;

  /// Label read by screen readers. The icon is excluded from semantics when
  /// null, as with [Icon].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = this.size ?? theme.size ?? 24;
    var color = this.color ?? theme.color!;
    final opacity = theme.opacity ?? 1;
    if (opacity != 1) color = color.withValues(alpha: color.a * opacity);

    // srcIn tints the picture at paint time, so each SVG is parsed only once
    // no matter how many colors it is drawn with.
    return SvgPicture.string(
      icon.svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
