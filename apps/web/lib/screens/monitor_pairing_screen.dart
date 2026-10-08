import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../monitor/monitor_session.dart';

/// Pairing screen (ADR 0012, "Monitor im Browser"): "Monitor koppeln",
/// a single large code field (`ABCD-EFGH`, case-insensitive), and a
/// "Koppeln" button. Usable with a TV remote/keyboard: autofocus, Enter
/// submits.
class MonitorPairingScreen extends ConsumerStatefulWidget {
  const MonitorPairingScreen({super.key, this.revokedHint = false});

  /// Shows "Dieser Monitor wurde gesperrt oder neu gekoppelt." once, after
  /// a `session.revoked` signal cleared the session (ADR 0012).
  final bool revokedHint;

  @override
  ConsumerState<MonitorPairingScreen> createState() =>
      _MonitorPairingScreenState();
}

class _MonitorPairingScreenState extends ConsumerState<MonitorPairingScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text;
    if (code.trim().isEmpty || _submitting) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(monitorSessionControllerProvider.notifier).pair(code);
    } on MonitorPairingFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Monitor koppeln',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (widget.revokedHint) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Dieser Monitor wurde gesperrt oder neu gekoppelt.',
                    key: Key('monitor-revoked-hint'),
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                TextField(
                  key: const Key('monitor-pairing-code'),
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    letterSpacing: 4,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'ABCD-EFGH',
                    hintStyle: TextStyle(color: Colors.white38),
                    enabledBorder: OutlineInputBorder(),
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-\s]')),
                  ],
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    key: const Key('monitor-pairing-error'),
                    style: const TextStyle(color: Colors.redAccent, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  key: const Key('monitor-pairing-submit'),
                  onPressed: _submitting ? null : _submit,
                  child: const Text('Koppeln'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
