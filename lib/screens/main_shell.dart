import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'create_tab.dart';
import 'daily_tab.dart';
import 'levels_tab.dart';
import 'me_tab.dart';

/// The main screen with four tabs at the bottom: Levels, Daily, Create, Me.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    // Back button: on any other tab it goes to Levels first; on Levels it closes the app.
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => index = 0);
      },
      child: Scaffold(
        // IndexedStack keeps every tab alive, so its scroll position is not lost when switching.
        body: IndexedStack(index: index, children: const [LevelsTab(), DailyTab(), CreateTab(), MeTab()]),
        bottomNavigationBar: ValueListenableBuilder<int>(
          valueListenable: storage.changes,
          builder: (context, _, __) {
            final todayDone = storage.isDailyDone(dayKey(DateTime.now()));
            return NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => setState(() => index = i),
              backgroundColor: AppColors.card,
              indicatorColor: const Color(0xFFE2EFEC),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.teal),
                  label: 'Levels',
                ),
                NavigationDestination(
                  // Small dot until today's puzzle is solved.
                  icon: Badge(isLabelVisible: !todayDone, smallSize: 8, child: const Icon(Icons.today_outlined)),
                  selectedIcon: Badge(
                    isLabelVisible: !todayDone,
                    smallSize: 8,
                    child: const Icon(Icons.today_rounded, color: AppColors.teal),
                  ),
                  label: 'Daily',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.add_photo_alternate_outlined),
                  selectedIcon: Icon(Icons.add_photo_alternate_rounded, color: AppColors.teal),
                  label: 'Create',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded, color: AppColors.teal),
                  label: 'Me',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
