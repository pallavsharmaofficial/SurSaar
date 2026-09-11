import 'package:flutter/material.dart';

/// One colour per finger, used on diagrams, the camera overlay and hints so
/// a beginner can match "blue dot" to "index finger" at a glance.
class FingerColors {
  const FingerColors._();

  static const Color index = Color(0xFF3B82F6);
  static const Color middle = Color(0xFF22C55E);
  static const Color ring = Color(0xFFF59E0B);
  static const Color pinky = Color(0xFFEC4899);
  static const Color thumb = Color(0xFFA855F7);

  static Color of(int finger) {
    switch (finger) {
      case 1:
        return index;
      case 2:
        return middle;
      case 3:
        return ring;
      case 4:
        return pinky;
      case 5:
        return thumb;
      default:
        return const Color(0xFF94A3B8);
    }
  }

  static String label(int finger) => finger == 5 ? 'T' : '$finger';

  static String name(int finger) {
    switch (finger) {
      case 1:
        return 'Index';
      case 2:
        return 'Middle';
      case 3:
        return 'Ring';
      case 4:
        return 'Pinky';
      case 5:
        return 'Thumb';
      default:
        return 'Finger';
    }
  }
}
