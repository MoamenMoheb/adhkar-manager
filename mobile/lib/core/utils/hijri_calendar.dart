class HijriDate {
  final int year;
  final int month;
  final int day;
  final DateTime gregorian;

  const HijriDate({
    required this.year,
    required this.month,
    required this.day,
    required this.gregorian,
  });

  static const List<String> monthNames = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static const List<String> weekdayNames = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  String get monthName => monthNames[(month - 1).clamp(0, 11)];
  String get weekdayName => weekdayNames[(gregorian.weekday - 1).clamp(0, 6)];

  String get formattedArabic => '$weekdayName، $day $monthName $year هـ';
  String get shortArabic => '$day $monthName $year هـ';

  bool get isMonday => gregorian.weekday == DateTime.monday;
  bool get isThursday => gregorian.weekday == DateTime.thursday;
  bool get isMondayOrThursday => isMonday || isThursday;

  /// الأيام البيض: 13, 14, 15 of every Hijri month
  /// Note: 13 Dhul-Hijjah is part of Ayyam al-Tashreeq (fasting prohibited).
  bool get isProhibitedFastingDay =>
      (month == 10 && day == 1) || // Eid al-Fitr
      (month == 12 && day >= 10 && day <= 13); // Eid al-Adha & Tashreeq

  bool get isAyyamAlBeed =>
      (day == 13 || day == 14 || day == 15) && !isProhibitedFastingDay;

  bool get isRecommendedMonThu => isMondayOrThursday && !isProhibitedFastingDay && month != 9;

  bool get isRecommendedAyyamBeed => isAyyamAlBeed && month != 9;

  bool get isFastingDay => isRecommendedMonThu || isRecommendedAyyamBeed;

  bool get isRamadan => month == 9;

  String? get occasionName {
    if (month == 1 && day == 1) return 'رأس السنة الهجرية';
    if (month == 1 && day == 9) return 'تاسوعاء (صيام مستحب)';
    if (month == 1 && day == 10) return 'يوم عاشوراء (صيام مستحب)';
    if (month == 8 && day == 15) return 'ليلة النصف من شعبان';
    if (month == 9 && day == 1) return 'غرة شهر رمضان المبارك';
    if (month == 10 && day == 1) return 'عيد الفطر المبارك';
    if (month == 12 && day == 9) return 'يوم عرفة (صيام مستحب)';
    if (month == 12 && day == 10) return 'عيد الأضحى المبارك';
    if (month == 12 && day >= 11 && day <= 13) return 'أيام التشريق';
    return null;
  }

  String get fastingReasonLabel {
    if (isProhibitedFastingDay) return 'يوم عيد / تشريق (يحرم صيامه)';
    if (isRamadan) return 'صيام فريضة شهر رمضان المبارك';
    final List<String> reasons = [];
    if (isMonday) reasons.add('صيام يوم الإثنين');
    if (isThursday) reasons.add('صيام يوم الخميس');
    if (isAyyamAlBeed) reasons.add('الأيام البيض ($day $monthName)');
    return reasons.join(' و ');
  }
}

