import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../backend/backend.dart';
import '../backend/photos.dart';
import '../core/log.dart';
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

/// Takes a photo ([camera]) or picks one from the gallery, made small: at
/// most 320 pixels and compressed. Null if the person cancels. Overridden in
/// tests.
final photoPickerProvider = Provider<Future<Uint8List?> Function({required bool camera})>(
  (ref) => ({required camera}) async {
    final file = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 320,
      maxHeight: 320,
      imageQuality: 75,
      preferredCameraDevice: CameraDevice.front,
      requestFullMetadata: false,
    );
    return file?.readAsBytes();
  },
);

/// Sets the profile picture to a drawn avatar (or initials, for null), and
/// deletes the person's own photo from the server if they had one.
void setDrawnAvatar(WidgetRef ref, String? id) {
  final before = ref.read(settingsProvider).avatar;
  ref.read(settingsProvider.notifier).update((x) => x.copyWith(avatar: id, clearAvatar: id == null));
  if (photoOwner(before) != null) {
    ref.read(backendProvider).deleteOwnPhoto().catchError((Object e) => logIssue('Photo not deleted: $e'));
  }
}

/// Asks camera or gallery, then saves the photo as the profile picture.
/// Returns true if it was saved.
Future<bool> pickOwnPhoto(BuildContext context, WidgetRef ref) async {
  final s = S.of(context);
  final camera = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final tt = Theme.of(ctx).textTheme;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WordSafeText(s.ownPhoto, style: tt.headlineSmall),
              const SizedBox(height: 8),
              Text(s.photoRules, style: tt.bodyMedium),
              const SizedBox(height: 16),
              BigButton(
                label: s.takePhoto,
                icon: Icons.photo_camera_rounded,
                onPressed: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 10),
              BigButton(
                label: s.choosePhoto,
                icon: Icons.photo_library_rounded,
                kind: ButtonKind.outline,
                onPressed: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (camera == null || !context.mounted) return false;
  Uint8List? bytes;
  try {
    bytes = await ref.read(photoPickerProvider)(camera: camera);
  } catch (e) {
    logIssue('Photo not picked: $e');
  }
  if (bytes == null || !context.mounted) return false;
  if (bytes.length > maxPhotoBytes) {
    toast(context, s.photoFailed);
    return false;
  }
  toast(context, s.photoSaving);
  try {
    final avatar = await ref.read(backendProvider).savePhoto(bytes);
    rememberPhoto(avatar, bytes);
    ref.read(settingsProvider.notifier).update((x) => x.copyWith(avatar: avatar));
    return true;
  } catch (e) {
    logIssue('Photo not saved: $e');
    if (context.mounted) toast(context, s.photoFailed);
    return false;
  }
}

/// A grid of the user's avatar set: "initials" first, then their own photo,
/// then the drawn pictures.
class AvatarGrid extends ConsumerWidget {
  const AvatarGrid({super.key, required this.selected, this.onPicked});

  final String? selected;

  /// Called after a choice is saved.
  final VoidCallback? onPicked;

  static const _own = '#own';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final (role, gender, name) = ref.watch(settingsProvider.select((x) => (x.role, x.gender, x.name)));
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    final hasPhoto = photoOwner(selected) != null;
    final options = <String?>[null, _own, ...avatarsFor(role, gender)];

    Widget tile(String? id) {
      final isSelected = id == _own ? hasPhoto : selected == id;
      final Widget picture;
      if (id == _own) {
        picture = hasPhoto
            ? Avatar(initial, size: 72, image: selected)
            : Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.tint,
                  border: Border.all(color: t.primary, width: 2),
                ),
                child: Icon(Icons.add_a_photo_rounded, size: 32, color: t.primary),
              );
      } else {
        picture = Avatar(initial, size: 72, image: id);
      }
      return Semantics(
        button: true,
        selected: isSelected,
        label: id == null
            ? s.useInitials
            : id == _own
            ? s.ownPhoto
            : s.pictureN(options.indexOf(id) - 1),
        excludeSemantics: true,
        child: InkWell(
          key: id == _own ? const ValueKey('own-photo') : null,
          customBorder: const CircleBorder(),
          onTap: () async {
            if (id == _own) {
              if (await pickOwnPhoto(context, ref)) onPicked?.call();
            } else {
              setDrawnAvatar(ref, id);
              onPicked?.call();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? t.primary : Colors.transparent, width: 4),
            ),
            child: Stack(
              children: [
                picture,
                if (isSelected)
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
      );
    }

    return Wrap(spacing: 12, runSpacing: 12, children: [for (final id in options) tile(id)]);
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
                  onPicked: () {
                    if (ctx.mounted) Navigator.pop(ctx);
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
