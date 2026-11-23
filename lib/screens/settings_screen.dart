import 'package:flutter/material.dart';

import '../data/table_backgrounds.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'backgrounds_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _reset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Reset all game data?'),
        content: const Text(
          'This deletes your levels, stars, coins, achievements, profile, unfinished puzzle and saved photos '
          'on this device. It cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB3261E)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await StorageService.instance.resetAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All game data was deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.cream,
      ),
      // Rebuilds when a setting changes.
      body: ValueListenableBuilder<int>(
        valueListenable: storage.changes,
        builder: (context, _, __) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _Card(
              child: SwitchListTile(
                value: storage.sound,
                onChanged: storage.setSound,
                secondary: const Icon(Icons.volume_up_outlined, color: AppColors.teal),
                title: const Text('Sound effects', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Click when a piece fits, music when you win'),
              ),
            ),
            _Card(
              child: SwitchListTile(
                value: storage.vibration,
                onChanged: storage.setVibration,
                secondary: const Icon(Icons.vibration_rounded, color: AppColors.teal),
                title: const Text('Vibration', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Short buzz when a piece snaps in'),
              ),
            ),
            _Card(
              child: ListTile(
                leading: const Icon(Icons.palette_outlined, color: AppColors.teal),
                title: const Text('Table background', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(backgroundById(storage.backgroundId).name),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackgroundsScreen())),
              ),
            ),
            _Card(
              child: ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFB3261E)),
                title: const Text('Reset all game data', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFB3261E))),
                subtitle: const Text('Delete everything saved on this device'),
                onTap: () => _reset(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.line)),
        child: child,
      ),
    );
  }
}
