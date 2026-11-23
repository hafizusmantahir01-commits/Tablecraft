import 'package:flutter/material.dart';

import '../data/app_info.dart';
import '../services/contact.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_3d.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _features = <(IconData, String, String)>[
    (Icons.grid_view_rounded, '50 levels', 'Five chapters of new pictures, in Easy, Medium or Hard'),
    (Icons.today_rounded, 'Daily puzzle', 'A new picture every day, with a bonus for a full week'),
    (Icons.add_photo_alternate_outlined, 'Your own photos', 'Turn any photo into a jigsaw puzzle'),
    (Icons.emoji_events_outlined, 'Stars and achievements', 'Solve without hints for 3 stars'),
    (Icons.palette_outlined, 'Six table backgrounds', 'Oak, walnut, linen, felt, slate and denim'),
    (Icons.wifi_off_rounded, 'Works offline', 'No account, no ads, no internet needed'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Tablecraft', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.cream,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Center(child: Logo3D(size: 96)),
          const SizedBox(height: 10),
          const Text(AppInfo.appName, textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const Text('Version ${AppInfo.version}',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.inkSoft)),
          const SizedBox(height: 16),
          const Text(
            'Tablecraft is a relaxing jigsaw puzzle game. Drag real-shaped pieces from the tray, '
            'watch them click into place, and build beautiful pictures at your own pace.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
            child: Column(children: [
              for (final (icon, title, text) in _features)
                ListTile(
                  leading: Icon(icon, color: AppColors.teal),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(text),
                ),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Made by', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
          const Text(AppInfo.developer, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _Tile(
            icon: Icons.mail_outline_rounded,
            title: 'Contact us',
            subtitle: AppInfo.supportEmail,
            onTap: () => contactSupport(context),
          ),
          _Tile(
            icon: Icons.description_outlined,
            title: 'Open source licenses',
            subtitle: 'Fonts and libraries used in the app',
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppInfo.appName,
              applicationVersion: AppInfo.version,
              applicationIcon: const Padding(padding: EdgeInsets.all(8), child: Logo3D(size: 56)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Icon(icon, color: AppColors.teal),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy policy', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.cream,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text('Last updated ${AppInfo.policyDate}', style: TextStyle(color: AppColors.inkSoft)),
          const SizedBox(height: 12),
          for (final (heading, body) in privacySections) ...[
            Text(heading, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(fontSize: 15, height: 1.45)),
            const SizedBox(height: 16),
          ],
          FilledButton.icon(
            onPressed: () => contactSupport(context),
            icon: const Icon(Icons.mail_outline_rounded),
            label: const Text('Email us'),
          ),
        ],
      ),
    );
  }
}
