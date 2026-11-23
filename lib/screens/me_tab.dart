import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/achievements.dart';
import '../data/table_backgrounds.dart';
import '../services/contact.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/table_surface.dart';
import 'about_screen.dart';
import 'achievements_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';

/// Tab 3: the player's profile, stats, achievements and app pages.
class MeTab extends StatelessWidget {
  const MeTab({super.key});

  StorageService get storage => StorageService.instance;

  Future<void> _changePhoto(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose a photo'),
            onTap: () => Navigator.pop(sheetContext, 'pick'),
          ),
          if (storage.avatar != null)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Remove photo'),
              onTap: () => Navigator.pop(sheetContext, 'remove'),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (choice == 'remove') await storage.setAvatar(null);
    if (choice == 'pick') {
      // Small picture is enough for a profile and keeps saved data light.
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 300, maxHeight: 300, imageQuality: 80);
      if (picked != null) await storage.setAvatar(await picked.readAsBytes());
    }
  }

  Future<void> _changeName(BuildContext context) async {
    final field = TextEditingController(text: storage.playerName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Your name'),
        content: TextField(
          controller: field,
          autofocus: true,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Enter your name'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, field.text), child: const Text('Save')),
        ],
      ),
    );
    if (name != null) await storage.setPlayerName(name);
  }

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: storage.changes,
      builder: (context, _, __) {
        final background = backgroundById(storage.backgroundId);
        final textColor = background.isDark ? Colors.white : AppColors.woodText;
        final stats = storage.stats;
        final unlocked = achievements.where((a) => a.isDone(stats)).length;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            TableSurface(
              background: background,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(children: [
                    // Tap the picture to change it.
                    GestureDetector(
                      onTap: () => _changePhoto(context),
                      child: Stack(children: [
                        Avatar(photo: storage.avatar, name: storage.playerName, size: 96),
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: AppColors.card,
                            child: Icon(Icons.photo_camera_outlined, size: 17, color: AppColors.teal),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    // Tap the name to change it.
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _changeName(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(storage.playerName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_outlined, size: 18, color: textColor),
                        ]),
                      ),
                    ),
                    Text('Reached level ${storage.unlockedLevel}',
                        style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                _Stat(value: '${stats.solved}', label: 'Solved'),
                const SizedBox(width: 8),
                _Stat(value: '${stats.levelsDone}', label: 'Levels'),
                const SizedBox(width: 8),
                _Stat(value: '${stats.bestStreak}', label: 'Best streak'),
                const SizedBox(width: 8),
                _Stat(value: '${storage.coins}', label: 'Coins'),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _open(context, const AchievementsScreen()),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Text('Achievements', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                        const Spacer(),
                        Text('$unlocked / ${achievements.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.inkSoft)),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
                      ]),
                      const SizedBox(height: 10),
                      // First few badges: coloured when reached, grey when not.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final a in achievements.take(6))
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: a.isDone(stats) ? AppColors.coin : AppColors.line,
                              child: Icon(a.icon, color: a.isDone(stats) ? AppColors.ink : AppColors.inkSoft, size: 22),
                            ),
                        ],
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _MenuTile(icon: Icons.settings_outlined, title: 'Settings', onTap: () => _open(context, const SettingsScreen())),
            _MenuTile(icon: Icons.help_outline_rounded, title: 'How to play', onTap: () => _open(context, const HelpScreen())),
            _MenuTile(icon: Icons.mail_outline_rounded, title: 'Contact us', onTap: () => contactSupport(context)),
            _MenuTile(icon: Icons.info_outline_rounded, title: 'About Tablecraft', onTap: () => _open(context, const AboutScreen())),
            _MenuTile(icon: Icons.privacy_tip_outlined, title: 'Privacy policy', onTap: () => _open(context, const PrivacyScreen())),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
        ]),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.line)),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Icon(icon, color: AppColors.teal),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
