import 'dart:math' as math;

class CityCoordinate {
  final String key;
  final String nameAr;
  final double lat;
  final double lng;

  const CityCoordinate({
    required this.key,
    required this.nameAr,
    required this.lat,
    required this.lng,
  });
}

class SunTimesResult {
  final DateTime sunrise; // الشروق
  final DateTime sunset;  // المغرب

  const SunTimesResult({required this.sunrise, required this.sunset});

  DateTime get morningAdhkarReminder => sunrise.subtract(const Duration(minutes: 30));
  DateTime get eveningAdhkarReminder => sunset.subtract(const Duration(minutes: 30));
}

class SunTimesCalculator {
  static const List<CityCoordinate> cities = [
    CityCoordinate(key: 'cairo', nameAr: 'القاهرة (مصر)', lat: 30.0444, lng: 31.2357),
    CityCoordinate(key: 'alexandria', nameAr: 'الإسكندرية (مصر)', lat: 31.2001, lng: 29.9187),
    CityCoordinate(key: 'makkah', nameAr: 'مكة المكرمة (السعودية)', lat: 21.3891, lng: 39.8579),
    CityCoordinate(key: 'madinah', nameAr: 'المدينة المنورة (السعودية)', lat: 24.5247, lng: 39.5692),
    CityCoordinate(key: 'riyadh', nameAr: 'الرياض (السعودية)', lat: 24.7136, lng: 46.6753),
    CityCoordinate(key: 'jeddah', nameAr: 'جدة (السعودية)', lat: 21.4858, lng: 39.1925),
    CityCoordinate(key: 'dubai', nameAr: 'دبي (الإمارات)', lat: 25.2048, lng: 55.2708),
    CityCoordinate(key: 'abudhabi', nameAr: 'أبوظبي (الإمارات)', lat: 24.4539, lng: 54.3773),
    CityCoordinate(key: 'doha', nameAr: 'الدوحة (قطر)', lat: 25.2854, lng: 51.5310),
    CityCoordinate(key: 'kuwait', nameAr: 'مدينة الكويت', lat: 29.3759, lng: 47.9774),
    CityCoordinate(key: 'manama', nameAr: 'المنامة (البحرين)', lat: 26.2285, lng: 50.5860),
    CityCoordinate(key: 'muscat', nameAr: 'مسقط (عُمان)', lat: 23.5880, lng: 58.3829),
    CityCoordinate(key: 'amman', nameAr: 'عمّان (الأردن)', lat: 31.9454, lng: 35.9284),
    CityCoordinate(key: 'jerusalem', nameAr: 'القدس (فلسطين)', lat: 31.7683, lng: 35.2137),
    CityCoordinate(key: 'beirut', nameAr: 'بيروت (لبنان)', lat: 33.8938, lng: 35.5018),
    CityCoordinate(key: 'damascus', nameAr: 'دمشق (سوريا)', lat: 33.5138, lng: 36.2765),
    CityCoordinate(key: 'baghdad', nameAr: 'بغداد (العراق)', lat: 33.3152, lng: 44.3661),
    CityCoordinate(key: 'khartoum', nameAr: 'الخرطوم (السودان)', lat: 15.5007, lng: 32.5599),
    CityCoordinate(key: 'tunis', nameAr: 'تونس (تونس)', lat: 36.8065, lng: 10.1815),
    CityCoordinate(key: 'algiers', nameAr: 'الجزائر (الجزائر)', lat: 36.7538, lng: 3.0588),
    CityCoordinate(key: 'rabat', nameAr: 'الرباط (المغرب)', lat: 34.0209, lng: -6.8416),
    CityCoordinate(key: 'istanbul', nameAr: 'إسطنبول (تركيا)', lat: 41.0082, lng: 28.9784),
    CityCoordinate(key: 'london', nameAr: 'لندن (بريطانيا)', lat: 51.5072, lng: -0.1276),
  ];

  static CityCoordinate getCityByKey(String? key) {
    if (key != null) {
      for (final c in cities) {
        if (c.key == key) return c;
      }
    }
    return defaultCityForLocalTimezone();
  }

  static CityCoordinate defaultCityForLocalTimezone() {
    final now = DateTime.now();
    final tzName = now.timeZoneName.toUpperCase();
    final hours = now.timeZoneOffset.inHours;

    // Handle Egypt Summer/Winter time (EET = UTC+2, EEST = UTC+3)
    if (tzName.contains('EET') || tzName.contains('EEST') || tzName.contains('CAIRO') || tzName.contains('EGYPT')) {
      return cities.firstWhere((c) => c.key == 'cairo');
    }
    if (hours == 2) return cities.firstWhere((c) => c.key == 'cairo');
    if (hours == 3) return cities.firstWhere((c) => c.key == 'makkah');
    if (hours == 4) return cities.firstWhere((c) => c.key == 'dubai');
    if (hours == 1) return cities.firstWhere((c) => c.key == 'tunis');
    if (hours == 0) return cities.firstWhere((c) => c.key == 'london');
    return cities.first;
  }

  /// Calculates astronomical Sunrise (الشروق) and Sunset/Maghrib (المغرب)
  /// for the given local [date] and [lat]/[lng] using NOAA solar equations.
  static SunTimesResult calculate(DateTime date, double lat, double lng) {
    const double rad = math.pi / 180.0;
    const double deg = 180.0 / math.pi;

    final startOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays + 1;
    final gamma = (2.0 * math.pi / 365.0) * (dayOfYear - 1);

    final eqTime = 229.18 *
        (0.000075 +
            0.001868 * math.cos(gamma) -
            0.032077 * math.sin(gamma) -
            0.014615 * math.cos(2 * gamma) -
            0.040849 * math.sin(2 * gamma));

    final decl = 0.006918 -
        0.399912 * math.cos(gamma) +
        0.070257 * math.sin(gamma) -
        0.006758 * math.cos(2 * gamma) +
        0.000907 * math.sin(2 * gamma) -
        0.002697 * math.cos(3 * gamma) +
        0.00148 * math.sin(3 * gamma);

    final cosHA = (math.cos(90.833 * rad) / (math.cos(lat * rad) * math.cos(decl))) -
        math.tan(lat * rad) * math.tan(decl);
    final clampedCos = cosHA.clamp(-1.0, 1.0);
    final ha = math.acos(clampedCos) * deg;

    final sunriseUtcMinutes = (720.0 - 4.0 * (lng + ha) - eqTime).round();
    final sunsetUtcMinutes = (720.0 - 4.0 * (lng - ha) - eqTime).round();

    final utcDayMidnight = DateTime.utc(date.year, date.month, date.day);
    final sunriseLocal = utcDayMidnight.add(Duration(minutes: sunriseUtcMinutes)).toLocal();
    final sunsetLocal = utcDayMidnight.add(Duration(minutes: sunsetUtcMinutes)).toLocal();

    return SunTimesResult(sunrise: sunriseLocal, sunset: sunsetLocal);
  }
}
