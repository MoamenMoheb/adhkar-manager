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

  DateTime morningReminder({int minutesBefore = 30}) =>
      sunrise.subtract(Duration(minutes: minutesBefore.clamp(1, 180)));

  DateTime eveningReminder({int minutesBefore = 30}) =>
      sunset.subtract(Duration(minutes: minutesBefore.clamp(1, 180)));

  DateTime get morningAdhkarReminder => morningReminder(minutesBefore: 30);
  DateTime get eveningAdhkarReminder => eveningReminder(minutesBefore: 30);
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

  /// Converts Gregorian [year]/[month]/[day] at 00:00 UTC to Julian Day.
  static double julianDayUtc(int year, int month, int day) {
    int y = year;
    int m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = y ~/ 100;
    final b = 2 - a + (a ~/ 4);
    return (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + day + b - 1524.5;
  }

  /// High-precision Jean Meeus solar declination (degrees) & equation of time (minutes)
  /// evaluated at [jd] (Julian Day including fractional UTC hour).
  static ({double declDeg, double eqTimeMin}) solarPositionAtJd(double jd) {
    const double rad = math.pi / 180.0;
    const double deg = 180.0 / math.pi;
    final d = jd - 2451545.0;
    final g = (357.529 + 0.98560028 * d) % 360.0;
    final q = (280.459 + 0.98564736 * d) % 360.0;
    final l = (q + 1.915 * math.sin(g * rad) + 0.020 * math.sin(2.0 * g * rad)) % 360.0;
    final e = 23.439 - 0.00000036 * d;

    double raHours = (math.atan2(math.cos(e * rad) * math.sin(l * rad), math.cos(l * rad)) * deg / 15.0) % 24.0;
    if (raHours < 0) raHours += 24.0;

    double eqHours = (q / 15.0) - raHours;
    if (eqHours > 12.0) eqHours -= 24.0;
    if (eqHours < -12.0) eqHours += 24.0;

    final declDeg = math.asin(math.sin(e * rad) * math.sin(l * rad)) * deg;
    return (declDeg: declDeg, eqTimeMin: eqHours * 60.0);
  }

  /// Solar hour angle (degrees) for [sunAltitudeDeg] at [lat]/[declDeg].
  static double hourAngleDeg(double lat, double declDeg, double sunAltitudeDeg) {
    const double rad = math.pi / 180.0;
    const double deg = 180.0 / math.pi;
    final cosHA = (math.sin(sunAltitudeDeg * rad) -
            math.sin(lat * rad) * math.sin(declDeg * rad)) /
        (math.cos(lat * rad) * math.cos(declDeg * rad));
    return math.acos(cosHA.clamp(-1.0, 1.0)) * deg;
  }

  /// Computes a prayer/solar event in UTC minutes using Meeus position at [approxUtcHours].
  static double eventUtcMinutes({
    required double jd0,
    required double lat,
    required double lng,
    required double approxUtcHours,
    double? sunAltitudeDeg,
    bool afterNoon = false,
  }) {
    final pos = solarPositionAtJd(jd0 + approxUtcHours / 24.0);
    final noonUtcMin = 720.0 - 4.0 * lng - pos.eqTimeMin;
    if (sunAltitudeDeg == null) return noonUtcMin;
    final ha = hourAngleDeg(lat, pos.declDeg, sunAltitudeDeg);
    return noonUtcMin + (afterNoon ? 4.0 * ha : -4.0 * ha);
  }

  /// Calculates astronomical Sunrise (الشروق) and Sunset/Maghrib (المغرب)
  /// for the given local [date] and [lat]/[lng] using Jean Meeus solar equations.
  static SunTimesResult calculate(DateTime date, double lat, double lng) {
    final jd0 = julianDayUtc(date.year, date.month, date.day);
    final approxNoonH = 12.0 - lng / 15.0;
    final sunriseUtcMin = eventUtcMinutes(
      jd0: jd0,
      lat: lat,
      lng: lng,
      approxUtcHours: approxNoonH - 4.5,
      sunAltitudeDeg: -0.833,
      afterNoon: false,
    );
    final sunsetUtcMin = eventUtcMinutes(
      jd0: jd0,
      lat: lat,
      lng: lng,
      approxUtcHours: approxNoonH + 5.0,
      sunAltitudeDeg: -0.833,
      afterNoon: true,
    );

    final utcDayMidnight = DateTime.utc(date.year, date.month, date.day);
    final sunriseLocal = utcDayMidnight.add(Duration(minutes: sunriseUtcMin.round())).toLocal();
    final sunsetLocal = utcDayMidnight.add(Duration(minutes: sunsetUtcMin.round())).toLocal();

    return SunTimesResult(sunrise: sunriseLocal, sunset: sunsetLocal);
  }
}
