import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backend/backend.dart';
import '../../core/connectivity.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../widgets/ui.dart';

enum _State { idle, busy, failed, offline }

/// 3 · Welcome and Google sign-in. No passwords.
///
/// Someone who used Sanadi before gets their profile back. In demo mode
/// (no Firebase settings) the button checks the internet and continues.
/// Without internet, the Quran and athkar can still be opened.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
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
      debugPrint('Sign-in failed: $e');
      if (mounted) setState(() => _state = _State.failed);
      return;
    }
    if (!mounted) return;
    final profile = user.profile;
    ref
        .read(settingsProvider.notifier)
        .update((s) => profile != null ? profile.applyTo(s) : s.copyWith(signedIn: true));
    if (user.googleName != null) ref.read(suggestedNameProvider.notifier).set(user.googleName!);
    context.go(nextStep(ref.read(settingsProvider)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tt = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final g = Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Text(
        'G',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontFamilyFallback: ['Tajawal'],
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E3A40),
        ),
      ),
    );
    return StepScaffold(
      center: true,
      content: [
        if (_state == _State.failed) WarnBanner(icon: Icons.error_rounded, text: s.signInFailed),
        if (_state == _State.offline) WarnBanner(icon: Icons.wifi_off_rounded, text: s.noInternetLong),
        const SizedBox(height: 24),
        Center(child: Logo(dark ? 'sanadi-horizontal-rtl-cream' : 'sanadi-horizontal-rtl-green', height: 84)),
        const SizedBox(height: 28),
        WordSafeText(s.tagline, textAlign: TextAlign.center, style: tt.headlineSmall),
        const SizedBox(height: 8),
        Text(s.taglineSub, textAlign: TextAlign.center, style: tt.bodyMedium),
        const SizedBox(height: 24),
      ],
      bottom: [
        if (_state == _State.offline) ...[
          BigButton(label: s.tryAgain, icon: Icons.refresh_rounded, onPressed: _signIn),
          // Offline content never needs an account or internet.
          Row(
            children: [
              Expanded(
                child: BigButton(
                  label: s.navQuran,
                  iconWidget: const SIcon(SIcons.rehal),
                  kind: ButtonKind.outline,
                  compact: true,
                  onPressed: () => context.push(Routes.mushaf),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BigButton(
                  label: s.athkarTitle,
                  iconWidget: const SIcon(SIcons.misbaha),
                  kind: ButtonKind.outline,
                  compact: true,
                  onPressed: () => context.push(Routes.athkar),
                ),
              ),
            ],
          ),
          Text(s.offlineWorks, textAlign: TextAlign.center, style: tt.bodySmall),
        ] else if (_state == _State.failed)
          BigButton(label: s.tryAgain, icon: Icons.refresh_rounded, onPressed: _signIn)
        else
          BigButton(
            label: _state == _State.busy ? s.signingIn : s.continueGoogle,
            iconWidget: g,
            busy: _state == _State.busy,
            onPressed: _signIn,
          ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            LinkButton(label: s.privacy, onPressed: () => showSoon(context)),
            LinkButton(label: s.terms, onPressed: () => showSoon(context)),
          ],
        ),
      ],
    );
  }
}
