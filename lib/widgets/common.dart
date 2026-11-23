import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/puzzle_info.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// Round 44 x 44 button used in top bars.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;
  final bool onDark;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = active
        ? AppColors.teal
        : (onDark ? const Color(0x24FFFFFF) : const Color(0xEBFFFAF0));
    final iconColor = active ? Colors.white : (onDark ? Colors.white : AppColors.ink);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: CircleBorder(side: BorderSide(color: onDark ? const Color(0x38FFFFFF) : const Color(0x4D6B4A2B))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 22, color: iconColor)),
        ),
      ),
    );
  }
}

/// Gold coin with a puzzle piece on it.
class CoinIcon extends StatelessWidget {
  final double size;
  const CoinIcon({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.coin,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.coinDark, width: size * 0.07),
      ),
      child: Icon(Icons.extension, size: size * 0.6, color: const Color(0xFFFFF4DC)),
    );
  }
}

class CoinBadge extends StatelessWidget {
  final int amount;
  const CoinBadge({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x336E461E), offset: Offset(0, 2))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const CoinIcon(),
        const SizedBox(width: 6),
        Text('$amount', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      ]),
    );
  }
}

/// Shows a puzzle picture, whether it is built in or from the gallery.
/// [thumbnail] loads a small copy, which saves memory in long lists.
class PuzzleImage extends StatelessWidget {
  final PuzzleInfo puzzle;
  final bool thumbnail;
  const PuzzleImage({super.key, required this.puzzle, this.thumbnail = false});

  @override
  Widget build(BuildContext context) {
    final cacheWidth = thumbnail ? 320 : null;
    Widget fallback(BuildContext context, Object error, StackTrace? stack) => Container(color: AppColors.line);
    if (puzzle.bytes != null) {
      return Image.memory(puzzle.bytes!, fit: BoxFit.cover, cacheWidth: cacheWidth, errorBuilder: fallback);
    }
    if (puzzle.filePath != null) {
      return Image.file(
        File(StorageService.instance.photoPath(puzzle.filePath!)),
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        errorBuilder: fallback,
      );
    }
    return Image.asset(puzzle.assetPath!, fit: BoxFit.cover, cacheWidth: cacheWidth, errorBuilder: fallback);
  }
}

String formatTime(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// 0 to 3 stars in a row. Empty stars are drawn as outlines.
class StarRow extends StatelessWidget {
  final int stars;
  final double size;
  final MainAxisAlignment alignment;
  const StarRow({super.key, required this.stars, this.size = 16, this.alignment = MainAxisAlignment.center});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < stars ? AppColors.coin : const Color(0x996E5034),
          ),
      ],
    );
  }
}

/// Round profile picture: the player's photo, or the first letter of their name.
class Avatar extends StatelessWidget {
  final Uint8List? photo;
  final String name;
  final double size;
  const Avatar({super.key, required this.photo, required this.name, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.teal,
        border: Border.all(color: AppColors.card, width: size * 0.05),
        image: photo == null ? null : DecorationImage(image: MemoryImage(photo!), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: photo == null
          ? Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: size * 0.42),
            )
          : null,
    );
  }
}
