import 'package:flutter/material.dart';

import '../data/doctor_photos.dart';
import '../state/clinic_store.dart';
import '../models/models.dart';
import '../theme/clinic_style.dart';
import 'clinic_icon.dart';

class CircleIconBtn extends StatelessWidget {
  const CircleIconBtn({super.key, required this.icon, this.onTap, this.size = 44, this.color, this.iconColor});

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.45, color: iconColor ?? ClinicColors.ink),
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding, this.color, this.onTap, this.radius});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? ClinicRadii.card;
    final bg = color ?? ClinicColors.card;
    final showBorder = color == null || color == ClinicColors.card || color == Colors.white;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: softShadow,
      ),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r),
          child: Container(
            padding: padding ?? const EdgeInsets.all(12),
            decoration: showBorder
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(r),
                    border: Border.all(color: ClinicColors.border.withValues(alpha: 0.7)),
                  )
                : null,
            child: child,
          ),
        ),
      ),
    );
  }
}

class PhotoAvatar extends StatelessWidget {
  const PhotoAvatar({super.key, required this.name, this.size = 56, this.photo, this.ring = true});

  final String name;
  final double size;
  final String? photo;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveDoctorPhoto(name: name, existing: photo ?? '');
    final radius = BorderRadius.circular(size / 2.4);

    Widget image;
    if (resolved.isNotEmpty) {
      image = isAssetPhoto(resolved)
          ? Image.asset(
              resolved,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Initials(name: name, size: size),
            )
          : Image.network(
              resolved,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Initials(name: name, size: size),
            );
    } else {
      image = _Initials(name: name, size: size);
    }

    final clipped = ClipRRect(borderRadius: radius, child: SizedBox(width: size, height: size, child: image));
    if (!ring) return clipped;

    return Container(
      width: size + 6,
      height: size + 6,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2.4 + 3),
        color: Colors.white,
        border: Border.all(color: ClinicColors.border),
        boxShadow: [
          BoxShadow(
            color: ClinicColors.primaryDeep.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: clipped,
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.size});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hue = (name.hashCode % 40) + 10;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2.4),
        gradient: LinearGradient(
          colors: [Color.lerp(ClinicColors.accent, ClinicColors.primaryDeep, hue / 80)!, ClinicColors.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name.characters.first,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.36),
      ),
    );
  }
}

