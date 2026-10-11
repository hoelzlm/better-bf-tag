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
class AnnouncementBanner extends StatelessWidget {
  const AnnouncementBanner({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('announcement-banner'),
      width: double.infinity,
      color: Colors.amber,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DURCHSAGE',
            style: TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            announcement.text,
            key: const Key('announcement-banner-text'),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
