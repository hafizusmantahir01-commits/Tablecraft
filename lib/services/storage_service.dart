import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/achievements.dart';
import '../data/levels.dart';
import '../models/puzzle_info.dart';

/// What saving a finished game tells the "complete" screen.
class WinRecord {
  final bool isNewBest;
  final int? bestSeconds;
  final bool perfectWeek; // this puzzle completed all 7 days of its week
  final List<Achievement> newAchievements;
  const WinRecord(this.isNewBest, this.bestSeconds, this.perfectWeek, this.newAchievements);
}

/// Saves small pieces of data on the device: coins, level progress, daily puzzles,
/// stats, profile, settings and an unfinished game.
/// It is a singleton: the whole app uses the same StorageService.instance.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late SharedPreferences _prefs;
  String? _photosFolder; // only on Android/iOS; the web has no file system

  /// Goes up by one after every save. Screens listen to it to refresh themselves.
  final ValueNotifier<int> changes = ValueNotifier(0);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _rememberFirstDay();
    if (!kIsWeb) {
      final docs = await getApplicationDocumentsDirectory();
      _photosFolder = '${docs.path}/photos';
    }
  }

  Future<void> _done(Future<bool> write) async {
    await write;
    changes.value++;
  }

  int _int(String key) => _prefs.getInt(key) ?? 0;

  // ---------- coins ----------

  static const int startingCoins = 100;
  static const int hintPrice = 20;

  int get coins => _prefs.getInt('coins') ?? startingCoins;

  Future<void> addCoins(int amount) async {
    await _prefs.setInt('coins_earned_total', _int('coins_earned_total') + amount);
    await _done(_prefs.setInt('coins', coins + amount));
  }

  Future<bool> spendCoins(int amount) async {
    if (coins < amount) return false;
    await _done(_prefs.setInt('coins', coins - amount));
    return true;
  }

  // ---------- levels ----------

  /// The highest level the player may play. Level 1 is always open.
  int get unlockedLevel => _prefs.getInt('unlocked_level') ?? 1;

  bool isLevelUnlocked(int level) => level <= unlockedLevel;

  /// 0 = not finished yet, otherwise 1 to 3 stars.
  int levelStars(int level) => _int('stars_$level');

  int get levelsDone => [for (var l = 1; l <= levelCount; l++) l].where((l) => levelStars(l) > 0).length;

  Future<void> _completeLevel(int level, int stars) async {
    if (stars > levelStars(level)) await _prefs.setInt('stars_$level', stars);
    if (level >= unlockedLevel && level < levelCount) {
      await _prefs.setInt('unlocked_level', level + 1); // finishing a level opens the next one
    }
  }

  // ---------- daily puzzles ----------

  Set<String> get dailyDone => (_prefs.getStringList('daily_done') ?? const <String>[]).toSet();

  bool isDailyDone(String key) => dailyDone.contains(key);

  int get dailyStreak => currentStreak(dailyDone, DateTime.now());

  Future<void> _completeDaily(String key) async {
    final days = dailyDone..add(key);
    await _prefs.setStringList('daily_done', days.toList());
    final streak = currentStreak(days, DateTime.now());
    if (streak > _int('best_streak')) await _prefs.setInt('best_streak', streak);
  }

  /// The day the app was first opened. The daily "week 1" starts here.
  DateTime get firstDay => DateTime.tryParse(_prefs.getString('first_day') ?? '') ?? DateTime.now();

  Future<void> _rememberFirstDay() async {
    if (_prefs.getString('first_day') == null) {
      await _prefs.setString('first_day', dayKey(DateTime.now()));
    }
  }

  int get perfectWeeks => _int('perfect_weeks');

  /// After a daily puzzle: if all 7 days of its week are now done, give the bonus (once per week).
  Future<bool> _checkPerfectWeek(String key) async {
    final week = weekOf(DateTime.parse(key), firstDay); // the 7 days of the week this puzzle belongs to
    final done = dailyDone;
    if (!week.every((day) => done.contains(dayKey(day)))) return false;
    final weekId = dayKey(week.first);
    final rewarded = _prefs.getStringList('perfect_weeks_rewarded') ?? <String>[];
    if (rewarded.contains(weekId)) return false;
    await _prefs.setStringList('perfect_weeks_rewarded', [...rewarded, weekId]);
    await _prefs.setInt('perfect_weeks', perfectWeeks + 1);
    await addCoins(perfectWeekBonus);
    return true;
  }

  // ---------- best times ----------

  int? bestTime(String puzzleId, int pieceCount) => _prefs.getInt('best_${puzzleId}_$pieceCount');

  // ---------- stats and achievements ----------

  PlayerStats get stats => PlayerStats(
        solved: _int('solved'),
        levelsDone: levelsDone,
        noHintSolves: _int('no_hint_solves'),
        maxPieces: _int('max_pieces'),
        photoSolves: _int('photo_solves'),
        bestStreak: _int('best_streak'),
        coinsEarnedTotal: _int('coins_earned_total'),
        fastSolve: _prefs.getBool('fast_solve') ?? false,
        perfectWeeks: perfectWeeks,
      );

  /// Saves everything about a finished puzzle in one place.
  Future<WinRecord> recordWin({
    required PuzzleInfo puzzle,
    required int pieceCount,
    required int seconds,
    required int hintsUsed,
    required int coinsEarned,
  }) async {
    // Best time for this picture and size.
    final bestKey = 'best_${puzzle.id}_$pieceCount';
    final oldBest = _prefs.getInt(bestKey);
    final isNewBest = oldBest == null || seconds < oldBest;
    if (isNewBest) await _prefs.setInt(bestKey, seconds);

    // Stats.
    await _prefs.setInt('solved', _int('solved') + 1);
    if (hintsUsed == 0) await _prefs.setInt('no_hint_solves', _int('no_hint_solves') + 1);
    await _prefs.setInt('max_pieces', max(_int('max_pieces'), pieceCount));
    if (puzzle.kind == PuzzleKind.photo) await _prefs.setInt('photo_solves', _int('photo_solves') + 1);
    if (pieceCount >= 25 && seconds < 180) await _prefs.setBool('fast_solve', true);

    // Progress.
    if (puzzle.kind == PuzzleKind.level) await _completeLevel(puzzle.level!, starsFor(hintsUsed));
    var perfectWeek = false;
    if (puzzle.kind == PuzzleKind.daily) {
      await _completeDaily(puzzle.dailyKey!);
      perfectWeek = await _checkPerfectWeek(puzzle.dailyKey!);
    }

    await addCoins(coinsEarned);
    await clearSavedGame();

    return WinRecord(isNewBest, _prefs.getInt(bestKey), perfectWeek, await _takeNewAchievements());
  }

  /// Achievements reached now that were not reached before (each one is shown only once).
  Future<List<Achievement>> _takeNewAchievements() async {
    final seen = (_prefs.getStringList('achievements_seen') ?? <String>[]).toSet();
    final s = stats;
    final fresh = achievements.where((a) => a.isDone(s) && !seen.contains(a.id)).toList();
    if (fresh.isNotEmpty) {
      await _done(_prefs.setStringList('achievements_seen', [...seen, ...fresh.map((a) => a.id)]));
    }
    return fresh;
  }

  // ---------- profile ----------

  String get playerName => _prefs.getString('player_name') ?? 'Player';

  Future<void> setPlayerName(String name) => _done(_prefs.setString('player_name', name.trim().isEmpty ? 'Player' : name.trim()));

  /// Small profile picture, stored as text (base64) so it works on phones and the web alike.
  Uint8List? get avatar {
    final text = _prefs.getString('avatar');
    return text == null ? null : base64Decode(text);
  }

  Future<void> setAvatar(Uint8List? bytes) =>
      _done(bytes == null ? _prefs.remove('avatar') : _prefs.setString('avatar', base64Encode(bytes)));

  // ---------- settings ----------

  /// Easy, Medium or Hard for levels. The last choice is remembered.
  Difficulty get levelDifficulty =>
      Difficulty.values.asNameMap()[_prefs.getString('level_difficulty')] ?? Difficulty.medium;

  Future<void> setLevelDifficulty(Difficulty d) => _done(_prefs.setString('level_difficulty', d.name));

  bool get sound => _prefs.getBool('sound') ?? true;

  Future<void> setSound(bool on) => _done(_prefs.setBool('sound', on));

  bool get vibration => _prefs.getBool('vibration') ?? true;

  Future<void> setVibration(bool on) => _done(_prefs.setBool('vibration', on));

  String get backgroundId => _prefs.getString('background') ?? 'oak';

  Future<void> setBackground(String id) => _done(_prefs.setString('background', id));

  // ---------- unfinished game ----------
  // Stored as JSON text, because SharedPreferences only keeps simple values.

  SavedGame? get savedGame {
    final text = _prefs.getString('saved_game');
    if (text == null) return null;
    try {
      return SavedGame.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      return null; // old or broken data: just ignore it
    }
  }

  Future<void> saveGame(SavedGame game) => _done(_prefs.setString('saved_game', jsonEncode(game.toJson())));

  Future<void> clearSavedGame() => _done(_prefs.remove('saved_game'));

  // ---------- player photos (Android and iOS only) ----------

  /// The gallery gives us a temporary file. We copy it into the app's own folder
  /// so an unfinished photo puzzle still works tomorrow. We store only the file NAME,
  /// because on iOS the full folder path can change after an app update.
  Future<String> keepPhoto(XFile picked) async {
    final folder = Directory(_photosFolder!);
    if (!await folder.exists()) await folder.create(recursive: true);
    final name = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File('${folder.path}/$name').writeAsBytes(await picked.readAsBytes());
    return name;
  }

  /// Full path of a saved photo from its file name.
  String photoPath(String name) => '$_photosFolder/${name.split('/').last}';

  // ---------- reset ----------

  /// Deletes everything the app saved on this device.
  Future<void> resetAll() async {
    await _prefs.clear();
    await _rememberFirstDay(); // a fresh start: week 1 begins today
    if (!kIsWeb && _photosFolder != null) {
      final folder = Directory(_photosFolder!);
      if (await folder.exists()) await folder.delete(recursive: true);
    }
    changes.value++;
  }
}
