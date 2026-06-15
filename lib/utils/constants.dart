import 'package:flutter/material.dart';

// App Colors
class AppColors {
  static const Color primary = Color(0xFF2E7D32);      // dark green
  static const Color primaryLight = Color(0xFF4CAF50); // light green
  static const Color accent = Color(0xFF00C853);       // bright green
  static const Color background = Color(0xFF0A0F0A);   // dark background
  static const Color surface = Color(0xFF1A2E1A);      // card background
  static const Color textPrimary = Color(0xFFFFFFFF);  // white text
  static const Color textSecondary = Color(0xFF9E9E9E);// grey text
  static const Color xpColor = Color(0xFFFFD700);      // gold for XP
}

// App Text Styles
class AppText {
  static const TextStyle heading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
}

// Supabase table names
class Tables {
  static const String profiles = 'profiles';
  static const String habits = 'habits';
  static const String challenges = 'challenges';
  static const String userChallenges = 'user_challenges';
  static const String posts = 'posts';
  static const String rewards = 'rewards';
}