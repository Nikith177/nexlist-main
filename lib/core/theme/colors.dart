import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Update these hex codes to precisely match the web frontend)
  static const Color primary = Color(0xFF0066FF); // Classic Nexlist Blue
  static const Color secondary = Color(0xFF22C55E); // Accent Green (for success/actions)
  static const Color accent = Color(0xFFFF9100); // Orange for urgent items

  // Semantic Colors
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF1976D2);

  // Neutral Colors (Light Theme)
  static const Color background = Color(0xFFF9FAFB); // Very light grey
  static const Color surface = Colors.white;
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937); // Dark Slate Grey
  static const Color textSecondary = Color(0xFF6B7280); // Cool Grey
  static const Color textHint = Color(0xFF9CA3AF); 
  
  // Borders & Dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
}
