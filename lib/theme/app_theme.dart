import 'package:flutter/material.dart';

/// Nocturne design tokens, ported from the Claude Design project
/// (`_ds/nocturne-.../styles.css`).
class AppColors {
  AppColors._();

  static const bg = Color(0xff161826);
  static const surface = Color(0xff232532);
  static const text = Color(0xffe9e9ed);
  static const accent = Color(0xff9184d9);
  static const accent2 = Color(0xffa7a1db);
  static const divider = Color(0x29e9e9ed); // 16% opacity

  static const neutral100 = Color(0xfff3f5fe);
  static const neutral400 = Color(0xffb2b6ca);
  static const neutral500 = Color(0xff9397ab);
  static const neutral600 = Color(0xff75798c);
  static const neutral800 = Color(0xff3f424d);

  static const accent100 = Color(0xfff5f4ff);
  static const accent200 = Color(0xffe7e5fe);
  static const accent300 = Color(0xffd2cefd);
  static const accent800 = Color(0xff423a6a);

  static const accent2_300 = Color(0xffd2cefd);
}

class AppRadius {
  AppRadius._();

  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 14.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    const headingWeight = FontWeight.w500;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.bg,
        primary: AppColors.accent,
        onPrimary: AppColors.bg,
        secondary: AppColors.accent2,
        error: AppColors.accent2_300,
      ),
      dividerColor: AppColors.divider,
      fontFamily: null,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: headingWeight, fontSize: 26, color: AppColors.text),
        titleLarge: TextStyle(fontWeight: headingWeight, fontSize: 22, color: AppColors.text),
        titleMedium: TextStyle(fontWeight: headingWeight, fontSize: 17, color: AppColors.text),
        bodyLarge: TextStyle(fontSize: 15, color: AppColors.text),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.text),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.neutral400),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.9,
          color: AppColors.neutral500,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: AppColors.text),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontWeight: headingWeight, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontWeight: headingWeight, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(AppColors.accent.withValues(alpha: 0.15)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(fontWeight: headingWeight, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.neutral400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        titleTextStyle: const TextStyle(
          fontWeight: headingWeight,
          fontSize: 20,
          color: AppColors.text,
        ),
        contentTextStyle: const TextStyle(fontSize: 14, color: AppColors.text),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.accent),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
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
            ? const [BoxShadow(color: AppColors.neutral800, spreadRadius: 1, blurRadius: 0)]
            : null,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

enum AppTagStyle { neutral, accent, outline }

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
          Text(text, style: TextStyle(fontSize: 11, letterSpacing: 0.2, color: fg)),
        ],
      ),
    );

    if (onTap == null) return tag;
    return GestureDetector(onTap: onTap, child: tag);
  }
}

/// Circular ghost icon button matching Nocturne's `.btn.btn-icon.btn-ghost`.
class AppGhostIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const AppGhostIconButton({super.key, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
      ),
    );
  }
}