class HijriCalendar {
  // Exact Umm al-Qura calendar data (1442 AH to 1467 AH / 2020 - 2045 CE)
  // Each entry: Hijri year -> [Gregorian UTC epoch start (1 Muharram), ...12 month lengths]
  static final Map<int, _HijriYearData> _ummAlQuraData = {
    1442: _HijriYearData(DateTime.utc(2020, 8, 20), [29, 30, 29, 30, 29, 30, 29, 30, 30, 29, 30, 29]),
    1443: _HijriYearData(DateTime.utc(2021, 8, 9), [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 30]),
    1444: _HijriYearData(DateTime.utc(2022, 7, 30), [29, 30, 29, 30, 30, 29, 29, 30, 29, 30, 29, 30]),
    1445: _HijriYearData(DateTime.utc(2023, 7, 19), [29, 30, 30, 30, 29, 30, 29, 29, 30, 29, 29, 30]),
    1446: _HijriYearData(DateTime.utc(2024, 7, 7), [29, 30, 30, 30, 29, 30, 30, 29, 29, 30, 29, 29]),
    1447: _HijriYearData(DateTime.utc(2025, 6, 26), [30, 29, 30, 30, 30, 29, 30, 29, 30, 29, 30, 29]),
    1448: _HijriYearData(DateTime.utc(2026, 6, 16), [29, 30, 29, 30, 30, 29, 30, 30, 29, 30, 29, 30]),
    1449: _HijriYearData(DateTime.utc(2027, 6, 6), [29, 29, 30, 29, 30, 29, 30, 30, 29, 30, 30, 29]),
    1450: _HijriYearData(DateTime.utc(2028, 5, 25), [30, 29, 30, 29, 29, 30, 29, 30, 29, 30, 30, 29]),
    1451: _HijriYearData(DateTime.utc(2029, 5, 14), [30, 30, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30]),
    1452: _HijriYearData(DateTime.utc(2030, 5, 4), [30, 29, 30, 30, 29, 29, 30, 29, 29, 30, 29, 30]),
    1453: _HijriYearData(DateTime.utc(2031, 4, 23), [30, 29, 30, 30, 29, 30, 29, 30, 29, 29, 30, 29]),
    1454: _HijriYearData(DateTime.utc(2032, 4, 11), [30, 29, 30, 30, 29, 30, 30, 29, 30, 29, 30, 29]),
    1455: _HijriYearData(DateTime.utc(2033, 4, 1), [29, 30, 29, 30, 30, 29, 30, 29, 30, 30, 29, 30]),
    1456: _HijriYearData(DateTime.utc(2034, 3, 22), [29, 29, 30, 29, 30, 29, 30, 29, 30, 30, 30, 29]),
    1457: _HijriYearData(DateTime.utc(2035, 3, 11), [30, 29, 29, 30, 29, 29, 30, 29, 30, 30, 30, 30]),
    1458: _HijriYearData(DateTime.utc(2036, 2, 29), [29, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30, 30]),
    1459: _HijriYearData(DateTime.utc(2037, 2, 17), [29, 30, 30, 29, 29, 30, 29, 29, 30, 29, 30, 30]),
    1460: _HijriYearData(DateTime.utc(2038, 2, 6), [29, 30, 30, 29, 30, 29, 30, 29, 29, 30, 29, 30]),
    1461: _HijriYearData(DateTime.utc(2039, 1, 26), [29, 30, 30, 29, 30, 29, 30, 29, 30, 30, 29, 29]),
    1462: _HijriYearData(DateTime.utc(2040, 1, 15), [30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 30, 29]),
    1463: _HijriYearData(DateTime.utc(2041, 1, 4), [29, 30, 29, 30, 29, 30, 29, 30, 30, 30, 29, 30]),
    1464: _HijriYearData(DateTime.utc(2041, 12, 25), [29, 30, 29, 29, 30, 29, 29, 30, 30, 30, 29, 30]),
    1465: _HijriYearData(DateTime.utc(2042, 12, 14), [30, 29, 30, 29, 29, 30, 29, 29, 30, 30, 29, 30]),
    1466: _HijriYearData(DateTime.utc(2043, 12, 3), [30, 30, 29, 30, 29, 29, 29, 30, 29, 30, 30, 29]),
    1467: _HijriYearData(DateTime.utc(2044, 11, 21), [30, 30, 29, 30, 30, 29, 29, 30, 29, 30, 29, 30]),
  };

  /// Converts a Gregorian [DateTime] to [HijriDate] with optional [offsetDays] (-2..+2).
  static HijriDate fromGregorian(DateTime date, {int offsetDays = 0}) {
    final localDate = DateTime(date.year, date.month, date.day);
    final adjustedUtc = DateTime.utc(date.year, date.month, date.day).add(Duration(days: offsetDays));

    // Search Umm al-Qura table first
    for (final entry in _ummAlQuraData.entries) {
      final y = entry.key;
      final data = entry.value;
      final diffDays = adjustedUtc.difference(data.startUtc).inDays;
      if (diffDays >= 0 && diffDays < data.totalDays) {
        int remaining = diffDays;
        for (int m = 1; m <= 12; m++) {
          final mLen = data.monthLengths[m - 1];
          if (remaining < mLen) {
            return HijriDate(
              year: y,
              month: m,
              day: remaining + 1,
              gregorian: localDate,
            );
          }
          remaining -= mLen;
        }
      }
    }

    // Algorithmic Kuwaiti / Tabular fallback outside 1442-1467 AH
    return _kuwaitiFromGregorian(adjustedUtc, localDate);
  }

