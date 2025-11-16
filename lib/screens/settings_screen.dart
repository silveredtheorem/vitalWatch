import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final bool isFallDetectionEnabled;
  final ValueChanged<bool> onToggleFallDetection;

  const SettingsScreen({
    super.key,
    required this.isFallDetectionEnabled,
    required this.onToggleFallDetection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          SwitchListTile(
            title: const Text('Automatic Fall Detection'),
            subtitle: const Text('Automatically send a Medical SOS when a fall is detected.'),
            value: isFallDetectionEnabled,
            onChanged: onToggleFallDetection,
            secondary: const Icon(Icons.shield_outlined),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
