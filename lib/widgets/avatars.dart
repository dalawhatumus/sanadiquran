import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import 'ui.dart';

/// The four avatar sets: male/female × student/teacher (assets/avatars).
List<String> avatarsFor(UserRole? role, Gender? gender) {
  final r = role == UserRole.teacher ? 't' : 's';
  final g = gender == Gender.female ? 'f' : 'm';
  return [for (var i = 1; i <= 6; i++) '$g$r$i'];
}

/// Pictures for the sample people in this test build (the other side of a
/// call is always the same gender as the user).
String sampleTeacherAvatar(bool female) => female ? 'ft1' : 'mt1';
String sampleStudentAvatar(bool female) => female ? 'fs1' : 'ms1';

/// A grid of the user's avatar set, plus "initials" as the first choice.
class AvatarGrid extends ConsumerWidget {
  const AvatarGrid({super.key, required this.selected, required this.onPick});

  final String? selected;
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final (role, gender, name) = ref.watch(settingsProvider.select((x) => (x.role, x.gender, x.name)));
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    final options = <String?>[null, ...avatarsFor(role, gender)];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final id in options)
          Semantics(
            button: true,
            selected: selected == id,
            label: id == null ? s.useInitials : s.pictureN(options.indexOf(id)),
            excludeSemantics: true,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onPick(id),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected == id ? t.primary : Colors.transparent, width: 4),
                ),
                child: Stack(
                  children: [
                    Avatar(initial, size: 72, image: id),
                    if (selected == id)
                      PositionedDirectional(
                        end: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: t.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: t.surface, width: 2),
                          ),
                          child: Icon(Icons.check_rounded, size: 22, color: t.onPrimary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Bottom sheet to change the profile picture (from Settings).
Future<void> showAvatarPicker(BuildContext context, WidgetRef ref) {
  final s = S.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Consumer(
          builder: (ctx, ref, _) {
            final current = ref.watch(settingsProvider.select((x) => x.avatar));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WordSafeText(s.choosePicture, style: Theme.of(ctx).textTheme.headlineSmall),
                const SizedBox(height: 16),
                AvatarGrid(
                  selected: current,
                  onPick: (id) {
                    ref.read(settingsProvider.notifier).update((x) => x.copyWith(avatar: id, clearAvatar: id == null));
                    Navigator.pop(ctx);
                  },
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
