import 'package:flutter/material.dart';

/// Placeholder for `/monitor`, until the monitor is coupled to a device.
class MonitorPlaceholderScreen extends StatelessWidget {
  const MonitorPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Monitor – noch nicht gekoppelt',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
