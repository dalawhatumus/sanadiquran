import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backend/backend.dart';
import '../../core/connectivity.dart';
import '../../core/log.dart';
import '../../core/router.dart';
import '../../core/screen.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

enum _State { idle, busy, failed, offline }

/// "Continue with Google", with what goes wrong shown above it, a line
/// saying no password is needed, and help for a phone with no Google account.
/// Signing in brings back someone's profile if they used Sanadi before; in
/// demo mode (no Firebase settings) it just continues.
class SignInPanel extends ConsumerStatefulWidget {
  const SignInPanel({super.key});

  @override
  ConsumerState<SignInPanel> createState() => _SignInPanelState();
}

class _SignInPanelState extends ConsumerState<SignInPanel> {
  _State _state = _State.idle;

  Future<void> _signIn() async {
    setState(() => _state = _State.busy);
    final online = await ref.read(onlineCheckProvider)();
    if (!mounted) return;
    if (!online) {
      setState(() => _state = _State.offline);
      return;
    }
    final SignedInUser user;
    try {
      user = await ref.read(backendProvider).signIn();
    } on SignInCancelled {
      if (mounted) setState(() => _state = _State.idle);
      return;
    } catch (e) {
      logIssue('Sign-in failed: $e');
      if (mounted) setState(() => _state = _State.failed);
      return;
    }
    if (!mounted) return;
    final profile = user.profile;
    ref
        .read(settingsProvider.notifier)
        .update((s) => (profile != null ? profile.applyTo(s) : s.copyWith(signedIn: true)).copyWith(guest: false));
    if (user.googleName != null) ref.read(suggestedNameProvider.notifier).set(user.googleName!);
    context.go(nextStep(ref.read(settingsProvider)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_state == _State.failed) ...[
          WarnBanner(icon: Icons.error_rounded, text: s.signInFailed),
          const SizedBox(height: 12),
        ],
        if (_state == _State.offline) ...[
          WarnBanner(icon: Icons.wifi_off_rounded, text: s.noInternetLong),
          const SizedBox(height: 12),
        ],
        GoogleButton(
          label: _state == _State.busy ? s.signingIn : s.continueGoogle,
          busy: _state == _State.busy,
          onPressed: _signIn,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_open_rounded, size: 20, color: context.t.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(s.noPasswordNote, textAlign: TextAlign.center, style: tt.bodyMedium),
            ),
          ],
        ),
        Center(
          child: LinkButton(label: s.noGoogleAccountQ, onPressed: () => showNoGoogleAccount(context)),
        ),
      ],
    );
  }
}

/// How to add a Google account to the phone, with a button to the phone's
/// own screen for it.
Future<void> showNoGoogleAccount(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (ctx) {
    final s = S.of(ctx);
    final tt = Theme.of(ctx).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WordSafeText(s.noGoogleAccountQ, style: tt.headlineSmall),
            const SizedBox(height: 10),
            Text(s.noAccountBody, style: tt.bodyLarge),
            const SizedBox(height: 14),
            for (final (i, step) in s.noAccountSteps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NumberBadge(s.n(i + 1)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(step, style: tt.bodyLarge)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            BigButton(
              label: s.addGoogleAccount,
              icon: Icons.person_add_rounded,
              onPressed: () async {
                final opened = await Screen.addGoogleAccount();
                if (!opened && ctx.mounted) toast(ctx, s.addAccountFailed);
              },
            ),
            const SizedBox(height: 10),
            BigButton(label: s.close, kind: ButtonKind.outline, onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  },
);
