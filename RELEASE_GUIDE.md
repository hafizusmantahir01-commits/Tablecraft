# Tablecraft release guide

Package name (Android) / bundle id (iOS): **com.inovexa.tablecraft**
Developer: Innovexa Technologies, innovexa.technologies01@gmail.com

## 1. Create the platform folders (once)

```bash
flutter create --org com.inovexa --project-name tablecraft --platforms android,ios,web .
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

If you already ran `flutter create` with another org, delete the `android/` and `ios/` folders and run the command again.

Then apply `release/AndroidManifest_changes.md` and set the iOS / web names (see README).

## 2. Signing key (.jks) - create once, keep forever

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- Remember both passwords. If this file or its password is lost, updates on Google Play need a key reset.
- Keep a backup of the .jks outside the project (e.g. company drive). It is ignored by Git.

Copy `release/key.properties.example` to `android/key.properties` and fill in the passwords.

Add the signing code from `release/app_build.gradle.kts.snippets` to `android/app/build.gradle.kts`
(or `release/app_build.gradle.groovy.snippets` if your file is `build.gradle`).

## 3. Builds

| What | Command | Output |
|---|---|---|
| Unsigned release APK | remove/rename `android/key.properties`, then `cd android` and `./gradlew assembleRelease` (Windows: `gradlew assembleRelease`) | `build/app/outputs/apk/release/app-release-unsigned.apk` |
| Signed release APK (final) | with `android/key.properties` in place: `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| Play Store bundle | `flutter build appbundle --release` | `build/app/outputs/bundle/release/app-release.aab` |
| Web | `flutter build web --release` | `build/web/` |
| iOS (Mac only) | `flutter build ipa --release` | `build/ios/ipa/` |

Check that an APK is signed: `apksigner verify --print-certs app-release.apk`
(apksigner is in Android SDK `build-tools/<version>/`).

Before every new Play upload, raise the build number in `pubspec.yaml` (`1.0.0+1` -> `1.0.0+2`).

## 4. Store listing files (store_assets/)

| File | Play Console field |
|---|---|
| `icon-512.png` | App icon (512 x 512 PNG) |
| `feature-graphic-1024x500.png` | Feature graphic |
| `screenshot-1..5.png` | Phone screenshots (1080 x 1920, 9:16) |
| `icon-preview.png` | For checking only: icon in Play / circle / squircle / square masks |
| `release/privacy_policy.html` | Host it (e.g. GitHub Pages) and paste the URL in "Privacy policy" |

Regenerate graphics: `pip install cairosvg pillow` then `python tool/make_store_assets.py`.
Real screenshots: put 1080x1920 PNGs in `store_assets/real/1.png ... 5.png` and run it again.

Delete-account page: not needed. Tablecraft has no login or sign-up and no server data.
In-app data deletion is available: About and privacy -> Reset all game data.

Data safety form (Play Console): no data collected, no data shared.

## 5. Repository

```bash
git init
git add .
git commit -m "Tablecraft 1.0.0"
git remote add origin https://github.com/<company>/tablecraft.git     # first time
git remote set-url origin https://github.com/<company>/tablecraft.git # changing to a new repo
git remote -v        # check the link
git push -u origin main
```

`git remote set-url` changes the `url =` line under `[remote "origin"]` in `.git/config`
(you can also edit that file directly). Give the company account access in
GitHub -> Settings -> Collaborators.
