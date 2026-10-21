import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Login screen for `/admin/login`. No Chrome/Sidebar (web-login.md §3):
/// the admin shell only wraps signed-in routes.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .login(_usernameController.text, _passwordController.text);
    } on LoginFailure catch (failure) {
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
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<BftagSpacing>() ?? const BftagSpacing();
    final radii = theme.extension<BftagRadii>() ?? const BftagRadii();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(spacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(radii.medium),
                        ),
                        child: Icon(
                          Icons.local_fire_department,
                          color: theme.colorScheme.onPrimary,
                          size: 36,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing.lg),
                    Center(
                      child: Text('BF-Tag', style: theme.textTheme.titleLarge),
                    ),
                    SizedBox(height: spacing.xl),
                    TextField(
                      key: const Key('login-username'),
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Benutzername',
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    SizedBox(height: spacing.lg),
                    TextField(
                      key: const Key('login-password'),
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Passwort'),
                      onSubmitted: (_) => _submit(),
                      textInputAction: TextInputAction.done,
                    ),
                    SizedBox(height: spacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorText != null) ...[
                          Icon(
                            Icons.warning_amber_outlined,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          SizedBox(width: spacing.xs),
                        ],
                        Expanded(
                          child: Text(
                            _errorText ?? '',
                            key: const Key('login-error'),
                            softWrap: true,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('login-submit'),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Anmelden'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
