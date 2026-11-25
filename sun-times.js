/**
 * Serene Adhkar Sanctuary - Astronomical Sunrise (Shuruq) & Sunset (Maghrib) Calculator
 * Identical NOAA equations to the Flutter Mobile App
 */

const SUN_CITIES = [
  { key: 'cairo', nameAr: 'القاهرة (مصر)', lat: 30.0444, lng: 31.2357 },
  { key: 'alexandria', nameAr: 'الإسكندرية (مصر)', lat: 31.2001, lng: 29.9187 },
  { key: 'makkah', nameAr: 'مكة المكرمة (السعودية)', lat: 21.3891, lng: 39.8579 },
  { key: 'madinah', nameAr: 'المدينة المنورة (السعودية)', lat: 24.5247, lng: 39.5692 },
  { key: 'riyadh', nameAr: 'الرياض (السعودية)', lat: 24.7136, lng: 46.6753 },
  { key: 'jeddah', nameAr: 'جدة (السعودية)', lat: 21.4858, lng: 39.1925 },
  { key: 'dubai', nameAr: 'دبي (الإمارات)', lat: 25.2048, lng: 55.2708 },
  { key: 'abudhabi', nameAr: 'أبوظبي (الإمارات)', lat: 24.4539, lng: 54.3773 },
  { key: 'doha', nameAr: 'الدوحة (قطر)', lat: 25.2854, lng: 51.5310 },
  { key: 'kuwait', nameAr: 'مدينة الكويت', lat: 29.3759, lng: 47.9774 },
  { key: 'manama', nameAr: 'المنامة (البحرين)', lat: 26.2285, lng: 50.5860 },
  { key: 'muscat', nameAr: 'مسقط (عُمان)', lat: 23.5880, lng: 58.3829 },
  { key: 'amman', nameAr: 'عمّان (الأردن)', lat: 31.9454, lng: 35.9284 },
  { key: 'jerusalem', nameAr: 'القدس (فلسطين)', lat: 31.7683, lng: 35.2137 },
  { key: 'beirut', nameAr: 'بيروت (لبنان)', lat: 33.8938, lng: 35.5018 },
  { key: 'damascus', nameAr: 'دمشق (سوريا)', lat: 33.5138, lng: 36.2765 },
  { key: 'baghdad', nameAr: 'بغداد (العراق)', lat: 33.3152, lng: 44.3661 },
  { key: 'khartoum', nameAr: 'الخرطوم (السودان)', lat: 15.5007, lng: 32.5599 },
  { key: 'tunis', nameAr: 'تونس (تونس)', lat: 36.8065, lng: 10.1815 },
  { key: 'algiers', nameAr: 'الجزائر (الجزائر)', lat: 36.7538, lng: 3.0588 },
  { key: 'rabat', nameAr: 'الرباط (المغرب)', lat: 34.0209, lng: -6.8416 },
  { key: 'istanbul', nameAr: 'إسطنبول (تركيا)', lat: 41.0082, lng: 28.9784 },
  { key: 'london', nameAr: 'لندن (بريطانيا)', lat: 51.5072, lng: -0.1276 }
];

class SunTimesHelper {
  static getSelectedCity() {
    let key = null;
    try {
      key = localStorage.getItem('adhkar_city_key');
    } catch (e) {}
    if (key) {
      const found = SUN_CITIES.find(c => c.key === key);
      if (found) return found;
    }
    try {
      const iana = Intl.DateTimeFormat().resolvedOptions().timeZone || '';
      if (iana.includes('Cairo')) return SUN_CITIES.find(c => c.key === 'cairo');
      if (iana.includes('Riyadh')) return SUN_CITIES.find(c => c.key === 'makkah');
      if (iana.includes('Dubai')) return SUN_CITIES.find(c => c.key === 'dubai');
      if (iana.includes('Qatar')) return SUN_CITIES.find(c => c.key === 'doha');
      if (iana.includes('Kuwait')) return SUN_CITIES.find(c => c.key === 'kuwait');
      if (iana.includes('Amman')) return SUN_CITIES.find(c => c.key === 'amman');
      if (iana.includes('Beirut')) return SUN_CITIES.find(c => c.key === 'beirut');
      if (iana.includes('Baghdad')) return SUN_CITIES.find(c => c.key === 'baghdad');
      if (iana.includes('Tunis')) return SUN_CITIES.find(c => c.key === 'tunis');
      if (iana.includes('Algiers')) return SUN_CITIES.find(c => c.key === 'algiers');
      if (iana.includes('Casablanca')) return SUN_CITIES.find(c => c.key === 'rabat');
      if (iana.includes('Istanbul')) return SUN_CITIES.find(c => c.key === 'istanbul');
      if (iana.includes('London')) return SUN_CITIES.find(c => c.key === 'london');
    } catch (e) {}
    const tzHours = Math.round(-new Date().getTimezoneOffset() / 60);
    if (tzHours === 2) return SUN_CITIES.find(c => c.key === 'cairo');
    if (tzHours === 3) return SUN_CITIES.find(c => c.key === 'makkah');
    if (tzHours === 4) return SUN_CITIES.find(c => c.key === 'dubai');
    if (tzHours === 1) return SUN_CITIES.find(c => c.key === 'tunis');
    if (tzHours === 0) return SUN_CITIES.find(c => c.key === 'london');
    return SUN_CITIES[0];
  }

