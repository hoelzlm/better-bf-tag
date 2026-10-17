import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../monitor/monitor_session.dart';

/// Pairing screen (ADR 0012, "Monitor im Browser"; concept
/// `docs/design/screens/monitor-kopplung.md` §3.2): "Monitor koppeln", a
/// single large code field (`ABCD-EFGH`, case-insensitive) with a
/// standing "Kopplungscode" label, and a "Koppeln" button. Usable with a
/// TV remote/keyboard: autofocus, Enter submits.
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
  void initState() {
    super.initState();
    // Rebuild on every keystroke so the submit button's disabled state
    // (concept §6 AC5: disabled while the field is empty) stays in sync.
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monitorStyles = theme.extension<BftagMonitorTextStyles>()!;
    final spacing = theme.extension<BftagSpacing>()!;
    final radii = theme.extension<BftagRadii>()!;
    final isEmpty = _controller.text.trim().isEmpty;
    final hasError = _error != null;
    final borderColor = hasError ? colorScheme.error : colorScheme.outline;

    OutlineInputBorder border({required Color color, required double width}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.large),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: EdgeInsets.all(spacing.huge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 96,
                    color: colorScheme.primary,
                  ),
                  SizedBox(height: spacing.xl),
                  Text(
                    'Monitor koppeln',
                    style: monitorStyles.headline.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: spacing.sm),
                  Text(
                    'Kopplungscode aus „Monitore“ in der Admin-Web eingeben',
                    style: monitorStyles.body.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.revokedHint) ...[
                    SizedBox(height: spacing.lg),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        SizedBox(width: spacing.sm),
                        Flexible(
                          child: Text(
                            'Dieser Monitor wurde gesperrt oder neu gekoppelt.',
                            key: const Key('monitor-revoked-hint'),
                            style: monitorStyles.body.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: spacing.xxl),
                  SizedBox(
                    width: 720,
                    height: 140,
                    child: TextField(
                      key: const Key('monitor-pairing-code'),
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      readOnly: _submitting,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      style: monitorStyles.display.copyWith(
                        color: colorScheme.onSurface,
                        letterSpacing: 4,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Kopplungscode',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: 'ABCD-EFGH',
                        border: border(color: borderColor, width: 2),
                        enabledBorder: border(color: borderColor, width: 2),
                        focusedBorder: border(
                          color: hasError
                              ? colorScheme.error
                              : colorScheme.primary,
                          width: hasError ? 2 : 3,
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9\-\s]'),
                        ),
                      ],
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  if (hasError) ...[
                    SizedBox(height: spacing.lg),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.error,
                          size: 24,
                        ),
                        SizedBox(width: spacing.sm),
                        Flexible(
                          child: Text(
                            _error!,
                            key: const Key('monitor-pairing-error'),
                            style: monitorStyles.body.copyWith(
                              color: colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: spacing.xxl),
                  SizedBox(
                    width: 320,
                    height: 56,
                    child: FilledButton(
                      key: const Key('monitor-pairing-submit'),
                      onPressed: (isEmpty || _submitting) ? null : _submit,
                      child: _submitting
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Koppeln'),
                    ),
                  ),
                  SizedBox(height: spacing.xxxl),
                  Text(
                    'Gerätename wird nach der Kopplung hier angezeigt.',
                    style: monitorStyles.label.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