class PillFilter extends StatelessWidget {
  const PillFilter({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? ClinicColors.primary : ClinicColors.tint,
          borderRadius: BorderRadius.circular(ClinicRadii.pill),
          border: selected ? null : Border.all(color: ClinicColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : ClinicColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class OrangeButton extends StatelessWidget {
  const OrangeButton({
    super.key,
    required this.label,
    required this.onTap,
    this.expanded = true,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool expanded;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: loading ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor: ClinicColors.primary,
        disabledBackgroundColor: ClinicColors.primary.withValues(alpha: 0.4),
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ClinicRadii.button)),
        textStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800, fontSize: 15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
            )
          else if (icon != null)
            Icon(icon, size: 20),
          if (loading || icon != null) const SizedBox(width: 10),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: ClinicColors.primaryDeep,
        side: const BorderSide(color: ClinicColors.border),
        backgroundColor: ClinicColors.tint,
        minimumSize: const Size(0, 42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ClinicRadii.button)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
    );
  }
}

class AvailableBadge extends StatelessWidget {
  const AvailableBadge({super.key, this.label = 'متاح'});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: ClinicColors.available.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: ClinicColors.available, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class TealTag extends StatelessWidget {
  const TealTag(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: ClinicColors.primaryDeep, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class MobilePageHeader extends StatelessWidget {
  const MobilePageHeader({super.key, required this.title, this.onBack, this.trailing});

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: Row(
        children: [
          CircleIconBtn(
            icon: Icons.arrow_forward_ios,
            size: 42,
            onTap: onBack ??
                () {
                  final store = ClinicScope.of(context);
                  if (store.canGoBack) {
                    store.back();
                  } else {
                    Navigator.maybePop(context);
                  }
                },
          ),
          Expanded(
            child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          trailing ?? const SizedBox(width: 42, height: 42),
        ],
      ),
    );
  }
}

/// عنصر واحد في الشريط السفلي. [icon] إمّا مسار أصل PNG أو [IconData].
/// [primary] يجعله زراً دائرياً بارزاً في منتصف الشريط.
class DockItem {
  const DockItem({
    required this.icon,
    required this.label,
    this.badge = false,
    this.primary = false,
  });

  final Object icon;
  final String label;
  final bool badge;
  final bool primary;
}

class FloatingDock extends StatelessWidget {
  const FloatingDock({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<DockItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: ClinicColors.border),
          boxShadow: [
            BoxShadow(color: ClinicColors.primaryDeep.withValues(alpha: 0.14), blurRadius: 22, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < items.length; i++)
              _DockButton(
                item: items[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({required this.item, required this.selected, required this.onTap});

  final DockItem item;
  final bool selected;
  final VoidCallback onTap;

  Widget _glyph({required Color color, required double size, double opacity = 1}) {
    final icon = item.icon;
    if (icon is String) return ClinicIcon(icon, size: size, opacity: opacity);
    return Icon(icon as IconData, color: color, size: size);
  }

  @override
  Widget build(BuildContext context) {
    if (item.primary) {
      return Semantics(
        label: item.label,
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [ClinicColors.primary, ClinicColors.primaryDeep],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: ClinicColors.primary.withValues(alpha: selected ? 0.5 : 0.32),
                  blurRadius: selected ? 18 : 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _glyph(color: Colors.white, size: 26),
          ),
        ),
      );
    }

    return Semantics(
      label: item.label,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _glyph(
                    color: selected ? ClinicColors.primary : ClinicColors.muted,
                    size: 24,
                    opacity: selected ? 1 : 0.55,
                  ),
                  if (item.badge)
                    Positioned(
                      left: -3,
                      top: -3,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? ClinicColors.primary : ClinicColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: ClinicColors.tint, borderRadius: BorderRadius.circular(ClinicRadii.tile)),
        child: Column(
          children: [
            Icon(icon, color: ClinicColors.primary, size: 20),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class DateChip extends StatelessWidget {
  const DateChip({super.key, required this.day, required this.date, required this.selected, required this.onTap});

  final String day;
  final String date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 58,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? ClinicColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Text(day, style: TextStyle(color: selected ? Colors.white70 : ClinicColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.white : ClinicColors.tint,
                shape: BoxShape.circle,
              ),
              child: Text(date, style: TextStyle(color: selected ? ClinicColors.primary : ClinicColors.ink, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeChip extends StatelessWidget {
  const TimeChip({super.key, required this.time, required this.selected, required this.onTap});

  final String time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? ClinicColors.primary : ClinicColors.tint,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(time, style: TextStyle(color: selected ? Colors.white : ClinicColors.ink, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class FeaturedDoctorCard extends StatelessWidget {
  const FeaturedDoctorCard({super.key, required this.doctor, required this.onTap});

  final Doctor doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photo = resolveDoctorPhoto(id: doctor.id, name: doctor.fullName, existing: doctor.profilePhoto);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClinicRadii.card),
        child:           Ink(
          width: 148,
          decoration: BoxDecoration(
            color: ClinicColors.card,
            borderRadius: BorderRadius.circular(ClinicRadii.card),
            border: Border.all(color: ClinicColors.border.withValues(alpha: 0.65)),
            boxShadow: softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(ClinicRadii.card)),
                      child: photo.isNotEmpty
                          ? (isAssetPhoto(photo)
                              ? Image.asset(photo, fit: BoxFit.cover, errorBuilder: (_, _, _) => _photoFallback())
                              : Image.network(photo, fit: BoxFit.cover, errorBuilder: (_, _, _) => _photoFallback()))
                          : _photoFallback(),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: ClinicColors.star),
                            const SizedBox(width: 2),
                            Text(
                              doctor.rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: ClinicColors.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (doctor.isActive)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: ClinicColors.available,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'د. ${doctor.fullName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: ClinicColors.primaryDeep),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: ClinicColors.muted, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 11, color: ClinicColors.primary.withValues(alpha: 0.8)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            doctor.city.isEmpty ? doctor.clinicName : doctor.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: ClinicColors.muted, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 10, color: ClinicColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ClinicColors.accent, ClinicColors.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        doctor.fullName.isEmpty ? '?' : doctor.fullName.characters.first,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 36),
      ),
    );
  }
}

class SpecialistCard extends StatelessWidget {
  const SpecialistCard({super.key, required this.doctor, required this.onTap, this.highlighted = false});

  final Doctor doctor;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final bg = highlighted ? ClinicColors.primary : Colors.white;
    final fg = highlighted ? Colors.white : ClinicColors.ink;
    final muted = highlighted ? Colors.white70 : ClinicColors.muted;
    final photo = resolveDoctorPhoto(id: doctor.id, name: doctor.fullName, existing: doctor.profilePhoto);

    return SoftCard(
      color: bg,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(ClinicRadii.card)),
                  child: photo.isNotEmpty
                      ? (isAssetPhoto(photo)
                          ? Image.asset(photo, fit: BoxFit.cover, errorBuilder: (_, _, _) => _gridFallback(highlighted))
                          : Image.network(photo, fit: BoxFit.cover, errorBuilder: (_, _, _) => _gridFallback(highlighted)))
                      : _gridFallback(highlighted),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: highlighted ? Colors.white24 : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: highlighted ? Colors.white : ClinicColors.star),
                        const SizedBox(width: 2),
                        Text(
                          doctor.rating.toStringAsFixed(1),
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: highlighted ? Colors.white : ClinicColors.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('د. ${doctor.fullName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(doctor.specialty, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 11)),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 13, color: highlighted ? Colors.white70 : ClinicColors.primary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          doctor.city.isEmpty ? doctor.clinicName : doctor.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Icons.north_east, size: 14, color: highlighted ? Colors.white : ClinicColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridFallback(bool highlighted) {
    return Container(
      color: highlighted ? ClinicColors.primaryDeep : ClinicColors.tint,
      alignment: Alignment.center,
      child: Text(
        doctor.fullName.isEmpty ? '?' : doctor.fullName.characters.first,
        style: TextStyle(color: highlighted ? Colors.white : ClinicColors.primaryDeep, fontWeight: FontWeight.w800, fontSize: 28),
      ),
    );
  }
}
