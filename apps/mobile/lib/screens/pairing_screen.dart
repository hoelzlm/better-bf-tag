import 'dart:async';

import 'package:bftag_api_client/bftag_api_client.dart'
    show PairRequestPlatformEnum;
import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../pairing_code_scanner.dart';

/// Pairing screen for `/pair`: scan a QR code (whose content is the
/// 8-character pairing code) or enter the code manually, per ADR 0010.
///
/// The scanner widget comes from [qrScannerBuilderProvider] (not a
/// constructor parameter), so it can be overridden uniformly regardless of
/// whether the screen is reached directly or via the router.
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _codeController = TextEditingController();
  String? _errorText;
  bool _isSubmitting = false;
  bool _scannerConsumed = false;

  @override
  void initState() {
    super.initState();
    // Shows a one-time hint when this screen is reached because the
    // device's session was revoked (as opposed to a normal/never-paired
    // Unpaired state). Checked post-frame (not in a ref.listen callback)
    // because by the time this screen is pushed by the router, the
    // revoked state transition has already happened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final session = ref.read(pairedSessionControllerProvider);
      if (session is PairedUnpaired && session.revoked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dieses Gerät wurde abgemeldet.')),
        );
        ref.read(pairedSessionControllerProvider.notifier).acknowledgeRevoked();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _pair(String code) async {
    if (_isSubmitting || code.trim().isEmpty) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      await ref
          .read(pairedSessionControllerProvider.notifier)
          .pair(
            code,
            platform: defaultTargetPlatform == TargetPlatform.iOS
                ? PairRequestPlatformEnum.ios
                : PairRequestPlatformEnum.android,
            appVersion: packageInfo.version,
          );
    } on PairingFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = failure.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _scannerConsumed = false;
        });
      }
    }
  }

  void _onScanned(String code) {
    if (_scannerConsumed || _isSubmitting) {
      return;
    }
    _scannerConsumed = true;
    unawaited(_pair(code));
  }

  /// Camera area: proportional (not fixed) height so it shrinks on small
  /// screens (app-kopplung.md AC6) while the manual code entry below it
  /// stays reachable without scrolling. A `surfaceContainer` placeholder
  /// with a centered camera icon sits behind the scanner widget, so the
  /// area never looks "empty" before/without a live preview.
  Widget _buildCameraArea(BuildContext context) {
    final theme = Theme.of(context);
    final radii = theme.extension<BftagRadii>()!;
    // Proportional to the *screen height* (not a fixed SizedBox), so the
    // area shrinks on short screens (app-kopplung.md AC6) — e.g. ~132 at
    // 600dp, ~141 at 360x640, ~186 at 390x844. Deriving the AspectRatio
    // from the available width keeps the result exactly at
    // `targetHeight` regardless of how wide the layout is.
    final screenHeight = MediaQuery.of(context).size.height;
    final targetHeight = (screenHeight * 0.22).clamp(110.0, 220.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspectRatio = constraints.maxWidth / targetHeight;
        return ClipRRect(
          borderRadius: BorderRadius.circular(radii.large),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: theme.colorScheme.surfaceContainer,
                  child: Center(
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 40,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ref.watch(qrScannerBuilderProvider)(_onScanned),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Divider(color: colorScheme.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'oder Code eingeben',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(child: Divider(color: colorScheme.outline)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Gerät koppeln')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'QR-Code scannen',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildCameraArea(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: _buildDivider(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        key: const Key('pair-code'),
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Code eingeben',
                          hintText: 'ABCD-EFGH',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (_) => _pair(_codeController.text),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const Key('pair-submit'),
                        onPressed: _isSubmitting
                            ? null
                            : () => _pair(_codeController.text),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : const Text('Koppeln'),
                      ),
                      if (_errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            key: const Key('pair-error'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 20,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorText!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
