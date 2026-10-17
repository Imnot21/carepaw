import 'package:carepaw/app/theme/app_theme.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_stat.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('NeuStatTile', () {
    testWidgets('renders the value and the label', (tester) async {
      await tester.pumpWidget(
        _host(
          const NeuStatTile(
            label: 'Low stock',
            value: '3',
            icon: Icons.inventory_2_outlined,
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Low stock'), findsOneWidget);
    });

    testWidgets('renders the clay SVG asset in place of the Material icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const NeuStatTile(
            label: 'Low stock',
            value: '3',
            icon: Icons.inventory_2_outlined,
            svgAsset: SvgIcons.inventory,
          ),
        ),
      );

      expect(find.byType(NeuSvgIcon), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsNothing);
    });

    testWidgets('falls back to the Material icon when no asset is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const NeuStatTile(
            label: 'Low stock',
            value: '3',
            icon: Icons.inventory_2_outlined,
          ),
        ),
      );

      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      expect(find.byType(NeuSvgIcon), findsNothing);
    });

    testWidgets('renders the dash used for unknown values', (tester) async {
      await tester.pumpWidget(
        _host(
          const NeuStatTile(
            label: 'Waiting',
            value: '-',
            icon: Icons.groups_outlined,
          ),
        ),
      );

      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('reports taps when onTap is provided', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          NeuStatTile(
            label: 'Low stock',
            value: '3',
            icon: Icons.inventory_2_outlined,
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('3'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(taps, 1);
    });
  });
}
