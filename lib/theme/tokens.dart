import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RColors {
  // ── Base surfaces ────────────────────────────────────────────────────────────
  static const bg        = Color(0xFF07070B);
  static const bgCard    = Color(0xFF0E0E14);
  static const bgRaised  = Color(0xFF14141C);
  static const bgSurface = Color(0xFF1C1C26);

  // ── Brand ────────────────────────────────────────────────────────────────────
  // Shifted from cold blue → warmer electric violet-blue (more cinematic)
  static const brand     = Color(0xFF2196F3);   // electric blue
  static const brand2    = Color(0xFF64B5F6);   // sky blue
  static const brandDeep = Color(0xFF0D47A1);   // deep navy blue

  // ── Accent / semantic ────────────────────────────────────────────────────────
  static const like      = Color(0xFFFF4F7B);   // vivid rose
  static const gold      = Color(0xFFFFBB38);   // premium gold
  static const teal      = Color(0xFF00D9B8);   // fresh teal accent

  // ── Glass system (richer depth layers) ──────────────────────────────────────
  static const glass         = Color(0x0CFFFFFF);
  static const glassSm       = Color(0x08FFFFFF);
  static const glassMd       = Color(0x18FFFFFF);
  static const glassHeavy    = Color(0x2AFFFFFF);
  static const glassBorder   = Color(0x10FFFFFF);
  static const glassBorderMd = Color(0x20FFFFFF);
  static const glassBorderHv = Color(0x35FFFFFF);

  // ── Text ─────────────────────────────────────────────────────────────────────
  static const text  = Color(0xFFF5F5FF);   // slightly cool white
  static const text2 = Color(0xAAF5F5FF);
  static const text3 = Color(0x55F5F5FF);
  static const text4 = Color(0x28F5F5FF);

  // ── Overlays ─────────────────────────────────────────────────────────────────
  static const overlayBottom = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Color(0xFF07070B),
      Color(0xCC07070B),
      Color(0x6607070B),
      Color(0x1107070B),
      Colors.transparent,
    ],
    stops: [0.0, 0.22, 0.48, 0.70, 1.0],
  );
  static const overlayTop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xBB07070B), Color(0x4407070B), Colors.transparent],
    stops: [0.0, 0.5, 1.0],
  );
  static const brandGrad = LinearGradient(
    colors: [brand, brand2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const brandGradHoriz = LinearGradient(
    colors: [brandDeep, brand, brand2],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const cinemaGrad = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF64B5F6), Color(0xFF00D9B8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class RText {
  /// Display / wordmark — sharp, editorial feel
  static TextStyle wordmark({double size = 22}) => GoogleFonts.syne(
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: RColors.text,
    letterSpacing: -0.8,
  );

  /// Body copy
  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = RColors.text,
    double height = 1.45,
    double letterSpacing = 0.0,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// Small caps label
  static TextStyle label({
    double size = 11,
    Color color = RColors.text2,
    double letterSpacing = 0.4,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: letterSpacing,
  );

  /// Numeric / monospaced feel for counters/time
  static TextStyle mono({
    double size = 13,
    Color color = RColors.text,
    FontWeight weight = FontWeight.w500,
  }) => GoogleFonts.spaceGrotesk(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: -0.2,
  );
}

class RDur {
  static const xs  = Duration(milliseconds: 80);
  static const sm  = Duration(milliseconds: 180);
  static const md  = Duration(milliseconds: 300);
  static const lg  = Duration(milliseconds: 460);
  static const xl  = Duration(milliseconds: 620);
}

class RCurve {
  static const easeOut = Cubic(0.16, 1, 0.3, 1);
  static const spring  = Cubic(0.34, 1.25, 0.64, 1);
  static const ios     = Cubic(0.25, 0.46, 0.45, 0.94);
  static const snap    = Cubic(0.22, 1.0, 0.36, 1.0);
}

/// Shared decoration helpers
class RDeco {
  static BoxDecoration glassCard({
    BorderRadius? radius,
    Color? borderColor,
    List<BoxShadow>? shadows,
  }) => BoxDecoration(
    color: RColors.glass,
    borderRadius: radius ?? BorderRadius.circular(20),
    border: Border.all(color: borderColor ?? RColors.glassBorder),
    boxShadow: shadows,
  );

  static BoxDecoration brandCard({BorderRadius? radius}) => BoxDecoration(
    gradient: const LinearGradient(
      colors: [RColors.brand, RColors.brand2],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: radius ?? BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(color: RColors.brand.withOpacity(0.45), blurRadius: 24, spreadRadius: 0, offset: const Offset(0, 6)),
    ],
  );

  static BoxDecoration pill({Color? color, Color? borderColor}) => BoxDecoration(
    color: color ?? RColors.glassMd,
    borderRadius: BorderRadius.circular(100),
    border: Border.all(color: borderColor ?? RColors.glassBorderMd),
  );
}
