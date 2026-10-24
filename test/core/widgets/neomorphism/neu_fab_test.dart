import 'package:carepaw/app/theme/app_theme.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NeuFAB.extended', () {
    testWidgets('hugs its label instead of spanning the screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: const SizedBox.shrink(),
            floatingActionButton: NeuFAB.extended(
              extendedText: 'Edit',
              icon: Icons.edit_rounded,
              onPressed: () {},
            ),
          ),
        ),
      );

      final fabWidth = tester.getSize(find.byType(NeuFAB)).width;
      final screenWidth = tester.view.physicalSize.width /
          tester.view.devicePixelRatio;
      expect(find.text('Edit'), findsOneWidget);
      expect(fabWidth, lessThan(screenWidth / 2));
    });
  });
}
