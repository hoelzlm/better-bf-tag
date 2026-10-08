import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../monitor/monitor_clock.dart';
import '../monitor/monitor_session.dart';
import '../widgets/vehicle_status_bar.dart';

String _twoDigits(int n) => n.toString().padLeft(2, '0');

bool _dateFormattingInitialized = false;

/// Standby screen (ADR 0012, "Monitor im Browser"): large clock, German
/// date, monitor name, connection banner, and the live Fahrzeugstatus-Leiste
/// -- scaled for viewing from across a room on a TV.
class MonitorStandbyScreen extends ConsumerStatefulWidget {
  const MonitorStandbyScreen({super.key});

  @override
  ConsumerState<MonitorStandbyScreen> createState() =>
      _MonitorStandbyScreenState();
}

class _MonitorStandbyScreenState extends ConsumerState<MonitorStandbyScreen> {
  bool _ready = _dateFormattingInitialized;

  @override
  void initState() {
    super.initState();
    if (!_dateFormattingInitialized) {
      initializeDateFormatting('de').then((_) {
        _dateFormattingInitialized = true;
        if (mounted) {
          setState(() => _ready = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(monitorSessionControllerProvider);
    final name = session is MonitorPaired ? session.name : '';
    final connection = ref.watch(realtimeConnectionProvider).valueOrNull;
    final now = ref.watch(monitorClockProvider).valueOrNull ?? DateTime.now();

    final time =
        '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}';
    final seconds = _twoDigits(now.second);
    final date = _ready
        ? DateFormat('EEEE, d. MMMM y', 'de').format(now)
        : '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _ConnectionBanner(status: connection),
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    right: 24,
                    child: Text(
                      name,
                      key: const Key('monitor-name'),
                      style: const TextStyle(color: Colors.white54, fontSize: 20),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                time,
                                key: const Key('monitor-clock-time'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 160,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                              Text(
                                ':$seconds',
                                key: const Key('monitor-clock-seconds'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          date,
                          key: const Key('monitor-date'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const VehicleStatusBar(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.status});

  final ConnectionStatus? status;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    // Neutral hint during the very first connect attempt; red banner for
    // every later non-live status (reconnecting/revoked).
    if (status == null || status == ConnectionStatus.connecting) {
      return _Banner(
        key: const Key('connection-banner-connecting'),
        color: Colors.grey.shade800,
        text: 'Verbinde …',
      );
    }
    if (status == ConnectionStatus.live) {
      return const SizedBox.shrink();
    }
    return _Banner(
      key: const Key('connection-banner-reconnecting'),
      color: Colors.red,
      text: 'Keine Verbindung – verbinde neu …',
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key, required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
