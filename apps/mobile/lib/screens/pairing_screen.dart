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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerät koppeln')),
      body: Column(
        children: [
          SizedBox(
            height: 240,
            child: ref.watch(qrScannerBuilderProvider)(_onScanned),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Koppeln'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorText ?? '',
                          key: const Key('pair-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
