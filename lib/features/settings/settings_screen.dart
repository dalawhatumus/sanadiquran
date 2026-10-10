import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backend/backend.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/avatars.dart';
import '../../widgets/ui.dart';
import '../athkar/athkar_menu_screen.dart';
import 'more_screens.dart';

/// Settings: profile, language, appearance, reminders, help and privacy,
/// account (sign out, delete), and testing tools for test builds.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final teacher = settings.role == UserRole.teacher;
    final backend = ref.watch(backendProvider);
    final admin = ref.watch(isAdminProvider).value ?? false;

    // Turns off "available" and signs out of the server, then starts again.
    Future<void> signOut() async {
      if (teacher && settings.teacherStatus == TeacherStatus.approved) {
        await backend.setAvailable(on: false, gender: settings.gender).catchError((_) {});
      }
      await backend.signOut().catchError((_) {});
      n.reset();
      if (context.mounted) context.go(Routes.language);
    }

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: WordSafeText(title, style: tt.titleLarge),
    );

    Widget linkCard(IconData icon, String title, String sub, VoidCallback onTap, {Color? color}) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SCard(
        onTap: onTap,
        child: Row(
          children: [
            TintBox(child: Icon(icon, color: color ?? t.primary)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WordSafeText(title, style: tt.titleMedium!.copyWith(color: color ?? t.heading)),
                  Text(sub, style: tt.bodySmall),
                ],
              ),
            ),
            Icon(Arrows.next, color: color ?? t.primary, size: 32),
          ],
        ),
      ),
    );

    Future<void> changeName() async {
      final name = await askName(context, settings.name);
      if (name != null && name != settings.name) n.update((x) => x.copyWith(name: name));
    }

    Future<void> deleteAccount() async {
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.deleteAccountQ),
          content: Text(s.deleteAccountBody, style: const TextStyle(fontSize: 18)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel, style: const TextStyle(fontSize: 18)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                s.deleteForever,
                style: TextStyle(fontSize: 18, color: t.warn, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      if (yes != true) return;
      try {
        await backend.deleteAccount();
      } on SignInCancelled {
        return;
      } catch (_) {
        if (context.mounted) toast(context, s.decisionFailed);
        return;
      }
      n.reset();
      if (context.mounted) {
        toast(context, s.accountDeleted);
        context.go(Routes.language);
      }
    }

    return StepScaffold(
      showBack: true,
      content: [
        WordSafeText(s.settings, style: tt.headlineMedium),
        const SizedBox(height: 12),
        SCard(
          onTap: () => showAvatarPicker(context, ref),
          child: Row(
            children: [
              Avatar(settings.name.characters.first.toUpperCase(), size: 72, image: settings.avatar),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FullName(settings.name, style: tt.titleLarge!),
                    Text(teacher ? s.roleTeacher : s.roleStudent, style: tt.bodySmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18, color: t.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            s.changePicture,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        BigButton(label: s.changeName, icon: Icons.badge_rounded, kind: ButtonKind.tint, onPressed: changeName),
        if (admin) ...[
          for (final (icon, title, sub, route) in [
            (Icons.how_to_reg_rounded, s.adminTitle, s.adminSub, Routes.admin),
            (Icons.link_rounded, s.connectTitle, s.connectSub, Routes.adminConnect),
            (Icons.flag_rounded, s.reportsTitle, s.reportsSub, Routes.adminReports),
          ])
            linkCard(icon, title, sub, () => context.push(route)),
        ],
        section(s.language),
        Row(
          children: [
            Expanded(
              child: PickChip(
                label: 'العربية',
                selected: settings.locale?.languageCode == 'ar',
                onTap: () => n.update((x) => x.copyWith(locale: const Locale('ar'))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PickChip(
                label: 'English',
                selected: settings.locale?.languageCode == 'en',
                onTap: () => n.update((x) => x.copyWith(locale: const Locale('en'))),
              ),
            ),
          ],
        ),
        section(s.appearance),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (mode, label) in [
              (ThemeMode.system, s.themeSystem),
              (ThemeMode.light, s.themeLight),
              (ThemeMode.dark, s.themeDark),
            ])
              PickChip(
                label: label,
                selected: settings.themeMode == mode,
                onTap: () => n.update((x) => x.copyWith(themeMode: mode)),
              ),
          ],
        ),
        linkCard(
          Icons.notifications_rounded,
          s.remindersL,
          settings.remindersOn ? s.remindersOnSub : s.remindersOffSub,
          () => showReminderSheet(context),
        ),
        section(s.helpSection),
        linkCard(Icons.mail_rounded, s.contactUs, s.contactSub, () => contactSanadi(context)),
        linkCard(Icons.shield_rounded, s.privacyTitle, s.privacySub, () => context.push(Routes.privacy)),
        linkCard(Icons.info_rounded, s.aboutTitle, s.aboutSub, () => context.push(Routes.about)),
        if (backend.live)
          linkCard(Icons.block_rounded, s.blockedTitle, s.blockedSub, () => context.push(Routes.blocked)),
        section(s.testing),
        Text(s.testingNote, style: tt.bodySmall),
        const SizedBox(height: 12),
        BigButton(
          label: s.switchRole,
          icon: Icons.swap_horiz_rounded,
          kind: ButtonKind.tint,
          onPressed: () {
            n.update(
              (x) => x.copyWith(
                role: teacher ? UserRole.student : UserRole.teacher,
                tourDone: true,
                // Online, the server decides whether a teacher is approved.
                teacherStatus: teacher || backend.live ? null : TeacherStatus.approved,
              ),
            );
            context.go(nextStep(ref.read(settingsProvider)));
          },
        ),
        if (teacher && !backend.live) ...[
          const SizedBox(height: 10),
          BigButton(
            label: s.approveApp,
            icon: Icons.verified_rounded,
            kind: ButtonKind.tint,
            onPressed: () {
              n.update((x) => x.copyWith(teacherStatus: TeacherStatus.approved));
              context.go(Routes.teacherHome);
            },
          ),
          const SizedBox(height: 10),
          BigButton(
            label: s.rejectApp,
            icon: Icons.block_rounded,
            kind: ButtonKind.tint,
            onPressed: () {
              n.update((x) => x.copyWith(teacherStatus: TeacherStatus.rejected));
              context.go(Routes.teacherHome);
            },
          ),
          const SizedBox(height: 10),
          BigButton(
            label: s.simulateCall,
            icon: Icons.call_received_rounded,
            kind: ButtonKind.tint,
            onPressed: () => context.push(Routes.incoming),
          ),
        ],
        const SizedBox(height: 10),
        BigButton(label: s.resetApp, icon: Icons.restart_alt_rounded, kind: ButtonKind.tint, onPressed: signOut),
        section(s.account),
        BigButton(
          label: s.signOut,
          icon: Icons.logout_rounded,
          kind: ButtonKind.outline,
          onPressed: () async {
            final yes = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(s.signOutQ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(s.cancel, style: const TextStyle(fontSize: 18)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      s.signOut,
                      style: TextStyle(fontSize: 18, color: t.warn, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
            if (yes == true) await signOut();
          },
        ),
        if (backend.live) ...[
          const SizedBox(height: 12),
          BigButton(
            label: s.deleteAccount,
            icon: Icons.delete_forever_rounded,
            kind: ButtonKind.outline,
            onPressed: deleteAccount,
          ),
        ],
        const SizedBox(height: 20),
        Text(backend.live ? s.serverLive : s.serverDemo, style: tt.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text('${s.version} $appVersion', style: tt.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}
