// lib/widgets/common_widgets.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

// ── Glass Card ────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  const GlassCard({super.key, required this.child, this.padding, this.borderRadius = 20});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
          ),
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

// ── Gradient Card ─────────────────────────────────────────────────────────────
class GradientCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback? onTap;
  const GradientCard({super.key, required this.title, required this.value,
    required this.subtitle, required this.icon, required this.gradient, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: gradient.colors.first.withValues(alpha: 0.4),
              blurRadius: 12, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.7), size: 14),
          ]),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
        ]),
      ),
    );
  }
}

// ── Nav Card ──────────────────────────────────────────────────────────────────
class NavCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final int? badge;
  const NavCard({super.key, required this.label, required this.icon,
    required this.gradient, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: Colors.white, size: 36),
              const SizedBox(height: 10),
              Text(label, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w700, letterSpacing: 0.3)),
            ]),
          ),
          if (badge != null && badge! > 0)
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
                child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg; Color fg; String label;
    switch (status) {
      case 'paid':   bg = AppColors.success.withValues(alpha: 0.15); fg = AppColors.success; label = '✓ Payé'; break;
      case 'late':   bg = AppColors.danger.withValues(alpha: 0.15);  fg = AppColors.danger;  label = '⚠ Retard'; break;
      default:       bg = AppColors.warning.withValues(alpha: 0.15); fg = AppColors.warning; label = '⏳ Impayé';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      if (action != null)
        TextButton(onPressed: onAction,
            child: Text(action!, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w700))),
    ]);
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState({super.key, required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 64, color: AppColors.border),
      const SizedBox(height: 16),
      Text(message, style: const TextStyle(color: AppColors.textGrey, fontSize: 15)),
    ]));
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────
class LoadingCard extends StatelessWidget {
  final double height;
  const LoadingCard({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height, margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16)),
    );
  }
}

// ── White Card ────────────────────────────────────────────────────────────────
class WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  const WhiteCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

// ── Gradient Button ───────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final bool loading;
  const GradientButton({super.key, required this.label, this.icon,
    required this.gradient, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: gradient.colors.first.withValues(alpha: 0.4),
              blurRadius: 8, offset: const Offset(0, 4))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (loading)
            const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          else ...[
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ]),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
String formatAmount(double amount) => '${NumberFormat('#,##0.00').format(amount)} DH';
String formatDate(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);
String formatDateTime(DateTime dt) => DateFormat('dd/MM/yyyy HH:mm').format(dt);
String formatMonth(String mois) {
  final parts = mois.split('-');
  if (parts.length != 2) return mois;
  const months = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
  final m = int.tryParse(parts[1]) ?? 0;
  return '${m > 0 && m < 13 ? months[m] : parts[1]} ${parts[0]}';
}

void showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating));
}

void showSuccess(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating));
}
