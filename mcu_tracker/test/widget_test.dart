import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mcu_tracker/data.dart';
import 'package:mcu_tracker/main.dart';
import 'package:mcu_tracker/store.dart';

Future<TrackerStore> _freshStore([Map<String, Object> seed = const {}]) async {
  SharedPreferences.setMockInitialValues(seed);
  return TrackerStore(await SharedPreferences.getInstance());
}

Future<void> _pumpApp(WidgetTester tester, TrackerStore store) async {
  await tester.pumpWidget(McuTrackerApp(store: store));
  await tester.pumpAndSettle();
}

/// The list is lazy, so anything past the first screen has to be scrolled to
/// before it exists in the tree at all.
Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('data', () {
    test('holds all 47 entries in release order', () {
      expect(entries.length, 47);
      expect(entries.map((Entry e) => e.n).toList(),
          List<int>.generate(47, (int i) => i + 1));
    });

    test('splits 23 / 24 across the two sagas', () {
      expect(entries.where((Entry e) => e.saga == 1).length, 23);
      expect(entries.where((Entry e) => e.saga == 2).length, 24);
    });

    test('every entry carries both lore fields', () {
      for (final Entry e in entries) {
        expect(e.why.trim(), isNotEmpty, reason: 'entry ${e.n}');
        expect(e.how.trim(), isNotEmpty, reason: 'entry ${e.n}');
        expect(e.year.trim(), isNotEmpty, reason: 'entry ${e.n}');
      }
    });
  });

  group('tracker', () {
    testWidgets('starts empty and points at the first title', (tester) async {
      await _pumpApp(tester, await _freshStore());

      expect(find.text('Iron Man  2008'), findsOneWidget); // watch-next line
      expect(find.text('0/23'), findsOneWidget);

      await _scrollTo(tester, find.text('0/24'));
      expect(find.text('0/24'), findsOneWidget);
    });

    testWidgets('checking a title advances the watch-next line', (tester) async {
      final TrackerStore store = await _freshStore();
      await _pumpApp(tester, store);

      await tester.tap(find.bySemanticsLabel('Mark Iron Man as watched'));
      await tester.pumpAndSettle();

      expect(store.watchedCount, 1);
      expect(store.isWatched(1), isTrue);
      expect(find.text('The Incredible Hulk  2008'), findsOneWidget);
      expect(find.text('1/23'), findsOneWidget);
    });

    testWidgets('watched titles persist across a restart', (tester) async {
      final TrackerStore store = await _freshStore();
      await _pumpApp(tester, store);

      await tester.tap(find.bySemanticsLabel('Mark Iron Man as watched'));
      await tester.pumpAndSettle();

      // Rebuild the store from the same backing store, as a cold launch would.
      final TrackerStore reloaded =
          TrackerStore(await SharedPreferences.getInstance());
      expect(reloaded.isWatched(1), isTrue);
      expect(reloaded.watchedCount, 1);
    });

    testWidgets('tapping a row reveals its lore', (tester) async {
      await _pumpApp(tester, await _freshStore());

      expect(find.text(entries.first.why), findsNothing);

      await tester.tap(find.text('Iron Man'));
      await tester.pumpAndSettle();

      expect(find.text(entries.first.why), findsOneWidget);
      expect(find.text(entries.first.how), findsOneWidget);
    });

    testWidgets('tapping the checkbox never expands the row', (tester) async {
      await _pumpApp(tester, await _freshStore());

      await tester.tap(find.bySemanticsLabel('Mark Iron Man as watched'));
      await tester.pumpAndSettle();

      expect(find.text(entries.first.why), findsNothing);
    });

    testWidgets('reset clears everything once confirmed', (tester) async {
      final TrackerStore store = await _freshStore(<String, Object>{
        'watched': <String>['1', '2', '3'],
      });
      await _pumpApp(tester, store);
      expect(store.watchedCount, 3);

      await tester.tap(find.byIcon(Icons.restart_alt));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
      await tester.pumpAndSettle();

      expect(store.watchedCount, 0);
      expect(find.text('Iron Man  2008'), findsOneWidget);
    });

    testWidgets('reset can be cancelled', (tester) async {
      final TrackerStore store = await _freshStore(<String, Object>{
        'watched': <String>['1', '2', '3'],
      });
      await _pumpApp(tester, store);

      await tester.tap(find.byIcon(Icons.restart_alt));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(store.watchedCount, 3);
    });

    testWidgets('finishing all 47 swaps the watch-next message', (tester) async {
      final TrackerStore store = await _freshStore(<String, Object>{
        'watched': List<String>.generate(47, (int i) => '${i + 1}'),
      });
      await _pumpApp(tester, store);

      expect(find.text('All 47 done — you are ready for Doomsday.'),
          findsOneWidget);
      expect(find.text('23/23'), findsOneWidget);

      await _scrollTo(tester, find.text('24/24'));
      expect(find.text('24/24'), findsOneWidget);
    });

    testWidgets('theme button cycles system, light, dark', (tester) async {
      final TrackerStore store = await _freshStore();
      await _pumpApp(tester, store);

      expect(store.themeMode, ThemeMode.system);
      await tester.tap(find.byIcon(Icons.brightness_auto_outlined));
      await tester.pumpAndSettle();
      expect(store.themeMode, ThemeMode.light);

      await tester.tap(find.byIcon(Icons.light_mode_outlined));
      await tester.pumpAndSettle();
      expect(store.themeMode, ThemeMode.dark);

      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      await tester.pumpAndSettle();
      expect(store.themeMode, ThemeMode.system);
    });
  });
}