  static setSelectedCity(key) {
    try {
      localStorage.setItem('adhkar_city_key', key);
    } catch (e) {}
    return this.getSelectedCity();
  }

  static getMorningOffset() {
    try {
      const val = parseInt(localStorage.getItem('adhkar_morning_offset_min') || '30', 10);
      if (!isNaN(val) && val >= 1 && val <= 180) return val;
    } catch (e) {}
    return 30;
  }

  static setMorningOffset(minutes) {
    const val = Math.max(1, Math.min(180, parseInt(minutes, 10) || 30));
    try {
      localStorage.setItem('adhkar_morning_offset_min', String(val));
    } catch (e) {}
    return val;
  }

  static getEveningOffset() {
    try {
      const val = parseInt(localStorage.getItem('adhkar_evening_offset_min') || '30', 10);
      if (!isNaN(val) && val >= 1 && val <= 180) return val;
    } catch (e) {}
    return 30;
  }

  static setEveningOffset(minutes) {
    const val = Math.max(1, Math.min(180, parseInt(minutes, 10) || 30));
    try {
      localStorage.setItem('adhkar_evening_offset_min', String(val));
    } catch (e) {}
    return val;
  }

  static julianDayUtc(year, month, day) {
    let y = year;
    let m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    const a = Math.floor(y / 100);
    const b = 2 - a + Math.floor(a / 4);
    return Math.floor(365.25 * (y + 4716)) + Math.floor(30.6001 * (m + 1)) + day + b - 1524.5;
  }

  static solarPositionAtJd(jd) {
    const rad = Math.PI / 180;
    const deg = 180 / Math.PI;
    const d = jd - 2451545.0;
    const g = (357.529 + 0.98560028 * d) % 360;
    const q = (280.459 + 0.98564736 * d) % 360;
    const l = (q + 1.915 * Math.sin(g * rad) + 0.020 * Math.sin(2 * g * rad)) % 360;
    const e = 23.439 - 0.00000036 * d;

    let raHours = (Math.atan2(Math.cos(e * rad) * Math.sin(l * rad), Math.cos(l * rad)) * deg / 15) % 24;
    if (raHours < 0) raHours += 24;

    let eqHours = (q / 15) - raHours;
    if (eqHours > 12) eqHours -= 24;
    if (eqHours < -12) eqHours += 24;

    const declDeg = Math.asin(Math.sin(e * rad) * Math.sin(l * rad)) * deg;
    return { declDeg, eqTimeMin: eqHours * 60 };
  }

  static hourAngleDeg(lat, declDeg, sunAltitudeDeg) {
    const rad = Math.PI / 180;
    const deg = 180 / Math.PI;
    const cosHA = (Math.sin(sunAltitudeDeg * rad) -
      Math.sin(lat * rad) * Math.sin(declDeg * rad)) /
      (Math.cos(lat * rad) * Math.cos(declDeg * rad));
    return Math.acos(Math.max(-1, Math.min(1, cosHA))) * deg;
  }

  static eventUtcMinutes(jd0, lat, lng, approxUtcHours, sunAltitudeDeg = null, afterNoon = false) {
    const pos = this.solarPositionAtJd(jd0 + approxUtcHours / 24);
    const noonUtcMin = 720 - 4 * lng - pos.eqTimeMin;
    if (sunAltitudeDeg === null) return noonUtcMin;
    const ha = this.hourAngleDeg(lat, pos.declDeg, sunAltitudeDeg);
    return noonUtcMin + (afterNoon ? 4 * ha : -4 * ha);
  }

  static calculate(date = new Date(), lat = null, lng = null) {
    const city = this.getSelectedCity();
    const useLat = lat !== null ? lat : city.lat;
    const useLng = lng !== null ? lng : city.lng;
    const morningOffset = this.getMorningOffset();
    const eveningOffset = this.getEveningOffset();

    const jd0 = this.julianDayUtc(date.getFullYear(), date.getMonth() + 1, date.getDate());
    const approxNoonH = 12 - useLng / 15;
    const sunriseUtcMin = Math.round(this.eventUtcMinutes(jd0, useLat, useLng, approxNoonH - 4.5, -0.833, false));
    const sunsetUtcMin = Math.round(this.eventUtcMinutes(jd0, useLat, useLng, approxNoonH + 5.0, -0.833, true));

    const utcMidnight = Date.UTC(date.getFullYear(), date.getMonth(), date.getDate());
    const sunrise = new Date(utcMidnight + sunriseUtcMin * 60000);
    const sunset = new Date(utcMidnight + sunsetUtcMin * 60000);
    const morningReminder = new Date(sunrise.getTime() - morningOffset * 60000);
    const eveningReminder = new Date(sunset.getTime() - eveningOffset * 60000);

    return {
      city,
      sunrise,
      sunset,
      morningOffset,
      eveningOffset,
      morningReminder,
      eveningReminder,
      sunriseStr: this.formatTimeAr(sunrise),
      sunsetStr: this.formatTimeAr(sunset),
      morningReminderStr: this.formatTimeAr(morningReminder),
      eveningReminderStr: this.formatTimeAr(eveningReminder)
    };
  }

  static formatTimeAr(dt) {
    return dt.toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' });
  }
}