  /// Converts Hijri (year, month, day) back to local Gregorian [DateTime].
  static DateTime hijriToGregorian(int hYear, int hMonth, int hDay, {int offsetDays = 0}) {
    final data = _ummAlQuraData[hYear];
    if (data != null) {
      int dayOffset = 0;
      for (int m = 1; m < hMonth; m++) {
        dayOffset += data.monthLengths[m - 1];
      }
      dayOffset += (hDay - 1) - offsetDays;
      final target = data.startUtc.add(Duration(days: dayOffset));
      return DateTime(target.year, target.month, target.day);
    }

    return _kuwaitiToGregorian(hYear, hMonth, hDay, offsetDays: offsetDays);
  }

  static int getDaysInMonth(int hYear, int hMonth) {
    final data = _ummAlQuraData[hYear];
    if (data != null && hMonth >= 1 && hMonth <= 12) {
      return data.monthLengths[hMonth - 1];
    }
    // Tabular fallback: odd months 30, even 29 (12th month 30 on leap years)
    if (hMonth % 2 == 1) return 30;
    if (hMonth == 12 && ((11 * hYear + 14) % 30) < 11) return 30;
    return 29;
  }

  static List<HijriDate> getMonthDays(int hYear, int hMonth, {int offsetDays = 0}) {
    final count = getDaysInMonth(hYear, hMonth);
    return List.generate(count, (idx) {
      final d = idx + 1;
      final greg = hijriToGregorian(hYear, hMonth, d, offsetDays: offsetDays);
      return HijriDate(year: hYear, month: hMonth, day: d, gregorian: greg);
    });
  }

  // Fallback Kuwaiti Algorithm
  static HijriDate _kuwaitiFromGregorian(DateTime utcDate, DateTime localOriginal) {
    int day = utcDate.day;
    int month = utcDate.month;
    int year = utcDate.year;

    int m = month;
    int y = year;
    if (m < 3) {
      y -= 1;
      m += 12;
    }

    int a = (y / 100).floor();
    int b = 2 - a + (a / 4).floor();
    if (y < 1583) b = 0;
    if (y == 1582) {
      if (m > 10) b = -10;
      if (m == 10) {
        b = 0;
        if (day > 4) b = -10;
      }
    }

    int jd = (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + day + b - 1524;

    b = 0;
    if (jd > 2299160) {
      a = ((jd - 1867216.25) / 36524.25).floor();
      b = 1 + a - (a / 4).floor();
    }
    int bb = jd + b + 1524;
    int cc = ((bb - 122.1) / 365.25).floor();
    int dd = (365.25 * cc).floor();
    int ee = ((bb - dd) / 30.6001).floor();
    day = (bb - dd) - (30.6001 * ee).floor();
    month = ee - 1;
    if (ee > 13) {
      cc += 1;
      month = ee - 13;
    }
    year = cc - 4716;

    const double iyear = 10631.0 / 30.0;
    const int epochastro = 1948084;
    const double shift1 = 8.01 / 60.0;

    int z = jd - epochastro;
    int cyc = (z / 10631.0).floor();
    z = z - 10631 * cyc;
    int j = ((z - shift1) / iyear).floor();
    int iy = 30 * cyc + j;
    z = z - (j * iyear + shift1).floor();
    int im = ((z + 28.5001) / 29.5).floor();
    if (im == 13) im = 12;
    int id = z - (29.5001 * im - 29).floor();

    return HijriDate(year: iy, month: im, day: id, gregorian: localOriginal);
  }

  static DateTime _kuwaitiToGregorian(int hYear, int hMonth, int hDay, {int offsetDays = 0}) {
    final jd = ((11 * hYear + 3) / 30).floor() +
        354 * hYear +
        30 * hMonth -
        ((hMonth - 1) / 2).floor() +
        hDay +
        1948440 -
        385 -
        offsetDays;

    int l = jd + 68569;
    int n = ((4 * l) / 146097).floor();
    l = l - ((146097 * n + 3) / 4).floor();
    int i = ((4000 * (l + 1)) / 1461001).floor();
    l = l - ((1461 * i) / 4).floor() + 31;
    int j = ((80 * l) / 2447).floor();
    int day = l - ((2447 * j) / 80).floor();
    l = (j / 11).floor();
    int month = j + 2 - 12 * l;
    int year = 100 * (n - 49) + i + l;

    return DateTime(year, month, day);
  }
}

class _HijriYearData {
  final DateTime startUtc;
  final List<int> monthLengths;
  late final int totalDays = monthLengths.reduce((a, b) => a + b);

  _HijriYearData(this.startUtc, this.monthLengths);
}
