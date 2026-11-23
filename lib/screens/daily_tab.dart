import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../data/table_backgrounds.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/table_surface.dart';
import 'play_actions.dart';

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

String _longDate(DateTime d) => '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

/// "22 - 28 November", or "29 November - 5 December" when the week crosses a month.
String _weekRange(List<DateTime> week) {
  final a = week.first, b = week.last;
  return a.month == b.month
      ? '${a.day} - ${b.day} ${_months[b.month - 1]}'
      : '${a.day} ${_months[a.month - 1]} - ${b.day} ${_months[b.month - 1]}';
}

/// Tab 2: this week's 7 daily puzzles and today's big card.
class DailyTab extends StatelessWidget {
  const DailyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    return ValueListenableBuilder<int>(
      valueListenable: storage.changes,
      builder: (context, _, __) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final todayPuzzle = dailyPuzzle(today);
        final todayDone = storage.isDailyDone(dayKey(today));
        final week = weekOf(today, storage.firstDay); // week 1 starts on the day the app was installed
        final weekNo = weekNumber(today, storage.firstDay);
        final doneThisWeek = week.where((d) => storage.isDailyDone(dayKey(d))).length;
        final background = backgroundById(storage.backgroundId);
        final textColor = background.isDark ? Colors.white : AppColors.woodText;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            TableSurface(
              background: background,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(children: [
                    Expanded(
                      child: Text('Daily puzzle', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor)),
                    ),
                    _StreakChip(days: storage.dailyStreak),
                  ]),
                ),
              ),
            ),

            // ---------- this week ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Week $weekNo', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        Text(_weekRange(week), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                      ]),
                    ),
                    Text('$doneThisWeek / 7', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.teal)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    for (var i = 0; i < 7; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: _WeekDayTile(
                          day: week[i],
                          isToday: week[i] == today,
                          done: storage.isDailyDone(dayKey(week[i])),
                          locked: !isDayOpen(week[i], now),
                          onTap: () => _tapDay(context, week[i], now),
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.emoji_events_rounded, size: 20, color: doneThisWeek == 7 ? AppColors.coin : AppColors.inkSoft),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doneThisWeek == 7
                            ? 'Perfect week! You earned $perfectWeekBonus bonus coins.'
                            : 'Solve all 7 days for $perfectWeekBonus bonus coins',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),

            // ---------- today ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(22),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => PlayActions.openDaily(context, today),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Stack(fit: StackFit.expand, children: [
                        PuzzleImage(puzzle: todayPuzzle),
                        if (todayDone)
                          const Positioned(
                            top: 12,
                            right: 12,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.teal,
                              child: Icon(Icons.check_rounded, color: Colors.white),
                            ),
                          ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Today, ${_longDate(today)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.inkSoft)),
                            Text(todayPuzzle.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            const Text('${dailyGridSize * dailyGridSize} pieces', style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                          ]),
                        ),
                        FilledButton(
                          onPressed: () => PlayActions.openDaily(context, today),
                          child: Text(todayDone ? 'Again' : 'Play'),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  void _tapDay(BuildContext context, DateTime day, DateTime now) {
    if (isDayOpen(day, now)) {
      PlayActions.openDaily(context, day);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('This puzzle opens on ${_longDate(day)}.')));
  }
}

/// One day in the week row: weekday letter, date, and its state.
class _WeekDayTile extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool done;
  final bool locked;
  final VoidCallback onTap;

  const _WeekDayTile({required this.day, required this.isToday, required this.done, required this.locked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color fill = done ? AppColors.teal : (isToday ? const Color(0xFFE2EFEC) : (locked ? const Color(0xFFF1E9DC) : AppColors.cream));
    final Color fg = done ? Colors.white : (locked ? const Color(0xFFA8957E) : AppColors.ink);
    final IconData icon = done
        ? Icons.check_rounded
        : locked
            ? Icons.lock_rounded
            : (isToday ? Icons.play_arrow_rounded : Icons.circle_outlined);

    return Semantics(
      button: true,
      label: '${_weekdays[day.weekday - 1]} ${day.day}${done ? ', solved' : locked ? ', locked' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isToday ? AppColors.teal : AppColors.line, width: isToday ? 2 : 1),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_weekdays[day.weekday - 1].substring(0, 1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: fg)),
            Text('${day.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: fg)),
            const SizedBox(height: 2),
            Icon(icon, size: 16, color: fg),
          ]),
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  final int days;
  const _StreakChip({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_fire_department_rounded, color: days > 0 ? const Color(0xFFE0612A) : AppColors.inkSoft),
        const SizedBox(width: 4),
        Text(days == 1 ? '1 day' : '$days days', style: const TextStyle(fontWeight: FontWeight.w900)),
      ]),
    );
  }
}
