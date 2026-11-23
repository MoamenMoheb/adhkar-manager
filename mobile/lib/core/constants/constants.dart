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
  static const Color surfaceDark = Color(0xFF0B111A);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF16202E);

  // 10 Male Islamic Avatars
  static const List<Map<String, String>> maleAvatars = [
    {'id': 'm1', 'title': 'طاقية بيضاء ولحية خفيفة', 'asset': 'assets/avatars/m1.svg'},
    {'id': 'm2', 'title': 'شماغ أحمر ولحية', 'asset': 'assets/avatars/m2.svg'},
    {'id': 'm3', 'title': 'عمامة بيضاء وقورة', 'asset': 'assets/avatars/m3.svg'},
    {'id': 'm4', 'title': 'غترة بيضاء ناصعة', 'asset': 'assets/avatars/m4.svg'},
    {'id': 'm5', 'title': 'طاقية خضراء مذهبة', 'asset': 'assets/avatars/m5.svg'},
    {'id': 'm6', 'title': 'ثوب كحلي وطاقية بيضاء', 'asset': 'assets/avatars/m6.svg'},
    {'id': 'm7', 'title': 'لحية كاملة وطاقية بيضاء', 'asset': 'assets/avatars/m7.svg'},
    {'id': 'm8', 'title': 'شماغ أنيق', 'asset': 'assets/avatars/m8.svg'},
    {'id': 'm9', 'title': 'شاب بطاقية بيضاء', 'asset': 'assets/avatars/m9.svg'},
    {'id': 'm10', 'title': 'عمامة خضراء مباركة', 'asset': 'assets/avatars/m10.svg'},
  ];

  // 10 Female Islamic Avatars
  static const List<Map<String, String>> femaleAvatars = [
    {'id': 'f1', 'title': 'حجاب زمردي إسلامي', 'asset': 'assets/avatars/f1.svg'},
    {'id': 'f2', 'title': 'حجاب فيروزي هادئ', 'asset': 'assets/avatars/f2.svg'},
    {'id': 'f3', 'title': 'حجاب كحلي وقور', 'asset': 'assets/avatars/f3.svg'},
    {'id': 'f4', 'title': 'حجاب بيج ناعم', 'asset': 'assets/avatars/f4.svg'},
    {'id': 'f5', 'title': 'حجاب وردي هادئ', 'asset': 'assets/avatars/f5.svg'},
    {'id': 'f6', 'title': 'نقاب أسود إسلامي', 'asset': 'assets/avatars/f6.svg'},
    {'id': 'f7', 'title': 'حجاب زيتوني أنيق', 'asset': 'assets/avatars/f7.svg'},
    {'id': 'f8', 'title': 'نقاب وقور', 'asset': 'assets/avatars/f8.svg'},
    {'id': 'f9', 'title': 'حجاب حريري أبيض', 'asset': 'assets/avatars/f9.svg'},
    {'id': 'f10', 'title': 'حجاب داكن فاخر', 'asset': 'assets/avatars/f10.svg'},
  ];

  static List<Map<String, String>> getAllAvatars() => [...maleAvatars, ...femaleAvatars];
}
