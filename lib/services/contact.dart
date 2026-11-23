import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_info.dart';

/// Opens the email app with our address and a subject already filled in.
/// If the device has no email app, the address is copied so the player can paste it.
Future<void> contactSupport(BuildContext context) async {
  final email = Uri(
    scheme: 'mailto',
    path: AppInfo.supportEmail,
    query: 'subject=${Uri.encodeComponent('${AppInfo.appName} ${AppInfo.version} feedback')}',
  );
  var opened = false;
  try {
    opened = await launchUrl(email, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (opened || !context.mounted) return;
  await Clipboard.setData(const ClipboardData(text: AppInfo.supportEmail));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('No email app found. Our address was copied: ${AppInfo.supportEmail}')),
  );
}
