import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/avatars.dart';
import '../../widgets/ui.dart';

/// 4 · What would you like to do? (Step 1 of 4, neutral Arabic)
class RoleScreen extends ConsumerStatefulWidget {
  const RoleScreen({super.key});

  @override
  ConsumerState<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends ConsumerState<RoleScreen> {
  UserRole? _role;

  @override
  void initState() {
    super.initState();
    _role = ref.read(settingsProvider).role;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tt = Theme.of(context).textTheme;
    return StepScaffold(
      step: s.stepOf(1, 4),
      content: [
        WordSafeText(s.roleTitle, style: tt.headlineMedium),
        const SizedBox(height: 24),
        ChoiceCard(
          leading: const TintBox(child: Icon(Icons.mic_rounded)),
          title: s.roleStudent,
          subtitle: s.roleStudentSub,
          selected: _role == UserRole.student,
          onTap: () => setState(() => _role = UserRole.student),
        ),
        const SizedBox(height: 14),
        ChoiceCard(
          leading: const TintBox(child: SIcon(SIcons.students)),
          title: s.roleTeacher,
          subtitle: s.roleTeacherSub,
          selected: _role == UserRole.teacher,
          onTap: () => setState(() => _role = UserRole.teacher),
        ),
      ],
      bottom: [
        BigButton(
          label: s.next,
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: _role == null
              ? null
              : () {
                  ref.read(settingsProvider.notifier).update((st) => st.copyWith(role: _role));
                  context.push(Routes.gender);
                },
        ),
      ],
    );
  }
}

/// 5 · I am… (Step 2 of 4). Explains same-gender matching.
class GenderScreen extends ConsumerStatefulWidget {
  const GenderScreen({super.key});

  @override
  ConsumerState<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends ConsumerState<GenderScreen> {
  Gender? _gender;

  @override
  void initState() {
    super.initState();
    _gender = ref.read(settingsProvider).gender;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return StepScaffold(
      showBack: true,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.role),
      step: s.stepOf(2, 4),
      content: [
        WordSafeText(s.genderTitle, style: tt.headlineMedium),
        const SizedBox(height: 24),
        ChoiceCard(
          leading: const TintBox(child: Icon(Icons.man_rounded)),
          title: s.male,
          selected: _gender == Gender.male,
          onTap: () => setState(() => _gender = Gender.male),
        ),
        const SizedBox(height: 14),
        ChoiceCard(
          leading: const TintBox(child: Icon(Icons.woman_rounded)),
          title: s.femaleL,
          selected: _gender == Gender.female,
          onTap: () => setState(() => _gender = Gender.female),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_rounded, color: t.primary, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(s.genderInfo, style: tt.bodyMedium)),
          ],
        ),
      ],
      bottom: [
        BigButton(
          label: s.next,
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: _gender == null
              ? null
              : () {
                  ref.read(settingsProvider.notifier).update((st) => st.copyWith(gender: _gender));
                  context.push(Routes.name);
                },
        ),
      ],
    );
  }
}

/// 6 · Your name (Step 3 of 4). Checks when Next is tapped.
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  late final TextEditingController _c = TextEditingController(text: ref.read(settingsProvider).name);
  bool _error = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _next() {
    final name = _c.text.trim();
    if (name.isEmpty) {
      setState(() => _error = true);
      return;
    }
    ref.read(settingsProvider.notifier).update((st) => st.copyWith(name: name));
    context.push(Routes.permMic);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final teacher = ref.watch(settingsProvider).role == UserRole.teacher;
    return StepScaffold(
      showBack: true,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.gender),
      step: s.stepOf(3, 4),
      content: [
        WordSafeText(s.nameTitle, style: tt.headlineMedium),
        const SizedBox(height: 8),
        Text(teacher ? s.nameStudentSub : s.nameSub, style: tt.bodyMedium),
        const SizedBox(height: 24),
        Text(s.nameLabel, style: tt.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _c,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _next(),
          onChanged: (_) => _error ? setState(() => _error = false) : null,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.text),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.account_circle_rounded, color: t.muted, size: 30),
            errorText: _error ? s.nameEmpty : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(s.nameHint, style: tt.bodySmall),
        const SizedBox(height: 28),
        Text(s.choosePictureOptional, style: tt.titleSmall),
        const SizedBox(height: 12),
        AvatarGrid(
          selected: ref.watch(settingsProvider.select((x) => x.avatar)),
          onPick: (id) =>
              ref.read(settingsProvider.notifier).update((x) => x.copyWith(avatar: id, clearAvatar: id == null)),
        ),
      ],
      bottom: [BigButton(label: s.next, trailingIcon: Icons.arrow_forward_rounded, onPressed: _next)],
    );
  }
}
