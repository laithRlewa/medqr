import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/doctor_photos.dart';
import '../theme/clinic_style.dart';
import 'clinic_art.dart';

export '../data/labels.dart';
export '../models/models.dart';
export '../theme/clinic_style.dart';
export 'clinic_art.dart';

final dateFmt = DateFormat('d MMM yyyy', 'ar');
final dateTimeFmt = DateFormat('d MMM yyyy · HH:mm', 'ar');
final longDateFmt = DateFormat('d MMMM yyyy', 'ar');
final isoDate = DateFormat('yyyy-MM-dd');

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, required this.subtitle, this.icon, this.actions});

  final String title;
  final String subtitle;
  final IconData? icon;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: ClinicColors.primaryDeep)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ClinicColors.muted)),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return onTap == null ? card : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: card);
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hint, required this.onChanged, this.width = 360});

  final String hint;
  final ValueChanged<String> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
        ),
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint(this.text, {super.key, this.art, this.artHeight = 120});
  final String text;
  final String? art;
  final double artHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (art != null) ...[
              ClinicIllustration(art!, height: artHeight),
              const SizedBox(height: 12),
            ] else ...[
              Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 36),
              const SizedBox(height: 8),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class AvatarCircle extends StatelessWidget {
  const AvatarCircle({super.key, required this.name, this.colors, this.photo, this.radius = 22});

  final String name;
  final String? photo;
  final List<Color>? colors;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final resolved = resolveDoctorPhoto(name: name, existing: photo ?? '');
    final shape = BorderRadius.circular(radius * 0.9);

    Widget child;
    if (resolved.isNotEmpty) {
      child = isAssetPhoto(resolved)
          ? Image.asset(resolved, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => _avatarFallback(size))
          : Image.network(resolved, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => _avatarFallback(size));
    } else {
      child = _avatarFallback(size);
    }

    return Container(
      width: size + 4,
      height: size + 4,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius * 0.9 + 2),
        color: Colors.white,
        border: Border.all(color: ClinicColors.border),
      ),
      child: ClipRRect(borderRadius: shape, child: child),
    );
  }

  Widget _avatarFallback(double size) {
    final palette = colors ?? const [ClinicColors.accent, ClinicColors.primaryDeep];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(gradient: LinearGradient(colors: palette)),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name.characters.first,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: radius * 0.7),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.15,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 1),
          Text(
            value.isEmpty ? '—' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.2, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child, this.icon, this.trailing});

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

Color appointmentColor(String status) => switch (status) {
      'pending' => Colors.amber.shade800,
      'confirmed' => Colors.green.shade700,
      'declined' => Colors.red.shade700,
      'cancelled' => Colors.grey.shade600,
      'completed' => Colors.blue.shade700,
      _ => Colors.grey,
    };

Color notifColor(String type) => switch (type) {
      'diagnosis' || 'visit' => Colors.teal,
      'prescription' => Colors.indigo,
      'access_granted' => Colors.green,
      'access_expired' => Colors.orange,
      'appointment' => Colors.blue,
      'message' => Colors.cyan.shade700,
      'post' || 'follow' => Colors.purple,
      'review' => Colors.amber.shade800,
      'file' => Colors.brown,
      'admin' || 'welcome' => const Color(0xFF14738F),
      _ => Colors.cyan,
    };

IconData notifIcon(String type) => switch (type) {
      'diagnosis' || 'visit' => Icons.medical_services_outlined,
      'prescription' => Icons.medication_outlined,
      'access_granted' => Icons.verified_user_outlined,
      'access_expired' => Icons.timer_off_outlined,
      'appointment' => Icons.event_available_outlined,
      'message' => Icons.chat_bubble_outline_rounded,
      'post' => Icons.article_outlined,
      'follow' => Icons.person_add_alt_1_outlined,
      'review' => Icons.star_outline_rounded,
      'file' => Icons.attach_file_rounded,
      'profile' => Icons.person_outline,
      'admin' => Icons.campaign_outlined,
      'welcome' => Icons.waving_hand_outlined,
      _ => Icons.notifications_outlined,
    };

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void disposeLater(TextEditingController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
}
