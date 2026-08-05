import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';

class _Palette {
  final Color bg;
  final Color surface;
  final Color text;
  final Color accent;
  final Color accent2;
  final Color divider;
  final Color neutral100;
  final Color neutral400;
  final Color neutral500;
  final Color neutral600;
  final Color neutral800;
  final Color accent100;
  final Color accent200;
  final Color accent300;
  final Color accent800;
  final Color accent2_300;

  const _Palette({
    required this.bg,
    required this.surface,
    required this.text,
    required this.accent,
    required this.accent2,
    required this.divider,
    required this.neutral100,
    required this.neutral400,
    required this.neutral500,
    required this.neutral600,
    required this.neutral800,
    required this.accent100,
    required this.accent200,
    required this.accent300,
    required this.accent800,
    required this.accent2_300,
  });
}

// Paletă "verzuie" — verde de frunză proaspătă, potrivit unei aplicații
// despre îngrijirea plantelor.
const _darkPalette = _Palette(
  bg: Color(0xff141a15),
  surface: Color(0xff1e2620),
  text: Color(0xffe8efe9),
  accent: Color(0xff4caf6d),
  accent2: Color(0xff8bc9a0),
  divider: Color(0x29e8efe9), // 16% opacity
  neutral100: Color(0xfff1f7f2),
  neutral400: Color(0xffb3c4b8),
  neutral500: Color(0xff93a89a),
  neutral600: Color(0xff728a78),
  neutral800: Color(0xff334036),
  accent100: Color(0xffe9f7ee),
  accent200: Color(0xffcdeed8),
  accent300: Color(0xffa3ddb8),
  accent800: Color(0xff1f5c37),
  accent2_300: Color(0xffa3ddb8),
);

const _lightPalette = _Palette(
  bg: Color(0xfff3f8f4),
  surface: Color(0xffffffff),
  text: Color(0xff16241a),
  accent: Color(0xff2e7d4f),
  accent2: Color(0xff4c9c6d),
  divider: Color(0x2916241a), // 16% opacity
  neutral100: Color(0xff16241a),
  neutral400: Color(0xff4c5f50),
  neutral500: Color(0xff627566),
  neutral600: Color(0xff7f9384),
  neutral800: Color(0xffdcebe0),
  accent100: Color(0xffe9f7ee),
  accent200: Color(0xffcdeed8),
  accent300: Color(0xffa3ddb8),
  accent800: Color(0xff1f5c37),
  accent2_300: Color(0xffa3ddb8),
);

/// Nocturne design tokens, ported from the Claude Design project
/// (`_ds/nocturne-.../styles.css`). Resolves to a light or dark palette
/// based on the OS-level appearance setting, so any widget can read
/// `AppColors.xxx` directly and stay in sync with day/night without
/// threading a [BuildContext] through.
class AppColors {
  AppColors._();

  static _Palette get _p =>
      PlatformDispatcher.instance.platformBrightness == Brightness.dark
      ? _darkPalette
      : _lightPalette;

  static Color get bg => _p.bg;
  static Color get surface => _p.surface;
  static Color get text => _p.text;
  static Color get accent => _p.accent;
  static Color get accent2 => _p.accent2;
  static Color get divider => _p.divider;

  static Color get neutral100 => _p.neutral100;
  static Color get neutral400 => _p.neutral400;
  static Color get neutral500 => _p.neutral500;
  static Color get neutral600 => _p.neutral600;
  static Color get neutral800 => _p.neutral800;

  static Color get accent100 => _p.accent100;
  static Color get accent200 => _p.accent200;
  static Color get accent300 => _p.accent300;
  static Color get accent800 => _p.accent800;

  static Color get accent2_300 => _p.accent2_300;
}

class AppRadius {
  AppRadius._();

  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 14.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() => _build(Brightness.dark, _darkPalette);

  static ThemeData light() => _build(Brightness.light, _lightPalette);

