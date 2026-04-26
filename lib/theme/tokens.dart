import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RColors {
  static const bg        = Color(0xFF050508);
  static const bgCard    = Color(0xFF0C0C10);
  static const bgRaised  = Color(0xFF111116);
  static const bgSurface = Color(0xFF18181E);
  static const brand     = Color(0xFF0090FF);
  static const brand2    = Color(0xFF00D4FF);
  static const like      = Color(0xFFFF3B5C);

  static const glass        = Color(0x0EFFFFFF);
  static const glassMd      = Color(0x17FFFFFF);
  static const glassHeavy   = Color(0x24FFFFFF);
  static const glassBorder  = Color(0x13FFFFFF);
  static const glassBorderMd = Color(0x22FFFFFF);

  static const text  = Color(0xFFF2F2F5);
  static const text2 = Color(0xB3F2F2F5);
  static const text3 = Color(0x66F2F2F5);
  static const text4 = Color(0x33F2F2F5);

  static const overlayBottom = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xF5050508), Color(0xAA050508), Color(0x44050508), Colors.transparent],
    stops: [0.0, 0.3, 0.6, 1.0],
  );
  static const overlayTop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xCC050508), Colors.transparent],
  );
  static const brandGrad = LinearGradient(
    colors: [brand, brand2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class RText {
  static TextStyle wordmark({double size = 22}) => GoogleFonts.spaceGrotesk(
    fontSize: size, fontWeight: FontWeight.w700,
    color: RColors.text, letterSpacing: -0.5,
  );
  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = RColors.text,
    double height = 1.4,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: size, fontWeight: weight, color: color, height: height,
  );
  static TextStyle label({double size = 11, Color color = RColors.text2}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size, fontWeight: FontWeight.w600,
        color: color, letterSpacing: 0.2,
      );
}

class RDur {
  static const xs = Duration(milliseconds: 80);
  static const sm = Duration(milliseconds: 160);
  static const md = Duration(milliseconds: 280);
  static const lg = Duration(milliseconds: 420);
}

class RCurve {
  static const easeOut = Cubic(0.16, 1, 0.3, 1);
  static const spring  = Cubic(0.34, 1.3, 0.64, 1);
  static const ios     = Cubic(0.25, 0.46, 0.45, 0.94);
}
