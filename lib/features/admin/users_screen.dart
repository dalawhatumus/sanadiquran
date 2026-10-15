import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/admin.dart';
import '../../backend/backend.dart';
import '../../backend/photos.dart';
import '../../core/countries.dart';
import '../../core/limits.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../messages/messages_screen.dart';

/// Admins find anyone by name, see the details they gave, and pause or
/// restore their account or remove their picture. "WhatsApp community"
/// lists those who asked to join, with their numbers to copy.
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _search = TextEditingController();
  bool _whatsappOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final users = ref.watch(usersProvider);
    final query = _search.text.trim().toLowerCase();
    final list = [
      for (final u in users.value ?? const <UserEntry>[])
        if ((query.isEmpty || u.name.toLowerCase().contains(query) || (u.phone ?? '').contains(query)) &&
            (!_whatsappOnly || (u.whatsapp && u.phone != null)))
          u,
    ];
    return StepScaffold(
      showBack: true,
      content: [
        WordSafeText(s.usersTitle, style: tt.headlineMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: t.text),
          decoration: InputDecoration(
            hintText: s.searchName,
            prefixIcon: Icon(Icons.search_rounded, color: t.muted, size: 28),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            PickChip(
              label: s.whatsappMember,
              selected: _whatsappOnly,
              onTap: () => setState(() => _whatsappOnly = !_whatsappOnly),
            ),
          ],
        ),
        if (_whatsappOnly && list.isNotEmpty) ...[
          const SizedBox(height: 10),
          BigButton(
            label: s.copyNumbers,
            icon: Icons.copy_rounded,
            kind: ButtonKind.outline,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: [for (final u in list) u.phone].join('\n')));
              if (context.mounted) toast(context, s.numbersCopied);
            },
          ),
        ],
        const SizedBox(height: 16),
        if (users.hasError)
          WarnBanner(icon: Icons.error_rounded, text: s.decisionFailed)
        else if (users.isLoading && list.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (list.isEmpty)
          Text(s.noOneYet, style: tt.bodyLarge)
        else
          for (final u in list) ...[_UserCard(user: u), const SizedBox(height: 10)],
      ],
    );
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({required this.user});

  final UserEntry user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final u = user;
    final details = [
      if (u.role != null) u.role == UserRole.teacher ? s.teacherL : s.studentL,
      if (u.gender != null) u.gender == Gender.female ? s.sister : s.brother,
    ].join(' · ');
    return SCard(
      onTap: () => _showPerson(context, ref, u),
      child: Row(
        children: [
          Avatar(initialOf(u.name), size: 52, image: u.avatar),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FullName(u.name.isEmpty ? '—' : u.name, style: tt.titleMedium!),
                if (details.isNotEmpty) Text(details, style: tt.bodySmall),
              ],
            ),
          ),
          if (u.paused)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: t.warn, borderRadius: BorderRadius.circular(12)),
              child: Text(
                s.pausedTag,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.onWarn),
              ),
            ),
        ],
      ),
    );
  }
}

/// A person's details (for admins), with Pause or Restore, and Remove
/// picture when they use their own photo.
Future<void> _showPerson(BuildContext context, WidgetRef ref, UserEntry u) async {
  final s = S.of(context);
  final action = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final t = ctx.t;
      final tt = Theme.of(ctx).textTheme;
      final country = Country.byCode(u.nationality);
      Widget row(IconData icon, String label, String? value, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, color: t.muted, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: tt.bodySmall),
                  Text(
                    value ?? s.notGivenYet,
                    style: tt.titleMedium!.copyWith(color: value == null ? t.muted : t.text),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      );
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Avatar(initialOf(u.name), size: 72, image: u.avatar),
                  const SizedBox(width: 14),
                  Expanded(child: FullName(u.name.isEmpty ? '—' : u.name, style: tt.titleLarge!)),
                ],
              ),
              const SizedBox(height: 16),
              row(Icons.cake_rounded, s.ageGroupL, u.ageGroup == null ? null : s.ageLabel(u.ageGroup!)),
              row(
                Icons.public_rounded,
                s.nationalityL,
                country == null ? u.nationality : '${country.flag} ${country.name(s.ar)}',
              ),
              row(
                Icons.phone_rounded,
                s.phoneL,
                u.phone == null ? null : '\u2066${u.phone}\u2069',
                trailing: u.phone == null
                    ? null
                    : IconButton(
                        tooltip: s.copy,
                        icon: Icon(Icons.copy_rounded, color: t.primary),
                        style: IconButton.styleFrom(minimumSize: const Size(kMinTap, kMinTap)),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: u.phone!));
                          if (ctx.mounted) toast(ctx, s.numberCopied);
                        },
                      ),
              ),
              row(Icons.groups_rounded, s.whatsappMember, u.whatsapp ? s.yes : s.no),
              const SizedBox(height: 8),
              BigButton(
                label: u.paused ? s.restoreAccount : s.pauseAccount,
                icon: u.paused ? Icons.play_circle_rounded : Icons.pause_circle_rounded,
                kind: ButtonKind.outline,
                onPressed: () => Navigator.pop(ctx, 'pause'),
              ),
              if (photoOwner(u.avatar) != null) ...[
                const SizedBox(height: 10),
                BigButton(
                  label: s.removePhoto,
                  icon: Icons.hide_image_rounded,
                  kind: ButtonKind.outline,
                  onPressed: () => Navigator.pop(ctx, 'photo'),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
  if (!context.mounted) return;
  if (action == 'pause') {
    await setPaused(context, ref, uid: u.uid, name: u.name, pause: !u.paused);
  } else if (action == 'photo') {
    final yes = await confirm(context, title: s.removePhotoQ, confirmLabel: s.removePhoto, destructive: true);
    if (!yes) return;
    try {
      await ref.read(backendProvider).removePhoto(u.uid);
      if (context.mounted) toast(context, s.photoRemoved);
    } catch (_) {
      if (context.mounted) toast(context, s.decisionFailed);
    }
  }
}

/// Pauses (after asking for a reason) or restores an account.
Future<void> setPaused(
  BuildContext context,
  WidgetRef ref, {
  required String uid,
  required String name,
  required bool pause,
}) async {
  final s = S.of(context);
  String reason = '';
  if (pause) {
    final r = await showDialog<String>(
      context: context,
      builder: (_) => _PauseDialog(name: name),
    );
    if (r == null) return;
    reason = r;
  } else {
    final yes = await confirm(context, title: name, confirmLabel: s.restoreAccount);
    if (!yes) return;
  }
  try {
    await ref.read(backendProvider).setPaused(uid, paused: pause, reason: reason);
    if (context.mounted) toast(context, pause ? s.pausedDone : s.restoredDone);
  } catch (_) {
    if (context.mounted) toast(context, s.decisionFailed);
  }
}

class _PauseDialog extends StatefulWidget {
  const _PauseDialog({required this.name});

  final String name;

  @override
  State<_PauseDialog> createState() => _PauseDialogState();
}

class _PauseDialogState extends State<_PauseDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    const big = TextStyle(fontSize: 18);
    return AlertDialog(
      title: Text(s.pauseQ(widget.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.pauseBody, style: big),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            minLines: 2,
            maxLines: 4,
            maxLength: Limits.pauseReason,
            decoration: InputDecoration(hintText: s.pauseReason),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel, style: big),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _reason.text.trim()),
          child: Text(
            s.pauseAccount,
            style: big.copyWith(fontWeight: FontWeight.w700, color: t.warn),
          ),
        ),
      ],
    );
  }
}
