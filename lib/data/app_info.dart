/// Facts about the app shown on the About screen and in the privacy policy.
class AppInfo {
  static const appName = 'Tablecraft';
  static const version = '1.0.0'; // keep in sync with "version" in pubspec.yaml
  static const developer = 'Innovexa Technologies';
  static const supportEmail = 'innovexa.technologies01@gmail.com';
  static const policyDate = 'November 22, 2026';
}

/// The privacy policy, shown inside the app. The same text is in privacy_policy.html
/// for the Google Play listing.
const privacySections = <(String, String)>[
  (
    'Summary',
    'Tablecraft is an offline jigsaw puzzle game. It has no accounts, no ads and no analytics. '
        'We do not collect, sell or share any personal information.',
  ),
  (
    'What is stored on your device',
    'To remember your game, Tablecraft saves a few things on your device only: your level progress and stars, '
        'daily puzzles, coins, best times, achievements, settings, an unfinished puzzle, and the name and profile '
        'picture you choose. This data never leaves your device and is not sent to us or anyone else.',
  ),
  (
    'Your photos',
    'When you use Create or change your profile picture, Tablecraft opens your photo gallery or camera '
        'only when you ask it to, and only uses the one photo you pick or take. On Android and iOS a copy of that photo is kept inside the app so you can '
        'continue the puzzle later. On the web the photo stays in memory and is gone when you close the page. '
        'Photos are never uploaded.',
  ),
  (
    'Internet and permissions',
    'Tablecraft does not need an internet connection to play. The only permission it may ask for is access to '
        'your photos or camera, and only when you pick or take a photo yourself.',
  ),
  (
    'Deleting your data',
    'You can delete everything Tablecraft has saved at any time: open Me, then Settings, then Reset all game data. '
        'Uninstalling the app also removes all of its data.',
  ),
  (
    'Children',
    'Tablecraft is suitable for all ages. Because we collect no personal information, we do not knowingly collect '
        'information from children.',
  ),
  (
    'Changes to this policy',
    'If this policy changes, the new version will be published on this page with a new date.',
  ),
  (
    'Contact',
    'Questions about this policy: ${AppInfo.supportEmail}',
  ),
];
