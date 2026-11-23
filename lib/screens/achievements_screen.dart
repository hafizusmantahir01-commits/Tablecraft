import 'package:flutter/material.dart';

import '../data/achievements.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = StorageService.instance.stats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.cream,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: achievements.length,
        separatorBuilder: (context, i) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final a = achievements[i];
          final done = a.isDone(stats);
          final progress = a.progress(stats);
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: done ? AppColors.coin : AppColors.line, width: done ? 2 : 1),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: done ? AppColors.coin : AppColors.line,
                child: Icon(a.icon, color: done ? AppColors.ink : AppColors.inkSoft),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  Text(a.description, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                  if (!done && a.target > 1) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress / a.target,
                            minHeight: 6,
                            color: AppColors.teal,
                            backgroundColor: AppColors.line,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$progress / ${a.target}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ]),
                  ],
                ]),
              ),
              if (done) const Icon(Icons.check_circle_rounded, color: AppColors.teal),
            ]),
          );
        },
      ),
    );
  }
}
