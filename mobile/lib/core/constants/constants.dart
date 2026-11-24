import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'أذكار';
  static const String supabaseUrl = 'https://chzzvopkxajurwkbdijq.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_8lkNqSSfDjRzxhAbniPwmA_G8qaL6A2';

  // Palette
  static const Color primary = Color(0xFF003527);
  static const Color primaryContainer = Color(0xFF064E3B);
  static const Color secondary = Color(0xFF006A61);
  static const Color secondaryContainer = Color(0xFF9DEFE3);
  static const Color tertiary = Color(0xFFC38B1E);
  static const Color surfaceLight = Color(0xFFF8F9FF);
  static const Color surfaceDark = Color(0xFF0E1117);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF161B22);

  // Theme-aware monochrome & contrast helpers (sleek dark mode, zero dark-green text)
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? const Color(0xFFF3F4F6) : const Color(0xFF111827);

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

  static Color cardSurface(BuildContext context) =>
      isDark(context) ? cardDark : cardLight;

  static Color activeSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF21262D) : const Color(0xFFF3F4F6);

  static Color borderColor(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08);

  static Color accent(BuildContext context) =>
      isDark(context) ? const Color(0xFFE5E7EB) : primary;

  static Color accentMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFFD1D5DB) : secondary;

  static Color accentBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF2D333B) : primary;

  static LinearGradient heroGradient(BuildContext context) => isDark(context)
      ? const LinearGradient(
          colors: [Color(0xFF1C2128), Color(0xFF11151B)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        )
      : const LinearGradient(
          colors: [primary, primaryContainer],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );

  // 10 Male Islamic Avatars (3D Luxury Faceless / مختلف الأعمار والألوان)
  static const List<Map<String, String>> maleAvatars = [
    {'id': 'm1', 'title': 'شاب بطاقية بيضاء وثوب مطرز (زمردي)', 'asset': 'assets/avatars/m1.png'},
    {'id': 'm2', 'title': 'رجل بشماغ أحمر وعقال وقور (غابي)', 'asset': 'assets/avatars/m2.png'},
    {'id': 'm3', 'title': 'شيخ مسن بلحية فضية وعمامة (ياقوتي)', 'asset': 'assets/avatars/m3.png'},
    {'id': 'm4', 'title': 'شاب بثوب كتاني بيج (عنبري)', 'asset': 'assets/avatars/m4.png'},
    {'id': 'm5', 'title': 'رجل بشماغ كشميري أسود مذهب (فحمي)', 'asset': 'assets/avatars/m5.png'},
    {'id': 'm6', 'title': 'طفل صغير بثوب تركواز مشرق (سماوي)', 'asset': 'assets/avatars/m6.png'},
    {'id': 'm7', 'title': 'جد مسن بجلابة مغربية أصيلة (ترابي)', 'asset': 'assets/avatars/m7.png'},
    {'id': 'm8', 'title': 'رجل بغترة بيضاء وثوب ملكي (أزرق)', 'asset': 'assets/avatars/m8.png'},
    {'id': 'm9', 'title': 'شاب بثوب زيتي مطرز مع طاقية (زيتوني)', 'asset': 'assets/avatars/m9.png'},
    {'id': 'm10', 'title': 'إمام وقور بعمامة خضراء ملكية (ذهبي)', 'asset': 'assets/avatars/m10.png'},
  ];

  // 10 Female Islamic Avatars (3D Luxury Faceless / منتقبات ومحجبات بمختلف الأعمار)
  static const List<Map<String, String>> femaleAvatars = [
    {'id': 'f1', 'title': 'شابة بحجاب زمردي مطرز بالذهب', 'asset': 'assets/avatars/f1.png'},
    {'id': 'f2', 'title': 'سيدة منتقبة بنقاب أسود ملكي مذهب', 'asset': 'assets/avatars/f2.png'},
    {'id': 'f3', 'title': 'شابة منتقبة بنقاب كحلي بتطريز فضي', 'asset': 'assets/avatars/f3.png'},
    {'id': 'f4', 'title': 'فتاة صغيرة بحجاب وردي ناعم', 'asset': 'assets/avatars/f4.png'},
    {'id': 'f5', 'title': 'سيدة بحجاب بيج موكا دافئ وعباية', 'asset': 'assets/avatars/f5.png'},
    {'id': 'f6', 'title': 'أم/جدة مسنة بإسدال صلاة أبيض ناصع', 'asset': 'assets/avatars/f6.png'},
    {'id': 'f7', 'title': 'شابة بحجاب عنابي ملكي وعباية داكنة', 'asset': 'assets/avatars/f7.png'},
    {'id': 'f8', 'title': 'سيدة منتقبة بنقاب أسود وهالة زمردية', 'asset': 'assets/avatars/f8.png'},
    {'id': 'f9', 'title': 'سيدة بحجاب تركواز حريري هادئ', 'asset': 'assets/avatars/f9.png'},
    {'id': 'f10', 'title': 'شابة بحجاب لؤلؤي أبيض مذهب للأعياد', 'asset': 'assets/avatars/f10.png'},
  ];

  static List<Map<String, String>> getAllAvatars() => [...maleAvatars, ...femaleAvatars];
}
