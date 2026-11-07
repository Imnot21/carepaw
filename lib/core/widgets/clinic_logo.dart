import 'package:flutter/material.dart';

import '../../app/theme/design_tokens.dart';

/// The DocMyk's PILA VET HUB logo on a white plate.
///
/// The logo's indigo strokes fall to 1.6:1 on the dark canvas, so the plate
/// stays white in both modes: in light mode it reads as a raised card, in
/// dark mode as a deliberate badge rather than a white hole.
class ClinicLogo extends StatelessWidget {
  static const String asset = 'assets/images/pilavethub_logo.png';

  final double size;

  const ClinicLogo({super.key, this.size = 112});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "DocMyk's PILA VET HUB logo",
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.08),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(NeuTokens.radiusLg),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F15172B),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
