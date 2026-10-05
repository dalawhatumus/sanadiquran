import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';

/// Teacher home (spec §6.3 T1): the big availability switch first.
/// Availability is local-only until calls are built.
class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  bool _available = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fg = _available ? Colors.white : SanadiColors.text;

    return Scaffold(
      appBar: SanadiAppBar(title: l10n.tabHome),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(l10n.greeting(l10n.guestName), style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          MergeSemantics(
            child: Material(
              color: _available ? SanadiColors.green : Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: _available
                    ? BorderSide.none
                    : const BorderSide(color: SanadiColors.away, width: 1.5),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => setState(() => _available = !_available),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(
                        _available ? Icons.wifi_tethering : Icons.do_not_disturb_on,
                        size: 44,
                        color: _available ? SanadiColors.gold : SanadiColors.away,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _available ? l10n.availableToTeach : l10n.away,
                              style: theme.textTheme.titleMedium?.copyWith(color: fg),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.availabilityHint,
                              style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 1.3,
                        child: Switch(
                          value: _available,
                          activeThumbColor: SanadiColors.gold,
                          onChanged: (v) => setState(() => _available = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          InfoCard(
            icon: Icons.today,
            title: l10n.todayStats(0, 0),
          ),
          const SizedBox(height: 16),
          InfoCard(
            icon: Icons.hourglass_top,
            title: l10n.studentsWaiting(0),
            color: SanadiColors.goldLight,
          ),
        ],
      ),
    );
  }
}
