import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';

/// How long a live `announcement.created` banner stays on the monitor
/// standby screen before falling back to the "Letzte Durchsage" panel
/// (ADR 0024, "Clients"). The timer is driven by the caller
/// ([MonitorScreen]), not by this widget, so tests can fake it.
const announcementBannerDuration = Duration(seconds: 60);

/// Full-width banner shown on the monitor standby screen while a live
/// `announcement.created` is within [announcementBannerDuration] (ADR
/// 0024). Never shown while the Einsatzansicht has Vorrang -- the caller
/// is responsible for that (see `MonitorScreen`), this widget only
/// renders what it's given.
///
/// `primaryContainer` surface, never amber/black (concept
/// `docs/design/screens/monitor-standby.md` §3/§6 AC5, Grundsatz
/// "Durchsage ist kein Alarm", Designsystem 5.7).
class AnnouncementBanner extends StatelessWidget {
  const AnnouncementBanner({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monitorStyles = theme.extension<BftagMonitorTextStyles>();
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();

    return Container(
      key: const Key('announcement-banner'),
      width: double.infinity,
      color: colorScheme.primaryContainer,
      padding: EdgeInsets.symmetric(
        vertical: spacing.xl,
        horizontal: spacing.xxl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.campaign, color: colorScheme.onSurface, size: 32),
          SizedBox(width: spacing.lg),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DURCHSAGE',
                  style: (monitorStyles?.label ?? const TextStyle(fontSize: 22))
                      .copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: spacing.sm),
                Text(
                  announcement.text,
                  key: const Key('announcement-banner-text'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: (monitorStyles?.body ?? const TextStyle(fontSize: 28))
                      .copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
