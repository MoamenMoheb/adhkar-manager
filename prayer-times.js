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
    const jd0 = SunTimesHelper.julianDayUtc(date.getFullYear(), date.getMonth() + 1, date.getDate());
    const approxNoonH = 12 - city.lng / 15;

    const fajrMin = SunTimesHelper.eventUtcMinutes(jd0, city.lat, city.lng, approxNoonH - 6.0, -method.fajrAngle, false);
    const sunriseMin = SunTimesHelper.eventUtcMinutes(jd0, city.lat, city.lng, approxNoonH - 4.5, -0.833, false);
    const dhuhrMin = SunTimesHelper.eventUtcMinutes(jd0, city.lat, city.lng, approxNoonH);

    const asrPos = SunTimesHelper.solarPositionAtJd(jd0 + (approxNoonH + 3.0) / 24);
    const shadowFactor = useHanafi ? 2 : 1;
    const asrCot = shadowFactor + Math.tan(Math.abs(city.lat - asrPos.declDeg) * rad);
    const asrAltDeg = Math.atan(1 / asrCot) * deg;
    const asrMin = SunTimesHelper.eventUtcMinutes(jd0, city.lat, city.lng, approxNoonH + 3.0, asrAltDeg, true);

    const maghribMin = SunTimesHelper.eventUtcMinutes(jd0, city.lat, city.lng, approxNoonH + 5.0, -0.833, true);
    const ishaMin = method.ishaMinutes !== null
      ? maghribMin + method.ishaMinutes
      : SunTimesHelper.eventUtcMinutes(jd0, city.lat, city.lng, approxNoonH + 6.5, -method.ishaAngle, true);

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
