import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/screens/reports_screen.dart';
import 'package:frontend/theme/app_theme.dart';

// ============================================================
// TEST WIDGET WRAPPER
// ============================================================

Widget buildTestWidget() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    home: const Scaffold(body: ReportsScreen()),
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
// DATE FORMATTER
// ============================================================

String formatTestDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$month/$day/${date.year}';
}

// ============================================================
// DATE RANGE TEST HELPER
// ============================================================

Future<DateTimeRange> selectTestDateRange(WidgetTester tester) async {
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);

  final startDate = DateTime(today.year, today.month, today.day - 7);

  final range = DateTimeRange(start: startDate, end: today);

  final dateSelector = find.text('All dates');

  await tester.ensureVisible(dateSelector);
  await tester.tap(dateSelector);
  await tester.pumpAndSettle();

  final dialogFinder = find.byType(DateRangePickerDialog);

  expect(dialogFinder, findsOneWidget);

  final dialogContext = tester.element(dialogFinder);

  // Simulates a confirmed result from the date picker.
  Navigator.of(dialogContext).pop(range);

  await tester.pumpAndSettle();

  return range;
}

// ============================================================
// RESET BUTTON FINDER
// ============================================================

Finder findResetButton() {
  return find.ancestor(
    of: find.text('Reset period'),
    matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
  );
}

// ============================================================
// AUTOMATED TESTS
// ============================================================

