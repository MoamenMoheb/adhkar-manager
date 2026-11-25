import 'dart:math' as math;
import 'sun_times.dart';

class PrayerMethod {
  final String key;
  final String nameAr;
  final double fajrAngle;
  final double ishaAngle;
  final int? ishaMinutesAfterMaghrib;

  const PrayerMethod({
    required this.key,
    required this.nameAr,
    required this.fajrAngle,
    this.ishaAngle = 17.5,
    this.ishaMinutesAfterMaghrib,
  });
}

class PrayerEntry {
  final String key; // 'fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'
  final String nameAr;
  final DateTime time;
  final bool isFardPrayer;

  const PrayerEntry({
    required this.key,
    required this.nameAr,
    required this.time,
    this.isFardPrayer = true,
  });
}

class DailyPrayerTimes {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final CityCoordinate city;
  final PrayerMethod method;

  const DailyPrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.city,
    required this.method,
  });

  List<PrayerEntry> get allEntries => [
        PrayerEntry(key: 'fajr', nameAr: 'الفجر', time: fajr),
        PrayerEntry(key: 'sunrise', nameAr: 'الشروق', time: sunrise, isFardPrayer: false),
        PrayerEntry(key: 'dhuhr', nameAr: 'الظهر', time: dhuhr),
        PrayerEntry(key: 'asr', nameAr: 'العصر', time: asr),
        PrayerEntry(key: 'maghrib', nameAr: 'المغرب', time: maghrib),
        PrayerEntry(key: 'isha', nameAr: 'العشاء', time: isha),
      ];
}

class PrayerTimesCalculator {
  static const List<PrayerMethod> methods = [
    PrayerMethod(key: 'egypt', nameAr: 'الهيئة المصرية العامة للمساحة', fajrAngle: 19.5, ishaAngle: 17.5),
    PrayerMethod(key: 'makkah', nameAr: 'تقويم أم القرى (مكة المكرمة)', fajrAngle: 18.5, ishaMinutesAfterMaghrib: 90),
    PrayerMethod(key: 'mwl', nameAr: 'رابطة العالم الإسلامي', fajrAngle: 18.0, ishaAngle: 17.0),
    PrayerMethod(key: 'karachi', nameAr: 'جامعة العلوم الإسلامية (كراتشي)', fajrAngle: 18.0, ishaAngle: 18.0),
    PrayerMethod(key: 'isna', nameAr: 'الجمعية الإسلامية بأمريكا الشمالية', fajrAngle: 15.0, ishaAngle: 15.0),
  ];

  static PrayerMethod getMethodByKey(String? key, {String? cityKey}) {
    if (key != null) {
      for (final m in methods) {
        if (m.key == key) return m;
      }
    }
    return defaultMethodForCity(cityKey);
  }

  static PrayerMethod defaultMethodForCity(String? cityKey) {
    if (cityKey == 'makkah' ||
        cityKey == 'madinah' ||
        cityKey == 'riyadh' ||
        cityKey == 'jeddah' ||
        cityKey == 'dubai' ||
        cityKey == 'abudhabi' ||
        cityKey == 'doha' ||
        cityKey == 'kuwait' ||
        cityKey == 'manama' ||
        cityKey == 'muscat') {
      return methods.firstWhere((m) => m.key == 'makkah');
    }
    if (cityKey == 'london') {
      return methods.firstWhere((m) => m.key == 'mwl');
    }
    return methods.firstWhere((m) => m.key == 'egypt');
  }

  static DailyPrayerTimes calculate({
    required DateTime date,
    required CityCoordinate city,
    PrayerMethod? method,
    bool hanafiAsr = false,
  }) {
    final usedMethod = method ?? defaultMethodForCity(city.key);
    const double rad = math.pi / 180.0;
    const double deg = 180.0 / math.pi;

    final jd0 = SunTimesCalculator.julianDayUtc(date.year, date.month, date.day);
    final approxNoonH = 12.0 - city.lng / 15.0;

    final fajrMin = SunTimesCalculator.eventUtcMinutes(
      jd0: jd0,
      lat: city.lat,
      lng: city.lng,
      approxUtcHours: approxNoonH - 6.0,
      sunAltitudeDeg: -usedMethod.fajrAngle,
      afterNoon: false,
    );
    final sunriseMin = SunTimesCalculator.eventUtcMinutes(
      jd0: jd0,
      lat: city.lat,
      lng: city.lng,
      approxUtcHours: approxNoonH - 4.5,
      sunAltitudeDeg: -0.833,
      afterNoon: false,
    );
    final dhuhrMin = SunTimesCalculator.eventUtcMinutes(
      jd0: jd0,
      lat: city.lat,
      lng: city.lng,
      approxUtcHours: approxNoonH,
    );

    final asrPos = SunTimesCalculator.solarPositionAtJd(jd0 + (approxNoonH + 3.0) / 24.0);
    final shadowFactor = hanafiAsr ? 2.0 : 1.0;
    final asrCot = shadowFactor + math.tan(((city.lat - asrPos.declDeg).abs()) * rad);
    final asrAltDeg = math.atan(1.0 / asrCot) * deg;
    final asrMin = SunTimesCalculator.eventUtcMinutes(
      jd0: jd0,
      lat: city.lat,
      lng: city.lng,
      approxUtcHours: approxNoonH + 3.0,
      sunAltitudeDeg: asrAltDeg,
      afterNoon: true,
    );

    final maghribMin = SunTimesCalculator.eventUtcMinutes(
      jd0: jd0,
      lat: city.lat,
      lng: city.lng,
      approxUtcHours: approxNoonH + 5.0,
      sunAltitudeDeg: -0.833,
      afterNoon: true,
    );
    final ishaMin = usedMethod.ishaMinutesAfterMaghrib != null
        ? maghribMin + usedMethod.ishaMinutesAfterMaghrib!
        : SunTimesCalculator.eventUtcMinutes(
            jd0: jd0,
            lat: city.lat,
            lng: city.lng,
            approxUtcHours: approxNoonH + 6.5,
            sunAltitudeDeg: -usedMethod.ishaAngle,
            afterNoon: true,
          );

    final utcDayMidnight = DateTime.utc(date.year, date.month, date.day);
    DateTime toLocalTime(double utcMinutes) =>
        utcDayMidnight.add(Duration(minutes: utcMinutes.round())).toLocal();

    return DailyPrayerTimes(
      fajr: toLocalTime(fajrMin),
      sunrise: toLocalTime(sunriseMin),
      dhuhr: toLocalTime(dhuhrMin),
      asr: toLocalTime(asrMin),
      maghrib: toLocalTime(maghribMin),
      isha: toLocalTime(ishaMin),
      city: city,
      method: usedMethod,
    );
  }

  /// Finds the next upcoming prayer/sunrise from [now] (checking tomorrow's Fajr if after Isha).
  static PrayerEntry getNextPrayer({
    required DateTime now,
    required CityCoordinate city,
    PrayerMethod? method,
    bool hanafiAsr = false,
  }) {
    final todayTimes = calculate(date: now, city: city, method: method, hanafiAsr: hanafiAsr);
    for (final entry in todayTimes.allEntries) {
      if (entry.time.isAfter(now)) return entry;
    }
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final tomorrowTimes = calculate(date: tomorrow, city: city, method: method, hanafiAsr: hanafiAsr);
    return tomorrowTimes.allEntries.first;
  }
}
