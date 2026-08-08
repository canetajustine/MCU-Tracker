import 'package:flutter/material.dart';

import 'data.dart';

/// The poster's palette, carried over so the app and the printout read as the
/// same document. Neutrals are biased blue rather than grey.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.line,
    required this.ink,
    required this.muted,
    required this.dim,
    required this.essential,
    required this.important,
    required this.requiredUniverse,
    required this.upcoming,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color line;
  final Color ink;
  final Color muted;
  final Color dim;

  final Color essential;
  final Color important;
  final Color requiredUniverse;
  final Color upcoming;

  static const AppPalette dark = AppPalette(
    bg: Color(0xFF0A0E1C),
    surface: Color(0xFF121A2E),
    surfaceAlt: Color(0xFF16203A),
    line: Color(0xFF1F2A44),
    ink: Color(0xFFE6ECF7),
    muted: Color(0xFF8A97B4),
    dim: Color(0xFF63708F),
    essential: Color(0xFF3FD68C),
    important: Color(0xFFE9A94A),
    requiredUniverse: Color(0xFF4C8FF7),
    upcoming: Color(0xFFA175F5),
  );

  static const AppPalette light = AppPalette(
    bg: Color(0xFFF4F6FB),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEDF1F8),
    line: Color(0xFFDBE2EF),
    ink: Color(0xFF141A28),
    muted: Color(0xFF57647F),
    dim: Color(0xFF8390AB),
    essential: Color(0xFF0D8A53),
    important: Color(0xFF9C5F0D),
    requiredUniverse: Color(0xFF1B5AC9),
    upcoming: Color(0xFF6733C4),
  );

  Color statusColor(Status status) => switch (status) {
        Status.essential => essential,
        Status.important => important,
        Status.requiredUniverse => requiredUniverse,
        Status.upcoming => upcoming,
      };

  /// Faint wash behind a status chip.
  Color statusTint(Status status) => statusColor(status).withValues(alpha: 0.13);

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? line,
    Color? ink,
    Color? muted,
    Color? dim,
    Color? essential,
    Color? important,
    Color? requiredUniverse,
    Color? upcoming,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      dim: dim ?? this.dim,
      essential: essential ?? this.essential,
      important: important ?? this.important,
      requiredUniverse: requiredUniverse ?? this.requiredUniverse,
      upcoming: upcoming ?? this.upcoming,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      bg: mix(bg, other.bg),
      surface: mix(surface, other.surface),
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      line: mix(line, other.line),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      dim: mix(dim, other.dim),
      essential: mix(essential, other.essential),
      important: mix(important, other.important),
      requiredUniverse: mix(requiredUniverse, other.requiredUniverse),
      upcoming: mix(upcoming, other.upcoming),
    );
  }
}

ThemeData buildTheme(AppPalette palette, Brightness brightness) {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: palette.essential,
    brightness: brightness,
  ).copyWith(surface: palette.bg);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.bg,
    splashFactory: InkSparkle.splashFactory,
    extensions: <ThemeExtension<dynamic>>[palette],
    textTheme: Typography.material2021(platform: TargetPlatform.iOS)
        .black
        .apply(bodyColor: palette.ink, displayColor: palette.ink),
  );
}

/// Convenience accessor: `context.palette`.
extension PaletteOf on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
