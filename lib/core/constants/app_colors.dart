import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Primary ──
  static const Color primary = Color(0xFFFF1493);
  static const Color primaryDark = Color(0xFFCC1076);
  static const Color primaryLight = Color(0xFFFF5CB8);

  // ── Background / Surface ──
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0D0D0D);
  static const Color surfaceLight = Color(0xFF1A1A1A);
  static const Color card = Color(0xFF141414);
  static const Color cardLight = Color(0xFF1E1E1E);

  // ── Text ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF666666);
  static const Color textDisabled = Color(0xFF444444);

  // ── Mode Colors ──
  static const Color modeRelationship = Color(0xFFFF1493); // pink
  static const Color modeFriends = Color(0xFF39FF14); // neon green
  static const Color modeFWB = Color(0xFFFF6D00); // orange

  // ── Neon Glow ──
  static const Color neonPink = Color(0xFFFF1493);
  static const Color neonPinkGlow = Color(0x66FF1493);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonGreenGlow = Color(0x6639FF14);
  static const Color neonOrange = Color(0xFFFF6D00);
  static const Color neonOrangeGlow = Color(0x66FF6D00);
  static const Color neonBlue = Color(0xFF00BFFF);
  static const Color neonBlueGlow = Color(0x6600BFFF);
  static const Color neonPurple = Color(0xFFBF00FF);
  static const Color neonPurpleGlow = Color(0x66BF00FF);

  // ── Status ──
  static const Color success = Color(0xFF39FF14);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFD600);
  static const Color info = Color(0xFF00BFFF);

  // ── Misc ──
  static const Color divider = Color(0xFF2A2A2A);
  static const Color shimmerBase = Color(0xFF1A1A1A);
  static const Color shimmerHighlight = Color(0xFF2A2A2A);
  static const Color overlay = Color(0xCC000000);
  static const Color scrim = Color(0x99000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF1493), Color(0xFFFF6D00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonPinkGradient = LinearGradient(
    colors: [Color(0xFFFF1493), Color(0xFFBF00FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient neonGreenGradient = LinearGradient(
    colors: [Color(0xFF39FF14), Color(0xFF00BFFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient neonOrangeGradient = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFFF1493)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0D0D0D), Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
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