  static ThemeData _build(Brightness brightness, _Palette p) {
    const headingWeight = FontWeight.w500;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.bg,
      colorScheme: brightness == Brightness.dark
          ? ColorScheme.dark(
              surface: p.bg,
              primary: p.accent,
              onPrimary: p.bg,
              secondary: p.accent2,
              error: p.accent2_300,
            )
          : ColorScheme.light(
              surface: p.bg,
              primary: p.accent,
              onPrimary: p.surface,
              secondary: p.accent2,
              error: p.accent2_300,
            ),
      dividerColor: p.divider,
      fontFamily: null,
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontWeight: headingWeight,
          fontSize: 26,
          color: p.text,
        ),
        titleLarge: TextStyle(
          fontWeight: headingWeight,
          fontSize: 22,
          color: p.text,
        ),
        titleMedium: TextStyle(
          fontWeight: headingWeight,
          fontSize: 17,
          color: p.text,
        ),
        bodyLarge: TextStyle(fontSize: 15, color: p.text),
        bodyMedium: TextStyle(fontSize: 14, color: p.text),
        bodySmall: TextStyle(fontSize: 12, color: p.neutral400),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.9,
          color: p.neutral500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.text,
        elevation: 0,
      ),
      iconTheme: IconThemeData(color: p.text),
      // Buton "tonal" modern: umplere translucidă în culoarea accentului,
      // umbră care se adâncește în repaus și se aplatizează la apăsare —
      // dă senzația fizică de buton apăsat, nu doar o schimbare de culoare.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: const Duration(milliseconds: 110),
          foregroundColor: WidgetStateProperty.all(p.accent),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return p.accent.withValues(alpha: 0.28);
            if (states.contains(WidgetState.hovered)) return p.accent.withValues(alpha: 0.18);
            return p.accent.withValues(alpha: 0.13);
          }),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.resolveWith((states) {
            final pressed = states.contains(WidgetState.pressed);
            return BorderSide(color: p.accent.withValues(alpha: pressed ? 0.25 : 0.55), width: pressed ? 1 : 1.4);
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 0.0;
            if (states.contains(WidgetState.hovered)) return 5.0;
            return 3.0;
          }),
          shadowColor: WidgetStateProperty.all(p.accent.withValues(alpha: 0.45)),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 11)),
          textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: headingWeight, fontSize: 14)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: p.accent,
              side: BorderSide(color: p.accent),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(
                fontWeight: headingWeight,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                p.accent.withValues(alpha: 0.15),
              ),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          textStyle: const TextStyle(fontWeight: headingWeight, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: TextStyle(color: p.neutral400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.accent),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: TextStyle(
          fontWeight: headingWeight,
          fontSize: 20,
          color: p.text,
        ),
        contentTextStyle: TextStyle(fontSize: 14, color: p.text),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1),
    );
  }
}

/// Card matching Nocturne's `.card` / `.card.elev-sm`.
class AppCard extends StatelessWidget {
  final Widget child;
  final bool elevated;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.elevated = false,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: AppColors.neutral800,
                  spreadRadius: 1,
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return _PressableCard(onTap: onTap!, child: card);
  }
}

/// Gives a tappable [AppCard] a slight press-in scale, on top of the usual
/// ink ripple, so tapping a plant/reminder card feels physically pressed.
class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableCard({required this.child, required this.onTap});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

enum AppTagStyle { neutral, accent, outline, selected }

/// Pill tag matching Nocturne's `.tag` variants.
class AppTag extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Widget? leading;
  final AppTagStyle style;
  final VoidCallback? onTap;

  const AppTag({
    super.key,
    required this.text,
    this.icon,
    this.leading,
    this.style = AppTagStyle.neutral,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;
    switch (style) {
      case AppTagStyle.neutral:
        bg = AppColors.neutral800;
        fg = AppColors.neutral100;
        border = null;
        break;
      case AppTagStyle.accent:
        bg = AppColors.accent800;
        fg = AppColors.accent100;
        border = null;
        break;
      case AppTagStyle.outline:
        bg = Colors.transparent;
        fg = AppColors.accent;
        border = Border.all(color: AppColors.accent);
        break;
      case AppTagStyle.selected:
        bg = AppColors.accent2;
        fg = AppColors.bg;
        border = Border.all(color: AppColors.accent2);
        break;
    }

    final tag = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: border,
        borderRadius: BorderRadius.circular(AppRadius.md * 0.75),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(fontSize: 11, letterSpacing: 0.2, color: fg),
          ),
        ],
      ),
    );

    if (onTap == null) return tag;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md * 0.75),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md * 0.75),
        splashColor: fg.withValues(alpha: 0.18),
        highlightColor: fg.withValues(alpha: 0.1),
        onTap: onTap,
        child: tag,
      ),
    );
  }
}

/// Circular ghost icon button matching Nocturne's `.btn.btn-icon.btn-ghost`.
class AppGhostIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const AppGhostIconButton({super.key, required this.icon, this.onPressed});

  @override
  State<AppGhostIconButton> createState() => _AppGhostIconButtonState();
}

class _AppGhostIconButtonState extends State<AppGhostIconButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Material(
          color: _pressed ? AppColors.accent.withValues(alpha: 0.18) : Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onPressed,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(widget.icon, size: 18, color: AppColors.accent),
            ),
          ),
        ),
      ),
    );
  }
}
