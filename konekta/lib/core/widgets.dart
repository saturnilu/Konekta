import 'package:flutter/material.dart';
import 'theme.dart';
import 'app_scope.dart';

/// Gradient primary button matching designs.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LinearGradient gradient;
  final double radius;
  final EdgeInsets padding;
  final bool outlined;
  final Color? foreground;
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.gradient = KonektaGradients.pillBlue,
    this.radius = 28,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.outlined = false,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? Colors.white;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          gradient: outlined ? null : gradient,
          color: outlined ? Colors.white : null,
          borderRadius: BorderRadius.circular(radius),
          border: outlined ? Border.all(color: KonektaColors.primary, width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w700)),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, color: fg, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rounded soft-blue text field matching the design inputs.
class KonektaField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final int? maxLines;
  final Widget? suffix;
  final Widget? prefix;
  final ValueChanged<String>? onChanged;
  const KonektaField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.suffix,
    this.prefix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: KonektaColors.textPrimary)),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType ?? TextInputType.text,
          maxLines: obscure ? 1 : maxLines,
          onChanged: onChanged,
          style: const TextStyle(color: KonektaColors.textPrimary, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

class KonektaPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  const KonektaPill({super.key, required this.label, required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: textColor ?? Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class GradientBackground extends StatelessWidget {
  final Widget child;
  final LinearGradient gradient;
  const GradientBackground({super.key, required this.child, this.gradient = KonektaGradients.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: child,
    );
  }
}

class InfoIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const InfoIcon({super.key, required this.icon, this.color = const Color(0xFF7FB8FF), this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 18, height: size + 18,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular((size + 18) / 2)),
      child: Icon(icon, color: color, size: size),
    );
  }
}

class AvatarPlaceholder extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  const AvatarPlaceholder({super.key, required this.text, this.size = 44, this.color = const Color(0xFFB4D6FF)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        text.isEmpty ? '?' : text[0].toUpperCase(),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.42),
      ),
    );
  }
}

class BrandTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badge;
  final String? trailing;
  final VoidCallback? onTap;
  final Color? leadingColor;
  const BrandTile({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.trailing,
    this.onTap,
    this.leadingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              AvatarPlaceholder(text: title, color: leadingColor ?? const Color(0xFFB4D6FF)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          KonektaPill(
                            label: badge!,
                            color: badge == 'OPEN' ? const Color(0xFF6FE0A1) : const Color(0xFFBFD9FF),
                            textColor: badge == 'OPEN' ? Colors.white : const Color(0xFF246FE0),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: KonektaColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Text(trailing!, style: const TextStyle(color: KonektaColors.textMuted, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient card with white rounded border.
class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const GradientCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: KonektaGradients.pillBlue, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: const Color(0xFF4FB6FF).withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4))]),
      padding: padding,
      child: child,
    );
  }
}

/// Small gradient button used in dashboards.
class GradientMiniButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const GradientMiniButton({super.key, required this.label, this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(gradient: KonektaGradients.pillBlue, borderRadius: BorderRadius.circular(28)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: Colors.white, size: 18),
            if (icon != null) const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Helper to read the current user role from AppScope.
class AppSession {
  static bool isBrandOf(BuildContext ctx) => AppScope.of(ctx).role == 'brand';
  static int userIdOf(BuildContext ctx) => AppScope.of(ctx).session.userId ?? 0;
}
