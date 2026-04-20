import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReelzColors {
  // Brand
  static const brand = Color(0xFF0090FF);
  static const brand2 = Color(0xFF00D4FF);
  static const brandDark = Color(0xFF0066CC);
  static const brandGlow = Color(0x290090FF);
  static const brandGlowMd = Color(0x520090FF);

  // Like — keep red for emotion
  static const like = Color(0xFFFF3B5C);
  static const likeGlow = Color(0x29FF3B5C);

  // Backgrounds
  static const bg = Color(0xFF050508);
  static const bgCard = Color(0xFF0C0C10);
  static const bgRaised = Color(0xFF111116);
  static const bgSurface = Color(0xFF18181E);

  // Glass
  static const glass = Color(0x0EFFFFFF);
  static const glassMd = Color(0x17FFFFFF);
  static const glassHeavy = Color(0x24FFFFFF);
  static const glassBorder = Color(0x13FFFFFF);
  static const glassBorderMd = Color(0x1FFFFFFF);

  // Text
  static const text = Color(0xFFF2F2F5);
  static const text2 = Color(0xB3F2F2F5);
  static const text3 = Color(0x66F2F2F5);
  static const text4 = Color(0x3DF2F2F5);

  // Accents
  static const accentGreen = Color(0xFF22D47A);
  static const accentBlue = Color(0xFF4A9EFF);

  // Gradients
  static const brandGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand, brand2],
  );

  static const overlayBottom = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Color(0xF0050508),
      Color(0x99050508),
      Color(0x33050508),
      Colors.transparent,
    ],
    stops: [0.0, 0.35, 0.65, 1.0],
  );

  static const overlayTop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xBB050508), Colors.transparent],
  );
}

class ReelzTextStyles {
  static TextStyle wordmark({double size = 22}) => GoogleFonts.spaceGrotesk(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: ReelzColors.text,
    letterSpacing: -0.5,
  );

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = ReelzColors.text,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  static TextStyle caption = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ReelzColors.text,
    height: 1.4,
  );

  static TextStyle hashtag = GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: ReelzColors.brand,
  );

  static TextStyle navLabel = GoogleFonts.plusJakartaSans(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static TextStyle actionCount = GoogleFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: ReelzColors.text,
  );
}

class ReelzDurations {
  static const xs = Duration(milliseconds: 70);
  static const sm = Duration(milliseconds: 140);
  static const md = Duration(milliseconds: 260);
  static const lg = Duration(milliseconds: 400);
  static const xl = Duration(milliseconds: 580);
}

class ReelzCurves {
  static const easeOut = Cubic(0.16, 1, 0.3, 1);
  static const spring = Cubic(0.34, 1.3, 0.64, 1);
  static const bounce = Cubic(0.34, 1.56, 0.64, 1);
  static const ios = Cubic(0.25, 0.46, 0.45, 0.94);
}
