/**
 * Serene Adhkar Sanctuary - Umm al-Qura Hijri Calendar & Fasting Reminder Engine
 * Synchronized identically with the Flutter Mobile App
 */

const HIJRI_MONTH_NAMES = [
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
  'ذو الحجة'
];

const ARABIC_WEEKDAYS = [
  'الأحد',
  'الإثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت'
];

const GREGORIAN_MONTH_NAMES = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
];

// Exact Umm al-Qura table (1442 AH - 1467 AH / 2020 - 2045 CE)
const UMM_AL_QURA_DATA = {
  1442: { startUtc: Date.UTC(2020, 7, 20), lengths: [29,30,29,30,29,30,29,30,30,29,30,29] },
  1443: { startUtc: Date.UTC(2021, 7, 9),  lengths: [30,29,30,29,30,29,30,29,30,29,30,30] },
  1444: { startUtc: Date.UTC(2022, 6, 30), lengths: [29,30,29,30,30,29,29,30,29,30,29,30] },
  1445: { startUtc: Date.UTC(2023, 6, 19), lengths: [29,30,30,30,29,30,29,29,30,29,29,30] },
  1446: { startUtc: Date.UTC(2024, 6, 7),  lengths: [29,30,30,30,29,30,30,29,29,30,29,29] },
  1447: { startUtc: Date.UTC(2025, 5, 26), lengths: [30,29,30,30,30,29,30,29,30,29,30,29] },
  1448: { startUtc: Date.UTC(2026, 5, 16), lengths: [29,30,29,30,30,29,30,30,29,30,29,30] },
  1449: { startUtc: Date.UTC(2027, 5, 6),  lengths: [29,29,30,29,30,29,30,30,29,30,30,29] },
  1450: { startUtc: Date.UTC(2028, 4, 25), lengths: [30,29,30,29,29,30,29,30,29,30,30,29] },
  1451: { startUtc: Date.UTC(2029, 4, 14), lengths: [30,30,30,29,29,30,29,29,30,30,29,30] },
  1452: { startUtc: Date.UTC(2030, 4, 4),  lengths: [30,29,30,30,29,29,30,29,29,30,29,30] },
  1453: { startUtc: Date.UTC(2031, 3, 23), lengths: [30,29,30,30,29,30,29,30,29,29,30,29] },
  1454: { startUtc: Date.UTC(2032, 3, 11), lengths: [30,29,30,30,29,30,30,29,30,29,30,29] },
  1455: { startUtc: Date.UTC(2033, 3, 1),  lengths: [29,30,29,30,30,29,30,29,30,30,29,30] },
  1456: { startUtc: Date.UTC(2034, 2, 22), lengths: [29,29,30,29,30,29,30,29,30,30,30,29] },
  1457: { startUtc: Date.UTC(2035, 2, 11), lengths: [30,29,29,30,29,29,30,29,30,30,30,30] },
  1458: { startUtc: Date.UTC(2036, 1, 29), lengths: [29,30,29,29,30,29,29,30,29,30,30,30] },
  1459: { startUtc: Date.UTC(2037, 1, 17), lengths: [29,30,30,29,29,30,29,29,30,29,30,30] },
  1460: { startUtc: Date.UTC(2038, 1, 6),  lengths: [29,30,30,29,30,29,30,29,29,30,29,30] },
  1461: { startUtc: Date.UTC(2039, 0, 26), lengths: [29,30,30,29,30,29,30,29,30,30,29,29] },
  1462: { startUtc: Date.UTC(2040, 0, 15), lengths: [30,29,30,29,30,30,29,30,29,30,30,29] },
  1463: { startUtc: Date.UTC(2041, 0, 4),  lengths: [29,30,29,30,29,30,29,30,30,30,29,30] },
  1464: { startUtc: Date.UTC(2041, 11, 25),lengths: [29,30,29,29,30,29,29,30,30,30,29,30] },
  1465: { startUtc: Date.UTC(2042, 11, 14),lengths: [30,29,30,29,29,30,29,29,30,30,29,30] },
  1466: { startUtc: Date.UTC(2043, 11, 3), lengths: [30,30,29,30,29,29,29,30,29,30,30,29] },
  1467: { startUtc: Date.UTC(2044, 10, 21),lengths: [30,30,29,30,30,29,29,30,29,30,29,30] }
};

