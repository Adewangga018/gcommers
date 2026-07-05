import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small uppercase kicker label used above section titles in an
/// infographic-style layout (e.g. "RINGKASAN BULAN INI").
class SectionKicker extends StatelessWidget {
  const SectionKicker({super.key, required this.label, this.action});

  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTheme.subtitle(size: 13, color: AppTheme.ink).copyWith(letterSpacing: 0.4),
        ),
        if (action != null) action!,
      ],
    );
  }
}

/// A single data tile for dashboards: icon chip, big value, label and an
/// optional trend/delta line. Designed to sit in a row of 2+ to read like
/// an infographic stat block rather than a plain card.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.accent = AppTheme.tertiaryGreen,
    this.accentSoft = AppTheme.tertiaryGreenSoft,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final Color accent;
  final Color accentSoft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: accentSoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 14),
          // Nilai bisa panjang (mis. total harga puluhan juta) — scale-down agar tetap 1 baris
          // dan tidak terpotong di tengah angka.
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: AppTheme.title(size: 20), maxLines: 1),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.body(size: 12, color: AppTheme.muted)),
          const Spacer(),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(caption!, style: AppTheme.body(size: 11, color: accent, weight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}

/// A horizontal proportion bar with a label and value, used to visualise
/// a share of a whole (e.g. status breakdown) in an infographic style.
class ProgressBarRow extends StatelessWidget {
  const ProgressBarRow({
    super.key,
    required this.label,
    required this.value,
    required this.fraction,
    this.color = AppTheme.tertiaryGreen,
  });

  final String label;
  final String value;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.body(size: 13, weight: FontWeight.w600)),
            Text(value, style: AppTheme.body(size: 13, color: AppTheme.muted)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction.clamp(0, 1),
            minHeight: 8,
            backgroundColor: AppTheme.tertiaryGreenSoft,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// Rounded pill used to surface a status with a colour-coded background,
/// shared across dashboards/history/order screens.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: AppTheme.body(size: 11, color: color, weight: FontWeight.w700),
      ),
    );
  }
}
