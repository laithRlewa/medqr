import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/brand_palette.dart';

export '../data/labels.dart';
export '../theme/brand_palette.dart';

final dateFmt = DateFormat('d MMM yyyy', 'ar');
final dateTimeFmt = DateFormat('d MMM yyyy · HH:mm', 'ar');
final longDateFmt = DateFormat('d MMMM yyyy', 'ar');

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, required this.subtitle, this.icon});

  final String title;
  final String subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
              ],
            ),
          ),
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
  const EmptyHint(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 36),
            const SizedBox(height: 8),
            Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
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
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide.none,
    );
  }
}

class AvatarCircle extends StatelessWidget {
  const AvatarCircle({super.key, required this.name, this.colors, this.photo});

  final String name;
  final String? photo;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final palette = colors ?? const [BrandPalette.accent, BrandPalette.primaryDeep];
    if (photo != null && photo!.isNotEmpty) {
      return CircleAvatar(radius: 22, backgroundImage: NetworkImage(photo!));
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: palette)),
        child: Center(
          child: Text(name.isEmpty ? '?' : name.characters.first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

Color doctorStatusColor(String status) => switch (status) {
      'pending' => Colors.amber.shade800,
      'approved' => Colors.green.shade700,
      'suspended' => Colors.red.shade700,
      _ => Colors.grey,
    };

class ColorField extends StatefulWidget {
  const ColorField({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const swatches = ['#0891b2', '#2563eb', '#0f766e', '#7c3aed', '#dc2626', '#ea580c', '#e0f2fe'];

  @override
  State<ColorField> createState() => _ColorFieldState();
}

class _ColorFieldState extends State<ColorField> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant ColorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && controller.text != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        controller.value = TextEditingValue(text: widget.value);
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: widget.onChanged,
          decoration: const InputDecoration(labelText: 'رمز اللون', isDense: true),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final hex in ColorField.swatches)
              GestureDetector(
                onTap: () {
                  controller.text = hex;
                  widget.onChanged(hex);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _hex(hex),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: widget.value.toLowerCase() == hex ? Colors.black : Colors.transparent, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Color _hex(String hex) {
    var v = hex.replaceAll('#', '');
    if (v.length == 6) v = 'FF$v';
    return Color(int.parse(v, radix: 16));
  }
}

class PeriodChips<T> extends StatelessWidget {
  const PeriodChips({super.key, required this.value, required this.options, required this.onChanged});

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        for (final opt in options)
          ChoiceChip(
            label: Text(opt.$2),
            selected: value == opt.$1,
            onSelected: (_) => onChanged(opt.$1),
          ),
      ],
    );
  }
}