class HijriCalendarHelper {
  static getOffsetDays() {
    try {
      const val = parseInt(localStorage.getItem('adhkar_hijri_offset') || '0', 10);
      return isNaN(val) ? 0 : Math.max(-2, Math.min(2, val));
    } catch (e) {
      return 0;
    }
  }

  static setOffsetDays(val) {
    const clamped = Math.max(-2, Math.min(2, val));
    try {
      localStorage.setItem('adhkar_hijri_offset', String(clamped));
    } catch (e) {}
    return clamped;
  }

  static buildHijriObject(hYear, hMonth, hDay, localDate) {
    const weekdayIdx = localDate.getDay(); // 0=Sun, 1=Mon, 4=Thu
    const isMonday = weekdayIdx === 1;
    const isThursday = weekdayIdx === 4;
    const isProhibited = (hMonth === 10 && hDay === 1) || (hMonth === 12 && hDay >= 10 && hDay <= 13);
    const isRamadan = hMonth === 9;
    const isAyyamAlBeed = (hDay === 13 || hDay === 14 || hDay === 15) && !isProhibited;
    const isRecommendedMonThu = (isMonday || isThursday) && !isProhibited && !isRamadan;
    const isRecommendedAyyamBeed = isAyyamAlBeed && !isRamadan;
    const isFastingDay = isRecommendedMonThu || isRecommendedAyyamBeed;

    const monthName = HIJRI_MONTH_NAMES[Math.max(0, Math.min(11, hMonth - 1))];
    const weekdayName = ARABIC_WEEKDAYS[weekdayIdx];

    let occasionName = null;
    if (hMonth === 1 && hDay === 1) occasionName = 'رأس السنة الهجرية';
    else if (hMonth === 1 && hDay === 9) occasionName = 'تاسوعاء (صيام مستحب)';
    else if (hMonth === 1 && hDay === 10) occasionName = 'يوم عاشوراء (صيام مستحب)';
    else if (hMonth === 8 && hDay === 15) occasionName = 'ليلة النصف من شعبان';
    else if (hMonth === 9 && hDay === 1) occasionName = 'غرة شهر رمضان المبارك';
    else if (hMonth === 10 && hDay === 1) occasionName = 'عيد الفطر المبارك';
    else if (hMonth === 12 && hDay === 9) occasionName = 'يوم عرفة (صيام مستحب)';
    else if (hMonth === 12 && hDay === 10) occasionName = 'عيد الأضحى المبارك';
    else if (hMonth === 12 && hDay >= 11 && hDay <= 13) occasionName = 'أيام التشريق';

    const reasons = [];
    if (isMonday) reasons.push('صيام يوم الإثنين');
    if (isThursday) reasons.push('صيام يوم الخميس');
    if (isAyyamAlBeed) reasons.push(`الأيام البيض (${hDay} ${monthName})`);

    let fastingReasonLabel = reasons.join(' و ');
    if (isProhibited) fastingReasonLabel = 'يوم عيد / تشريق (يحرم صيامه)';
    else if (isRamadan) fastingReasonLabel = 'صيام فريضة شهر رمضان المبارك';

    return {
      year: hYear,
      month: hMonth,
      day: hDay,
      monthName,
      weekdayName,
      gregorian: localDate,
      formattedArabic: `${weekdayName}، ${hDay} ${monthName} ${hYear} هـ`,
      shortArabic: `${hDay} ${monthName} ${hYear} هـ`,
      gregorianShort: `${localDate.getDate()} ${GREGORIAN_MONTH_NAMES[localDate.getMonth()]} ${localDate.getFullYear()} م`,
      isMonday,
      isThursday,
      isMondayOrThursday: isMonday || isThursday,
      isProhibitedFastingDay: isProhibited,
      isAyyamAlBeed,
      isRecommendedMonThu,
      isRecommendedAyyamBeed,
      isFastingDay,
      isRamadan,
      occasionName,
      fastingReasonLabel
    };
  }

  static fromGregorian(date = new Date(), offsetDays = null) {
    const offset = offsetDays !== null ? offsetDays : this.getOffsetDays();
    const localDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    const adjustedUtc = Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) + offset * 86400000;

