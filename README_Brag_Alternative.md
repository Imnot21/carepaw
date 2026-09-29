# Alternative Methods for Creating CarePaw Demo Videos

Since the `brag` package from https://github.com/latent-spaces/brag.git doesn't appear to be a publishable Dart package (it lacks a pubspec.yaml), here are alternative approaches to create demonstration videos of your CarePaw app:

## Option 1: Use Device/OS Built-in Screen Recording (Recommended)

### Mobile Devices:
- **Android**: Use built-in screen recorder (Quick Settings → Screen Record) or ADB:
  ```bash
  adb screenrecord /sdcard/carepaw_demo.mp4
  ```
- **iOS**: Use Control Center → Screen Recording or QuickTime on Mac

### Desktop:
- **macOS**: Shift+Command+5 or QuickTime Player
- **Windows**: Xbox Game Bar (Win+G) or OBS Studio
- **Linux**: SimpleScreenRecorder, OBS Studio, or Kazam

### Web Browser:
- Use browser extensions like Loom, Screencastify, or built-in developer tools

## Option 2: Flutter Integration Testing with Video Capture

Create an integration test that exercises your app and captures frames:

### 1. Add dependencies to `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  # Optional: for better image comparison
  flutter_image_comparison: ^0.4.0
```

### 2. Create `integration_test/app_demo_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:carepaw/main.dart' as app;
import 'dart:ui' as ui;
import 'dart:typed_data';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CarePaw Demo', () {
    testWidgets('demo app flow', (WidgetTester tester) async {
      // Build the app
      app.main();
      await tester.pumpAndSettle();

      // Capture initial frame
      await _captureFrame(tester, '01_start');

      // Navigate through app
      await _tapAndWait(tester, find.text('Login'));
      await _captureFrame(tester, '02_login_screen');

      // Enter credentials
      await tester.enterText(
        find.byType(TextField).at(0), 
        'admin@carepaw.app'
      );
      await tester.enterText(
        find.byType(TextField).at(1), 
        'admin123'
      );
      await _captureFrame(tester, '03_credentials_entered');

      // Tap login
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      await _captureFrame(tester, '04_after_login');

      // Navigate to Pets
      await tester.tap(find.text('Pets'));
      await tester.pumpAndSettle();
      await _captureFrame(tester, '05_pets_section');

      // Navigate to Appointments
      await tester.tap(find.text('Appointments'));
      await tester.pumpAndSettle();
      await _captureFrame(tester, '06_appointments');

      // Navigate to Medical Records
      await tester.tap(find.text('Medical Records'));
      await tester.pumpAndSettle();
      await _captureFrame(tester, '07_medical_records');

      // Navigate to Inventory
      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();
      await _captureFrame(tester, '08_inventory');

      // Final frame
      await _captureFrame(tester, '09_end');
    });
  });
}

Future<void> _tapAndWait(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

Future<void> _captureFrame(WidgetTester tester, String name) async {
  final binder = tester.binding as WidgetsFlutterBinding;
  final surface = binder.window;
  
  // Capture frame
  final Uint8List imgBytes = await surface.toImage(
    pixelRatio: devicePixelRatio,
  ).then((img) => img.toByteData(format: ui.ImageByteFormat.png)).then((data) => data!.buffer.asUint8List());
  
  // Save frame (you'd need to implement file saving or collect for video encoding)
  print('Captured frame: $name (${imgBytes.length} bytes)');
  
  // Wait a bit for visual effect
  await tester.pump(const Duration(milliseconds: 500));
}
```

### 3. Run the test:
```bash
flutter drive --target=test_driver/app.dart
```

## Option 3: Use Flutter's DevTools for Recording

Flutter DevTools has built-in recording capabilities:
1. Run your app: `flutter run`
2. Open DevTools: `flutter pub global run devtools`
3. Use the "Timeline" or "Performance" tab to record interactions
4. Export recording data

## Option 4: Create Interactive Demo with Coach Marks

Add this to `pubspec.yaml`:
```yaml
dependencies:
  flutter_tutorial_coach_mark: ^1.2.0
```

Then create an interactive tour that highlights key features.

## Option 5: Simple Video Script with Platform Channels

For more control, you could create a simple script that:
1. Uses platform channels to access native screen recording APIs
2. Or generates a GIF/WebP animation of widget changes

## Recommendation:

For quick, high-quality demos of CarePaw, I recommend **Option 1** (built-in screen recording) because:
- It captures actual device performance and animations
- No additional dependencies needed
- Works exactly as users will experience the app
- Easy to share and distribute

Would you like me to help you set up any of these alternatives, or would you prefer to proceed with the built-in screen recording approach for your CarePaw demonstration videos?