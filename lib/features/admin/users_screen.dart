import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/admin.dart';
import '../../backend/backend.dart';
import '../../core/limits.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../messages/messages_screen.dart';

/// Admins find anyone by name and pause or restore their account.
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _search = TextEditingController();

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
        if (query.isEmpty || u.name.toLowerCase().contains(query)) u,
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
      onTap: () => setPaused(context, ref, uid: u.uid, name: u.name, pause: !u.paused),
      child: Row(
        children: [
          Avatar(initialOf(u.name), size: 52),
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
