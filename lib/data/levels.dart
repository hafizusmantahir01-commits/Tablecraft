import '../models/puzzle_info.dart';

/// 50 levels in 5 chapters of 10. The pictures are assets/puzzles/level_01.jpg ... level_50.jpg,
/// made by tool/make_level_images.py with the same scene and mood lists as below.
const int levelCount = 50;
const int levelsPerChapter = 10;

const chapterNames = ['First Steps', 'Warming Up', 'Getting Serious', 'Puzzle Pro', 'Master Table'];

// Same order as PLACES and MOODS in tool/make_level_images.py.
const _places = [
  'Fields', 'Lake', 'Harbour', 'Dunes', 'Woods', 'City', 'Lighthouse', 'Balloons',
  'Castle', 'Beach', 'Cabin', 'Waterfall', 'Reef', 'Space', 'Garden',
];
const _moods = ['Morning', 'Sunny', 'Spring', 'Golden', 'Autumn', 'Misty', 'Winter', 'Sunset', 'Dusk', 'Night'];
const _specialWords = {
  'Reef': ['Coral', 'Sunlit', 'Bright', 'Golden', 'Hidden', 'Quiet', 'Cold', 'Deep', 'Blue', 'Secret'],
  'Space': ['Red', 'Ringed', 'Bright', 'Golden', 'Far', 'Silent', 'Frozen', 'Fiery', 'Purple', 'Deep'],
};

/// Each level gets a different scene than the one before it, and no picture repeats.
String levelTitle(int level) {
  final place = _places[(level - 1) % _places.length];
  final mood = (level + 3 * ((level - 1) ~/ _places.length)) % _moods.length;
  final word = _specialWords[place]?[mood] ?? _moods[mood];
  return '$word $place';
}

int chapterOf(int level) => (level - 1) ~/ levelsPerChapter; // 0..4

String _picture(int number) => 'assets/puzzles/level_${number.toString().padLeft(2, '0')}.jpg';

/// The puzzle for a level (1..50).
PuzzleInfo levelPuzzle(int level) => PuzzleInfo(
      id: 'level_$level',
      title: levelTitle(level),
      category: chapterNames[chapterOf(level)],
      kind: PuzzleKind.level,
      assetPath: _picture(level),
      level: level,
    );

// ---------- difficulty ----------

/// The player picks how hard the levels are. Every mode still starts small and grows slowly.
enum Difficulty { easy, medium, hard }

const difficultyNames = {Difficulty.easy: 'Easy', Difficulty.medium: 'Medium', Difficulty.hard: 'Hard'};

const difficultyHints = {
  Difficulty.easy: 'Fewer, bigger pieces. Relaxed.',
  Difficulty.medium: 'A balanced challenge.',
  Difficulty.hard: 'More pieces, and pieces start turned.',
};

/// Grid size (pieces per row) for a level. Level 1 is the smallest, level 50 the biggest,
/// growing by one row only every few levels.
///   Easy:   2x2 (4)  ->  6x6 (36)
///   Medium: 3x3 (9)  ->  8x8 (64)
///   Hard:   4x4 (16) -> 10x10 (100)
int gridFor(int level, Difficulty difficulty) {
  final (smallest, biggest) = switch (difficulty) {
    Difficulty.easy => (2, 6),
    Difficulty.medium => (3, 8),
    Difficulty.hard => (4, 10),
  };
  final progress = (level - 1) / (levelCount - 1); // 0.0 at level 1, 1.0 at level 50
  return (smallest + progress * (biggest - smallest)).round();
}

/// Only Hard mode turns the pieces.
bool rotationFor(Difficulty difficulty) => difficulty == Difficulty.hard;

// ---------- daily puzzle ----------

/// "2026-11-22": the same text for the whole day, used as the save key.
String dayKey(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

/// Days from [from] to [to], counting calendar days (not hours).
int daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Every date gets its own picture. The same date always gives the same picture,
/// on every phone, without needing a server.
PuzzleInfo dailyPuzzle(DateTime day) {
  final daysSince2020 = daysBetween(DateTime(2020), day);
  final picture = (daysSince2020 * 17) % levelCount + 1; // 17 jumps around so nearby days look different
  final key = dayKey(day);
  return PuzzleInfo(
    id: 'daily_$key',
    title: levelTitle(picture),
    category: 'Daily puzzle',
    kind: PuzzleKind.daily,
    assetPath: _picture(picture),
    dailyKey: key,
  );
}

/// Daily puzzles are always 36 pieces.
const int dailyGridSize = 6;

/// How many days in a row (ending today, or yesterday if today is not done yet) were solved.
int currentStreak(Set<String> doneDays, DateTime today) {
  var day = DateTime(today.year, today.month, today.day);
  // DateTime(y, m, d - 1) is "the day before" and stays correct across month ends and clock changes.
  if (!doneDays.contains(dayKey(day))) day = DateTime(day.year, day.month, day.day - 1);
  var streak = 0;
  while (doneDays.contains(dayKey(day))) {
    streak++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return streak;
}

/// Stars for a finished puzzle: no hints = 3, one hint = 2, more = 1.
int starsFor(int hintsUsed) => hintsUsed == 0 ? 3 : (hintsUsed == 1 ? 2 : 1);

// ---------- the daily week ----------
// Week 1 starts on the day the app was first opened. Each week is 7 days long.

/// Coins for solving all 7 daily puzzles of one week.
const int perfectWeekBonus = 100;

/// 1 for the first 7 days after [firstDay], 2 for the next 7, and so on.
int weekNumber(DateTime day, DateTime firstDay) => daysBetween(firstDay, day) ~/ 7 + 1;

/// The 7 days of the week that contains [day].
List<DateTime> weekOf(DateTime day, DateTime firstDay) {
  final offset = (weekNumber(day, firstDay) - 1) * 7;
  final start = DateTime(firstDay.year, firstDay.month, firstDay.day + offset);
  return [for (var i = 0; i < 7; i++) DateTime(start.year, start.month, start.day + i)];
}

/// A daily puzzle can be played on its own date or later, never before.
bool isDayOpen(DateTime day, DateTime now) => daysBetween(now, day) <= 0;