    for (const [yearStr, info] of Object.entries(UMM_AL_QURA_DATA)) {
      const hYear = parseInt(yearStr, 10);
      const totalDays = info.lengths.reduce((a, b) => a + b, 0);
      const diffDays = Math.floor((adjustedUtc - info.startUtc) / 86400000);
      if (diffDays >= 0 && diffDays < totalDays) {
        let rem = diffDays;
        for (let m = 1; m <= 12; m++) {
          const mLen = info.lengths[m - 1];
          if (rem < mLen) {
            return this.buildHijriObject(hYear, m, rem + 1, localDate);
          }
          rem -= mLen;
        }
      }
    }

    // Algorithmic Kuwaiti fallback outside 1442-1467 AH
    return this._kuwaitiFromGregorian(new Date(adjustedUtc), localDate);
  }

  static hijriToGregorian(hYear, hMonth, hDay, offsetDays = null) {
    const offset = offsetDays !== null ? offsetDays : this.getOffsetDays();
    const info = UMM_AL_QURA_DATA[hYear];
    if (info) {
      let dayOffset = 0;
      for (let m = 1; m < hMonth; m++) {
        dayOffset += info.lengths[m - 1];
      }
      dayOffset += (hDay - 1) - offset;
      const dtUtc = new Date(info.startUtc + dayOffset * 86400000);
      return new Date(dtUtc.getUTCFullYear(), dtUtc.getUTCMonth(), dtUtc.getUTCDate());
    }
    return this._kuwaitiToGregorian(hYear, hMonth, hDay, offset);
  }

  static getDaysInMonth(hYear, hMonth) {
    const info = UMM_AL_QURA_DATA[hYear];
    if (info && hMonth >= 1 && hMonth <= 12) {
      return info.lengths[hMonth - 1];
    }
    if (hMonth % 2 === 1) return 30;
    if (hMonth === 12 && ((11 * hYear + 14) % 30) < 11) return 30;
    return 29;
  }

  static getMonthDays(hYear, hMonth, offsetDays = null) {
    const count = this.getDaysInMonth(hYear, hMonth);
    const list = [];
    for (let d = 1; d <= count; d++) {
      const greg = this.hijriToGregorian(hYear, hMonth, d, offsetDays);
      list.push(this.buildHijriObject(hYear, hMonth, d, greg));
    }
    return list;
  }

  static _kuwaitiFromGregorian(utcDate, localOriginal) {
    let day = utcDate.getUTCDate();
    let month = utcDate.getUTCMonth() + 1;
    let year = utcDate.getUTCFullYear();
    let m = month;
    let y = year;
    if (m < 3) {
      y -= 1;
      m += 12;
    }
    let a = Math.floor(y / 100);
    let b = 2 - a + Math.floor(a / 4);
    if (y < 1583) b = 0;
    const jd = Math.floor(365.25 * (y + 4716)) + Math.floor(30.6001 * (m + 1)) + day + b - 1524;

    const iyear = 10631.0 / 30.0;
    const epochastro = 1948084;
    const shift1 = 8.01 / 60.0;
    let z = jd - epochastro;
    const cyc = Math.floor(z / 10631.0);
    z = z - 10631 * cyc;
    const j = Math.floor((z - shift1) / iyear);
    const iy = 30 * cyc + j;
    z = z - Math.floor(j * iyear + shift1);
    let im = Math.floor((z + 28.5001) / 29.5);
    if (im === 13) im = 12;
    const id = z - Math.floor(29.5001 * im - 29);

    return this.buildHijriObject(iy, im, id, localOriginal);
  }

  static _kuwaitiToGregorian(hYear, hMonth, hDay, offset = 0) {
    const jd = Math.floor((11 * hYear + 3) / 30) + 354 * hYear + 30 * hMonth - Math.floor((hMonth - 1) / 2) + hDay + 1948440 - 385 - offset;
    let l = jd + 68569;
    const n = Math.floor((4 * l) / 146097);
    l = l - Math.floor((146097 * n + 3) / 4);
    const i = Math.floor((4000 * (l + 1)) / 1461001);
    l = l - Math.floor((1461 * i) / 4) + 31;
    const j = Math.floor((80 * l) / 2447);
    const day = l - Math.floor((2447 * j) / 80);
    l = Math.floor(j / 11);
    const month = j + 2 - 12 * l;
    const year = 100 * (n - 49) + i + l;
    return new Date(year, month - 1, day);
  }
}
