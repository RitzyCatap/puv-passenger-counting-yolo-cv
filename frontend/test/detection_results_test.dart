import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/widgets/detection_results.dart';

// ============================================================
// CREATE CONTROLLED TEST IMAGE
// ============================================================

Future<Uint8List> createTestImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  final backgroundPaint = ui.Paint()..color = const ui.Color(0xFFE5EDE0);

  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 640, 480), backgroundPaint);

  final personPaint = ui.Paint()..color = const ui.Color(0xFF123D36);

  canvas.drawRect(const ui.Rect.fromLTWH(50, 60, 150, 300), personPaint);

  canvas.drawRect(const ui.Rect.fromLTWH(250, 80, 140, 280), personPaint);

  canvas.drawRect(const ui.Rect.fromLTWH(430, 70, 130, 290), personPaint);

  final picture = recorder.endRecording();

  final image = await picture.toImage(640, 480);

  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  image.dispose();
  picture.dispose();

  return byteData!.buffer.asUint8List(
    byteData.offsetInBytes,
    byteData.lengthInBytes,
  );
}

// ============================================================
// TEST WIDGET WRAPPER
// ============================================================

Widget buildTestWidget({
  required DetectionStatus status,
  PassengerDetectionResult? result,
  String? errorMessage,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: DetectionResults(
          status: status,
          result: result,
          errorMessage: errorMessage,
        ),
      ),
    ),
  );
}

// ============================================================
// AUTOMATED TESTS
// ============================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List testImage;

  setUpAll(() async {
    testImage = await createTestImage();
  });

  // ==========================================================
  // CONTROLLED DETECTION DATA
  // ==========================================================

  PassengerDetectionResult createSampleResult() {
    return PassengerDetectionResult(
      imageBytes: testImage,
      imageWidth: 640,
      imageHeight: 480,
      confidenceThreshold: 0.50,
      detections: const [
        DetectedPerson(confidence: 0.90, x1: 50, y1: 60, x2: 200, y2: 360),
        DetectedPerson(confidence: 0.80, x1: 250, y1: 80, x2: 390, y2: 360),
        DetectedPerson(confidence: 0.70, x1: 430, y1: 70, x2: 560, y2: 360),
      ],
    );
  }

  // ==========================================================
  // TEST 1 — PASSENGER COUNT
  // ==========================================================

  test('Passenger count matches detection list', () {
    final result = createSampleResult();

    expect(result.passengerCount, 3);
  });

  // ==========================================================
  // TEST 2 — AVERAGE CONFIDENCE
  // ==========================================================

  test('Average confidence is calculated correctly', () {
    final result = createSampleResult();

    expect(result.averageConfidence, closeTo(0.80, 0.0001));
  });

  // ==========================================================
  // TEST 3 — ZERO DETECTIONS
  // ==========================================================

  test('Zero detections return zero count and null average', () {
    final result = PassengerDetectionResult(
      imageBytes: testImage,
      imageWidth: 640,
      imageHeight: 480,
      confidenceThreshold: 0.50,
      detections: const [],
    );

    expect(result.passengerCount, 0);
    expect(result.averageConfidence, isNull);
  });

  // ==========================================================
  // TEST 4 — EMPTY STATE
  // ==========================================================

  testWidgets('Displays the initial empty state', (tester) async {
    await tester.pumpWidget(buildTestWidget(status: DetectionStatus.idle));

    expect(find.text('Awaiting image'), findsOneWidget);

    expect(find.text('No detection results yet'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 5 — PROCESSING STATE
  // ==========================================================

  testWidgets('Displays the processing state', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(status: DetectionStatus.processing),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Processing'), findsOneWidget);

    expect(find.text('Processing image...'), findsOneWidget);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 6 — FAILED STATE
  // ==========================================================

  testWidgets('Displays the failed state and error message', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        status: DetectionStatus.failed,
        errorMessage: 'Test backend connection failed.',
      ),
    );

    expect(find.text('Failed'), findsOneWidget);

    expect(find.text('Unable to process image'), findsOneWidget);

    expect(find.text('Test backend connection failed.'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 7 — COMPLETED STATE
  // ==========================================================

  testWidgets('Displays completed detection results', (tester) async {
    final result = createSampleResult();

    await tester.pumpWidget(
      buildTestWidget(status: DetectionStatus.completed, result: result),
    );

    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsWidgets);

    expect(find.text('Passenger count'), findsOneWidget);

    expect(find.text('3'), findsOneWidget);

    expect(find.text('50%'), findsOneWidget);

    expect(find.text('Detected persons (3)'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 8 — BOUNDING BOX PAINTER
  // ==========================================================

  testWidgets('Creates the image and bounding box overlay', (tester) async {
    final result = createSampleResult();

    await tester.pumpWidget(
      buildTestWidget(status: DetectionStatus.completed, result: result),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);

    final boundingBoxOverlay = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter.runtimeType.toString() == '_BoundingBoxPainter',
    );

    expect(boundingBoxOverlay, findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 9 — ZERO PASSENGERS COMPLETED STATE
  // ==========================================================

  testWidgets('Displays a completed result with zero passengers', (
    tester,
  ) async {
    final result = PassengerDetectionResult(
      imageBytes: testImage,
      imageWidth: 640,
      imageHeight: 480,
      confidenceThreshold: 0.50,
      detections: const [],
    );

    await tester.pumpWidget(
      buildTestWidget(status: DetectionStatus.completed, result: result),
    );

    await tester.pumpAndSettle();

    expect(find.text('0'), findsOneWidget);

    expect(find.text('N/A'), findsOneWidget);

    expect(find.text('No persons detected'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 10 — MISSING COMPLETED RESULT
  // ==========================================================

  testWidgets('Handles unavailable completed detection data', (tester) async {
    await tester.pumpWidget(buildTestWidget(status: DetectionStatus.completed));

    expect(find.text('Detection data unavailable'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 11 — MOBILE RESPONSIVE LAYOUT
  // ==========================================================

  testWidgets('Completed results fit mobile screen without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final result = createSampleResult();

    await tester.pumpWidget(
      buildTestWidget(status: DetectionStatus.completed, result: result),
    );

    await tester.pumpAndSettle();

    expect(find.text('Passenger count'), findsOneWidget);

    expect(find.text('3'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  // ==========================================================
  // TEST 12 — DESKTOP RESPONSIVE LAYOUT
  // ==========================================================

  testWidgets('Completed results fit desktop without overflow', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final result = createSampleResult();

    await tester.pumpWidget(
      buildTestWidget(status: DetectionStatus.completed, result: result),
    );

    await tester.pumpAndSettle();

    expect(find.text('Passenger count'), findsOneWidget);

    expect(find.text('Detected persons (3)'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
