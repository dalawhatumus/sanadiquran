import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../backend/backend.dart';
import '../../backend/chat.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../messages/messages_screen.dart';

const contactEmail = 'sanadiquran@gmail.com';

/// Opens the phone's email app to write to Sanadi.
Future<void> contactSanadi(BuildContext context, {String subject = 'Sanadi'}) async {
  final s = S.of(context);
  final uri = Uri(scheme: 'mailto', path: contactEmail, query: 'subject=${Uri.encodeComponent(subject)}');
  var opened = false;
  try {
    opened = await launchUrl(uri);
  } catch (_) {}
  if (!opened && context.mounted) {
    await Clipboard.setData(const ClipboardData(text: contactEmail));
    if (context.mounted) toast(context, s.noEmailApp);
  }
}

/// Asks for a new name; returns it, or null if cancelled.
Future<String?> askName(BuildContext context, String current) =>
    showDialog<String>(context: context, builder: (_) => _NameDialog(current));

class _NameDialog extends StatefulWidget {
  const _NameDialog(this.current);

  final String current;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _c = TextEditingController(text: widget.current);
  bool _error = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _save() {
    final name = _c.text.trim();
    if (name.isEmpty) {
      setState(() => _error = true);
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    return AlertDialog(
      title: Text(s.changeName),
      content: TextField(
        controller: _c,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        onChanged: (_) => _error ? setState(() => _error = false) : null,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.text),
        decoration: InputDecoration(labelText: s.nameLabel, errorText: _error ? s.nameEmpty : null),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel, style: const TextStyle(fontSize: 18)),
        ),
        TextButton(
          onPressed: _save,
          child: Text(
            s.save,
            style: TextStyle(fontSize: 18, color: t.primary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tt = Theme.of(context).textTheme;
    return StepScaffold(
      showBack: true,
      content: [
        WordSafeText(s.privacyTitle, style: tt.headlineMedium),
        const SizedBox(height: 8),
        for (final (title, body) in s.privacySections) ...[
          const SizedBox(height: 16),
          WordSafeText(title, style: tt.titleLarge),
          const SizedBox(height: 6),
          Text(body, style: tt.bodyLarge),
        ],
        const SizedBox(height: 24),
        BigButton(
          label: s.contactUs,
          icon: Icons.mail_rounded,
          kind: ButtonKind.outline,
          onPressed: () => contactSanadi(context),
        ),
      ],
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return StepScaffold(
      showBack: true,
      content: [
        Center(
          child: Logo(
            Theme.of(context).brightness == Brightness.dark
                ? 'sanadi-horizontal-rtl-cream'
                : 'sanadi-horizontal-rtl-green',
            height: 72,
          ),
        ),
        const SizedBox(height: 16),
        WordSafeText(s.aboutTitle, style: tt.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(s.aboutBody, style: tt.bodyLarge),
        const SizedBox(height: 24),
        WordSafeText(s.thanksTitle, style: tt.titleLarge),
        for (final (title, body) in s.acknowledgements) ...[
          const SizedBox(height: 12),
          SCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WordSafeText(title, style: tt.titleMedium!.copyWith(color: t.heading)),
                const SizedBox(height: 4),
                Text(body, style: tt.bodyMedium),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('${s.version} $appVersion', style: tt.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}

/// The version shown in Settings and About (keep in step with pubspec).
const appVersion = '0.8.1';

/// People this user blocked in messages, with Unblock.
class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final convs = ref.watch(conversationsProvider);
    final blocked = [
      for (final c in convs.value ?? const <Conversation>[])
        if (c.blockedByMe) c,
    ];
    return StepScaffold(
      showBack: true,
      content: [
        WordSafeText(s.blockedTitle, style: tt.headlineMedium),
        const SizedBox(height: 16),
        if (convs.isLoading && blocked.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (blocked.isEmpty)
          SCard(
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: t.muted, size: 32),
                const SizedBox(width: 12),
                Expanded(child: Text(s.blockedEmpty, style: tt.bodyLarge)),
              ],
            ),
          )
        else
          for (final c in blocked) ...[
            SCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Avatar(initialOf(c.otherName), size: 56, image: c.otherAvatar),
                      const SizedBox(width: 12),
                      Expanded(child: FullName(c.otherName, style: tt.titleLarge!)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  BigButton(
                    label: s.unblock,
                    icon: Icons.lock_open_rounded,
                    kind: ButtonKind.outline,
                    compact: true,
                    onPressed: () async {
                      try {
                        await ref.read(backendProvider).setBlocked(c.id, blocked: false);
                      } catch (_) {
                        if (context.mounted) toast(context, s.decisionFailed);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
