import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carepaw/core/utils/input_formatters.dart';
import 'package:carepaw/core/utils/validators.dart';

/// Types [text] into a field that currently holds [current].
String type(TextInputFormatter formatter, String current, String text) {
  return formatter
      .formatEditUpdate(
        TextEditingValue(text: current),
        TextEditingValue(text: text),
      )
      .text;
}

void main() {
  group('DecimalInputFormatter.weightKg', () {
    final f = DecimalInputFormatter.weightKg;

    test('keeps up to 3 digits and 2 decimals', () {
      expect(type(f, '', '25'), '25');
      expect(type(f, '25', '25.5'), '25.5');
      expect(type(f, '999.9', '999.99'), '999.99');
      expect(type(f, '', ''), '');
      expect(type(f, '', '.5'), '.5');
    });

    test('ignores a 4th digit, a 3rd decimal, letters and a 2nd point', () {
      expect(type(f, '100', '1000'), '100');
      expect(type(f, '25.55', '25.555'), '25.55');
      expect(type(f, '25', '25a'), '25');
      expect(type(f, '2.5', '2.5.'), '2.5');
      expect(type(f, '', '100000'), '');
    });
  });

  group('DecimalInputFormatter.stockQuantity', () {
    final f = DecimalInputFormatter.stockQuantity;

    test('keeps up to 5 digits', () {
      expect(type(f, '9999', '99999'), '99999');
      expect(type(f, '99999', '999999'), '99999');
    });
  });

  group('Validators.weight', () {
    test('accepts empty and a normal weight', () {
      expect(Validators.weight(''), isNull);
      expect(Validators.weight('25.5'), isNull);
      expect(Validators.weight('200'), isNull);
    });

    test('rejects zero and anything above the pet limit', () {
      expect(Validators.weight('0'), isNotNull);
      expect(Validators.weight('200.01'), isNotNull);
      expect(Validators.weight('999'), isNotNull);
    });
  });
}
