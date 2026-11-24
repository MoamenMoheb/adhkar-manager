/**
 * Serene Adhkar Sanctuary - 5 Daily Prayers & Sunrise (Shuruq) Astronomical Engine
 * Synchronized identically with the Flutter Mobile App (Egypt, Makkah, MWL, Karachi, ISNA)
 */

const PRAYER_METHODS = [
  { key: 'egypt', nameAr: 'الهيئة المصرية العامة للمساحة', fajrAngle: 19.5, ishaAngle: 17.5, ishaMinutes: null },
  { key: 'makkah', nameAr: 'تقويم أم القرى (مكة المكرمة)', fajrAngle: 18.5, ishaAngle: 0, ishaMinutes: 90 },
  { key: 'mwl', nameAr: 'رابطة العالم الإسلامي', fajrAngle: 18.0, ishaAngle: 17.0, ishaMinutes: null },
  { key: 'karachi', nameAr: 'جامعة العلوم الإسلامية (كراتشي)', fajrAngle: 18.0, ishaAngle: 18.0, ishaMinutes: null },
  { key: 'isna', nameAr: 'الجمعية الإسلامية بأمريكا الشمالية', fajrAngle: 15.0, ishaAngle: 15.0, ishaMinutes: null }
];

class PrayerTimesHelper {
  static getSelectedMethod(cityKey = null) {
    let saved = null;
    try { saved = localStorage.getItem('adhkar_prayer_method'); } catch (e) {}
    if (saved) {
      const found = PRAYER_METHODS.find(m => m.key === saved);
      if (found) return found;
    }
    return this.defaultMethodForCity(cityKey || SunTimesHelper.getSelectedCity().key);
  }

  static setSelectedMethod(key) {
    try { localStorage.setItem('adhkar_prayer_method', key); } catch (e) {}
    return this.getSelectedMethod();
  }

  static isHanafiAsr() {
    try { return localStorage.getItem('adhkar_hanafi_asr') === '1'; } catch (e) { return false; }
  }

  static setHanafiAsr(val) {
    try { localStorage.setItem('adhkar_hanafi_asr', val ? '1' : '0'); } catch (e) {}
  }

  static defaultMethodForCity(cityKey) {
    if (['makkah', 'madinah', 'riyadh', 'jeddah', 'dubai', 'abudhabi', 'doha', 'kuwait', 'manama', 'muscat'].includes(cityKey)) {
      return PRAYER_METHODS.find(m => m.key === 'makkah');
    }
    if (cityKey === 'london') return PRAYER_METHODS.find(m => m.key === 'mwl');
    return PRAYER_METHODS.find(m => m.key === 'egypt');
  }

  static calculate(date = new Date(), cityObj = null, methodObj = null, hanafiAsr = null) {
    const city = cityObj || SunTimesHelper.getSelectedCity();
    const method = methodObj || this.getSelectedMethod(city.key);
    const useHanafi = hanafiAsr !== null ? hanafiAsr : this.isHanafiAsr();

    const rad = Math.PI / 180;
    const deg = 180 / Math.PI;
    const startOfYear = new Date(date.getFullYear(), 0, 1);
    const dayOfYear = Math.floor((date - startOfYear) / 86400000) + 1;
    const gamma = (2 * Math.PI / 365) * (dayOfYear - 1);

    const eqTime = 229.18 * (
      0.000075 +
      0.001868 * Math.cos(gamma) -
      0.032077 * Math.sin(gamma) -
      0.014615 * Math.cos(2 * gamma) -
      0.040849 * Math.sin(2 * gamma)
    );

    const decl = 0.006918 -
      0.399912 * Math.cos(gamma) +
      0.070257 * Math.sin(gamma) -
      0.006758 * Math.cos(2 * gamma) +
      0.000907 * Math.sin(2 * gamma) -
      0.002697 * Math.cos(3 * gamma) +
      0.00148 * Math.sin(3 * gamma);

    const solarNoonUtcMin = 720 - 4 * city.lng - eqTime;

    const hourAngleDeg = (sunAltDeg) => {
      const cosHA = (Math.sin(sunAltDeg * rad) - Math.sin(city.lat * rad) * Math.sin(decl)) /
        (Math.cos(city.lat * rad) * Math.cos(decl));
      return Math.acos(Math.max(-1, Math.min(1, cosHA))) * deg;
    };

    const fajrMin = solarNoonUtcMin - 4 * hourAngleDeg(-method.fajrAngle);
    const sunriseMin = solarNoonUtcMin - 4 * hourAngleDeg(-0.833);
    const dhuhrMin = solarNoonUtcMin + 1;

    const shadowFactor = useHanafi ? 2 : 1;
    const asrCot = shadowFactor + Math.tan(Math.abs(city.lat * rad - decl));
    const asrAltDeg = Math.atan(1 / asrCot) * deg;
    const asrMin = solarNoonUtcMin + 4 * hourAngleDeg(asrAltDeg);

    const maghribMin = solarNoonUtcMin + 4 * hourAngleDeg(-0.833);
    const ishaMin = method.ishaMinutes !== null
      ? maghribMin + method.ishaMinutes
      : solarNoonUtcMin + 4 * hourAngleDeg(-method.ishaAngle);

    const utcMidnight = Date.UTC(date.getFullYear(), date.getMonth(), date.getDate());
    const toLocalDate = (utcMin) => new Date(utcMidnight + Math.round(utcMin) * 60000);

    const fajr = toLocalDate(fajrMin);
    const sunrise = toLocalDate(sunriseMin);
    const dhuhr = toLocalDate(dhuhrMin);
    const asr = toLocalDate(asrMin);
    const maghrib = toLocalDate(maghribMin);
    const isha = toLocalDate(ishaMin);

    const entries = [
      { key: 'fajr', nameAr: 'الفجر', time: fajr, timeStr: SunTimesHelper.formatTimeAr(fajr), isFard: true, icon: 'wb_twilight' },
      { key: 'sunrise', nameAr: 'الشروق', time: sunrise, timeStr: SunTimesHelper.formatTimeAr(sunrise), isFard: false, icon: 'wb_sunny' },
      { key: 'dhuhr', nameAr: 'الظهر', time: dhuhr, timeStr: SunTimesHelper.formatTimeAr(dhuhr), isFard: true, icon: 'light_mode' },
      { key: 'asr', nameAr: 'العصر', time: asr, timeStr: SunTimesHelper.formatTimeAr(asr), isFard: true, icon: 'sunny' },
      { key: 'maghrib', nameAr: 'المغرب', time: maghrib, timeStr: SunTimesHelper.formatTimeAr(maghrib), isFard: true, icon: 'nights_stay' },
      { key: 'isha', nameAr: 'العشاء', time: isha, timeStr: SunTimesHelper.formatTimeAr(isha), isFard: true, icon: 'bedtime' }
    ];

    return { city, method, fajr, sunrise, dhuhr, asr, maghrib, isha, entries };
  }

  static getNextPrayer(now = new Date()) {
    const today = this.calculate(now);
    for (const e of today.entries) {
      if (e.time > now) return e;
    }
    const tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
    return this.calculate(tomorrow).entries[0];
  }
}
