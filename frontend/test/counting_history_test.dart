import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/screens/counting_history_screen.dart';
import 'package:frontend/theme/app_theme.dart';

// ============================================================
// TEST WIDGET WRAPPER
// ============================================================

Widget buildTestWidget() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    home: const Scaffold(body: CountingHistoryScreen()),
  );
}

// ============================================================
// SCREEN SIZE HELPER
// ============================================================

void setScreenSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

// ============================================================
// AUTOMATED TESTS
// ============================================================

void main() {
  // ==========================================================
  // TEST 1 â€” PAGE RENDERING
  // ==========================================================

  testWidgets('Counting History screen displays correctly', (tester) async {
    setScreenSize(tester, const Size(1440, 1000));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Counting history'), findsOneWidget);

    expect(find.text('Counting records'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 2 â€” STATISTIC CARDS
  // ==========================================================

  testWidgets('Displays all three history statistic cards', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Total records'), findsOneWidget);

    expect(find.text('Completed'), findsOneWidget);

    expect(find.text('Failed'), findsOneWidget);

    expect(find.text('\u2014'), findsNWidgets(3));

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 3 â€” SEARCH INPUT
  // ==========================================================

  testWidgets('Search field accepts record ID or PUV type', (tester) async {
    setScreenSize(tester, const Size(1440, 1000));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);

    await tester.ensureVisible(searchField);

    await tester.enterText(searchField, 'Jeepney');

    await tester.pumpAndSettle();

    expect(find.text('Jeepney'), findsOneWidget);

    expect(find.byTooltip('Clear search'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 4 â€” CLEAR SEARCH
  // ==========================================================

  testWidgets('Clear search button removes entered text', (tester) async {
    setScreenSize(tester, const Size(1440, 1000));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);

    await tester.ensureVisible(searchField);

    await tester.enterText(searchField, 'Record 001');

    await tester.pumpAndSettle();

    final clearButton = find.byTooltip('Clear search');

    await tester.ensureVisible(clearButton);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(searchField);

    expect(textField.controller!.text, isEmpty);

    expect(find.byTooltip('Clear search'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 5 â€” DEFAULT PROCESSING STATUS
  // ==========================================================

  testWidgets('Processing status defaults to All statuses', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );

    expect(dropdown.value, 'All statuses');

    final availableStatuses = dropdown.items!
        .map((item) => item.value)
        .toList();

    expect(availableStatuses, [
      'All statuses',
      'Pending',
      'Processing',
      'Completed',
      'Failed',
    ]);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 6 â€” STATUS SELECTION
  // ==========================================================

  testWidgets('Processing status can be changed', (tester) async {
    setScreenSize(tester, const Size(1440, 1000));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final dropdownFinder = find.byType(DropdownButton<String>);

    await tester.ensureVisible(dropdownFinder);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    final pendingOption = find.text('Pending').last;

    await tester.tap(pendingOption);
    await tester.pumpAndSettle();

    final dropdown = tester.widget<DropdownButton<String>>(dropdownFinder);

    expect(dropdown.value, 'Pending');

    expect(find.textContaining('Filters selected.'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 7 â€” DATE RANGE PICKER
  // ==========================================================

  testWidgets('Date range picker opens and can be dismissed', (tester) async {
    setScreenSize(tester, const Size(1440, 1000));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final dateFilter = find.text('Select date range');

    await tester.ensureVisible(dateFilter);
    await tester.tap(dateFilter);
    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsOneWidget);

    expect(tester.takeException(), isNull);

    final dialogContext = tester.element(find.byType(DateRangePickerDialog));

    Navigator.of(dialogContext).pop();

    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsNothing);

    expect(find.text('Select date range'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 8 â€” ACTIVE FILTERS INDICATOR
  // ==========================================================

  testWidgets('Active filters notice appears after entering search', (
    tester,
  ) async {
    setScreenSize(tester, const Size(1440, 1000));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining('Filters selected.'), findsNothing);

    final searchField = find.byType(TextField);

    await tester.ensureVisible(searchField);

    await tester.enterText(searchField, 'Bus');

    await tester.pumpAndSettle();

    expect(find.textContaining('Filters selected.'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 9 â€” RESET FILTERS
  // ==========================================================

  testWidgets('Reset filters restores default filter values', (tester) async {
    setScreenSize(tester, const Size(1440, 1000));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);

    await tester.ensureVisible(searchField);

    await tester.enterText(searchField, 'Van');

    await tester.pumpAndSettle();

    final dropdownFinder = find.byType(DropdownButton<String>);

    await tester.ensureVisible(dropdownFinder);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Processing').last);

    await tester.pumpAndSettle();

    final resetButton = find.text('Reset filters');

    await tester.ensureVisible(resetButton);
    await tester.tap(resetButton);
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(searchField);

    final dropdown = tester.widget<DropdownButton<String>>(dropdownFinder);

    expect(textField.controller!.text, isEmpty);

    expect(dropdown.value, 'All statuses');

    expect(find.text('Select date range'), findsOneWidget);

    expect(find.textContaining('Filters selected.'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 10 â€” BACKEND UNAVAILABLE AND PAGINATION
  // ==========================================================

  testWidgets('Displays unavailable state and disables pagination', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Counting records unavailable'), findsOneWidget);

    expect(find.text('Awaiting backend connection'), findsOneWidget);

    expect(find.text('Record data unavailable'), findsOneWidget);

    final previousButton = tester.widget<IconButton>(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Previous page',
      ),
    );

    final nextButton = tester.widget<IconButton>(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Next page',
      ),
    );

    expect(previousButton.onPressed, isNull);

    expect(nextButton.onPressed, isNull);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 11 â€” MOBILE RESPONSIVE LAYOUT
  // ==========================================================

  testWidgets('Counting History fits mobile screen without overflow', (
    tester,
  ) async {
    setScreenSize(tester, const Size(393, 852));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Counting history'), findsOneWidget);

    expect(find.text('Total records'), findsOneWidget);

    expect(find.text('Completed'), findsOneWidget);

    expect(find.text('Failed'), findsOneWidget);

    final horizontalScrollViews = find.byWidgetPredicate(
      (widget) =>
          widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal,
    );

    expect(horizontalScrollViews, findsWidgets);

    await tester.ensureVisible(find.text('Counting records unavailable'));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 12 â€” DESKTOP RESPONSIVE LAYOUT
  // ==========================================================

  testWidgets('Counting History fits desktop without overflow', (tester) async {
    setScreenSize(tester, const Size(1440, 900));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Counting history'), findsOneWidget);

    expect(find.text('Record ID'), findsOneWidget);

    expect(find.text('PUV type'), findsOneWidget);

    expect(find.text('Passengers'), findsOneWidget);

    expect(find.text('Threshold'), findsOneWidget);

    expect(find.text('Status'), findsOneWidget);

    expect(find.text('Processed date'), findsOneWidget);

    expect(find.text('Actions'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