void main() {
  // ==========================================================
  // TEST 1 - PAGE RENDERING
  // ==========================================================

  testWidgets('Reports and Summary page displays correctly', (tester) async {
    setScreenSize(tester, const Size(1440, 1000));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Reports and summary'), findsOneWidget);

    expect(find.text('Report period'), findsOneWidget);

    expect(find.text('Passenger counting analytics'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 2 - SUMMARY STATISTIC CARDS
  // ==========================================================

  testWidgets('Displays all four summary statistic cards', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Total passengers'), findsOneWidget);

    expect(find.text('Counting records'), findsWidgets);

    expect(find.text('Average passengers'), findsOneWidget);

    expect(find.text('Completed counts'), findsOneWidget);

    expect(find.text('Across completed counts'), findsOneWidget);

    expect(find.text('Per completed count'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 3 - DEFAULT REPORT PERIOD
  // ==========================================================

  testWidgets('Report period defaults to All dates', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('All dates'), findsOneWidget);

    expect(find.textContaining('Report period selected.'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 4 - DISABLED RESET BUTTON
  // ==========================================================

  testWidgets('Reset period button is initially disabled', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final resetFinder = findResetButton();

    expect(resetFinder, findsOneWidget);

    final resetButton = tester.widget<OutlinedButton>(resetFinder);

    expect(resetButton.onPressed, isNull);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 5 - DATE RANGE PICKER
  // ==========================================================

  testWidgets('Date range picker opens and can be dismissed', (tester) async {
    setScreenSize(tester, const Size(1440, 1000));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final dateSelector = find.text('All dates');

    await tester.ensureVisible(dateSelector);
    await tester.tap(dateSelector);
    await tester.pumpAndSettle();

    final dialogFinder = find.byType(DateRangePickerDialog);

    expect(dialogFinder, findsOneWidget);

    expect(tester.takeException(), isNull);

    final dialogContext = tester.element(dialogFinder);

    Navigator.of(dialogContext).pop();

    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsNothing);

    expect(find.text('All dates'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 6 - DATE RANGE SELECTION
  // ==========================================================

  testWidgets('Selected report period is displayed correctly', (tester) async {
    setScreenSize(tester, const Size(1440, 1000));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final selectedRange = await selectTestDateRange(tester);

    final expectedLabel =
        '${formatTestDate(selectedRange.start)} - '
        '${formatTestDate(selectedRange.end)}';

    expect(find.text(expectedLabel), findsOneWidget);

    expect(find.text('All dates'), findsNothing);

    expect(find.textContaining('Report period selected.'), findsOneWidget);

    final resetButton = tester.widget<OutlinedButton>(findResetButton());

    expect(resetButton.onPressed, isNotNull);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 7 - RESET REPORT PERIOD
  // ==========================================================

  testWidgets('Reset period restores All dates', (tester) async {
    setScreenSize(tester, const Size(1440, 1000));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await selectTestDateRange(tester);

    expect(find.textContaining('Report period selected.'), findsOneWidget);

    final resetFinder = findResetButton();

    await tester.ensureVisible(resetFinder);
    await tester.tap(resetFinder);
    await tester.pumpAndSettle();

    expect(find.text('All dates'), findsOneWidget);

    expect(find.textContaining('Report period selected.'), findsNothing);

    final resetButton = tester.widget<OutlinedButton>(findResetButton());

    expect(resetButton.onPressed, isNull);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 8 - PASSENGER COUNTING TRENDS
  // ==========================================================

  testWidgets('Passenger counting trends framework displays correctly', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Passenger counting trends'), findsOneWidget);

    expect(find.text('Passengers counted'), findsOneWidget);

    expect(find.text('Chart data unavailable'), findsOneWidget);

    final chartPainter = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter?.runtimeType.toString() == '_EmptyChartPainter',
    );

    expect(chartPainter, findsOneWidget);

    await tester.ensureVisible(chartPainter);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 9 - VEHICLE REPORT SECTION
  // ==========================================================

  testWidgets('Vehicle report section displays correctly', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Passengers by PUV type'), findsOneWidget);

    expect(find.text('Vehicle data unavailable'), findsOneWidget);

    expect(find.text('Vehicle types with records'), findsOneWidget);

    expect(find.text('Records with assigned vehicles'), findsOneWidget);

    expect(find.text('Records without assigned vehicles'), findsOneWidget);

    await tester.ensureVisible(find.text('Vehicle data unavailable'));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 10 - PROCESSING STATUS SUMMARY
  // ==========================================================

  testWidgets('Processing summary displays all four statuses', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Processing summary'), findsOneWidget);

    expect(find.text('Completed'), findsOneWidget);

    expect(find.text('Processing'), findsOneWidget);

    expect(find.text('Pending'), findsOneWidget);

    expect(find.text('Failed'), findsOneWidget);

    expect(find.text('Processing data unavailable'), findsOneWidget);

    await tester.ensureVisible(find.text('Processing summary'));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 11 - PROCESSING PERFORMANCE CARDS
  // ==========================================================

  testWidgets('Displays all four processing performance cards', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Processing performance'), findsOneWidget);

    expect(find.text('Completion rate'), findsOneWidget);

    expect(find.text('Failed processing rate'), findsOneWidget);

    expect(find.text('Average confidence threshold'), findsOneWidget);

    expect(find.text('Average detection confidence'), findsOneWidget);

    await tester.ensureVisible(find.text('Average detection confidence'));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 12 - BACKEND UNAVAILABLE STATES
  // ==========================================================

  testWidgets('Displays backend unavailable states without fake data', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Chart data unavailable'), findsOneWidget);

    expect(find.text('Awaiting backend connection'), findsOneWidget);

    expect(find.text('Vehicle data unavailable'), findsOneWidget);

    expect(find.text('Processing data unavailable'), findsOneWidget);

    expect(
      find.textContaining('Report statistics are currently unavailable.'),
      findsOneWidget,
    );

    // Four summary values, three vehicle values,
    // four processing statuses, and four performance values.
    expect(find.text('\u2014'), findsNWidgets(15));

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 13 - MOBILE RESPONSIVE LAYOUT
  // ==========================================================

  testWidgets('Reports screen fits mobile without overflow', (tester) async {
    setScreenSize(tester, const Size(393, 852));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Reports and summary'), findsOneWidget);

    expect(find.text('Total passengers'), findsOneWidget);

    expect(find.text('Average passengers'), findsOneWidget);

    await tester.ensureVisible(find.text('Passenger counting trends'));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Passengers by PUV type'));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Processing summary'));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Average detection confidence'));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 14 - DESKTOP RESPONSIVE LAYOUT
  // ==========================================================

  testWidgets('Reports screen fits desktop without overflow', (tester) async {
    setScreenSize(tester, const Size(1440, 900));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Reports and summary'), findsOneWidget);

    expect(find.text('Report period'), findsOneWidget);

    expect(find.text('Total passengers'), findsOneWidget);

    expect(find.text('Passenger counting trends'), findsOneWidget);

    expect(find.text('Passengers by PUV type'), findsOneWidget);

    expect(find.text('Processing summary'), findsOneWidget);

    expect(find.text('Processing performance'), findsOneWidget);

    await tester.ensureVisible(find.text('Processing performance'));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
