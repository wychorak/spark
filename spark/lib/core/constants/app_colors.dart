import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Primary (soft cherry blossom pink) ──
  static const Color primary = Color(0xFFFF6B9D);
  static const Color primaryDark = Color(0xFFE8507E);
  static const Color primaryLight = Color(0xFFFFB3CC);

  // ── Background / Surface (light cream / blush) ──
  static const Color background = Color(0xFFFFF5F7);
  static const Color surface = Color(0xFFFFF0F3);
  static const Color surfaceLight = Color(0xFFFFE8ED);
  static const Color card = Color(0xFFFFF8FA);
  static const Color cardLight = Color(0xFFFFF0F5);

  // ── Text ──
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B6B80);
  static const Color textHint = Color(0xFFA0A0B0);
  static const Color textDisabled = Color(0xFFC8C8D0);

  // ── Mode Colors ──
  static const Color modeRelationship = Color(0xFFFF6B9D);
  static const Color modeFriends = Color(0xFF5CD68A);
  static const Color modeFWB = Color(0xFFFF9F43);

  // ── Accent Glow (soft) ──
  static const Color neonPink = Color(0xFFFF6B9D);
  static const Color neonPinkGlow = Color(0x40FF6B9D);
  static const Color neonGreen = Color(0xFF5CD68A);
  static const Color neonGreenGlow = Color(0x405CD68A);
  static const Color neonOrange = Color(0xFFFF9F43);
  static const Color neonOrangeGlow = Color(0x40FF9F43);
  static const Color neonBlue = Color(0xFF74B9FF);
  static const Color neonBlueGlow = Color(0x4074B9FF);
  static const Color neonPurple = Color(0xFFA29BFE);
  static const Color neonPurpleGlow = Color(0x40A29BFE);

  // ── Status ──
  static const Color success = Color(0xFF5CD68A);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFD93D);
  static const Color info = Color(0xFF74B9FF);

  // ── Misc ──
  static const Color divider = Color(0xFFF0E0E8);
  static const Color shimmerBase = Color(0xFFFFF0F5);
  static const Color shimmerHighlight = Color(0xFFFFE0EB);
  static const Color overlay = Color(0xCCFFFFFF);
  static const Color scrim = Color(0x99FFFFFF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFF9F43)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonPinkGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFA29BFE)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient neonGreenGradient = LinearGradient(
    colors: [Color(0xFF5CD68A), Color(0xFF74B9FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient neonOrangeGradient = LinearGradient(
    colors: [Color(0xFFFF9F43), Color(0xFFFF6B9D)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFFFFF8FA), Color(0xFFFFF0F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFF5F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Gradient helpers per mode ──
  static LinearGradient gradientForMode(String mode) {
    switch (mode) {
      case 'friends':
        return neonGreenGradient;
      case 'fwb':
        return neonOrangeGradient;
      case 'relationship':
      default:
        return neonPinkGradient;
    }
  }

  static Color colorForMode(String mode) {
    switch (mode) {
      case 'friends':
        return modeFriends;
      case 'fwb':
        return modeFWB;
      case 'relationship':
      default:
        return modeRelationship;
    }
  }

  static Color glowForMode(String mode) {
    switch (mode) {
      case 'friends':
        return neonGreenGlow;
      case 'fwb':
        return neonOrangeGlow;
      case 'relationship':
      default:
        return neonPinkGlow;
    }
  }
}
