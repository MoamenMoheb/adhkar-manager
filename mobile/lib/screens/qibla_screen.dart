import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../core/utils/qibla_calculator.dart';
import '../core/utils/sun_times.dart';
import '../services/notification_service.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  static const EventChannel _compassEvents =
      EventChannel('com.moamenmoheb.adhkar_sanctuary/qibla_compass');
  static const MethodChannel _locationChannel =
      MethodChannel('com.moamenmoheb.adhkar_sanctuary/qibla_location');

  StreamSubscription<dynamic>? _compassSub;

  double _lat = 30.0444;
  double _lng = 31.2357;
  String _locationLabel = 'القاهرة (مصر)';
  bool _usingGps = false;
  bool _fetchingGps = false;

  double _declinationDeg = 0.0;
  double _magneticHeading = 0.0;
  int _accuracy = 2; // 0=unreliable, 1=low, 2=medium, 3=high, -1=none
  bool _hasSensor = true;
  bool _wasAligned = false;
  bool _promptedCalibration = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _startCompassStream();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final cityKey = await NotificationService.instance.getSelectedCityKey();
    final city = SunTimesCalculator.getCityByKey(cityKey);
    if (!mounted) return;
    setState(() {
      _lat = city.lat;
      _lng = city.lng;
      _locationLabel = city.nameAr;
      _usingGps = false;
    });
    await _updateDeclination();
  }

  Future<void> _updateDeclination() async {
    try {
      final decl = await _locationChannel.invokeMethod<double>('getDeclination', {
        'lat': _lat,
        'lng': _lng,
      });
      if (decl != null && mounted) {
        setState(() => _declinationDeg = decl);
      }
    } catch (_) {
      // Non-fatal fallback: 0° declination
    }
  }

  Future<void> _refreshGpsLocation() async {
    if (_fetchingGps) return;
    setState(() => _fetchingGps = true);
    try {
      final res = await _locationChannel.invokeMapMethod<String, dynamic>('getCurrentLocation');
      if (!mounted) return;
      if (res != null && res['lat'] != null && res['lng'] != null) {
        setState(() {
          _lat = (res['lat'] as num).toDouble();
          _lng = (res['lng'] as num).toDouble();
          _locationLabel = 'الموقع الحالي (GPS)';
          _usingGps = true;
        });
        await _updateDeclination();
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('تم تحديد موقعك عبر GPS بدقة عالية')),
            );
        }
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('تعذر الحصول على GPS — يمكنك اختيار المدينة يدوياً')),
          );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('خدمة الموقع غير متاحة حالياً')),
          );
      }
    } finally {
      if (mounted) setState(() => _fetchingGps = false);
    }
  }

  void _startCompassStream() {
    _compassSub = _compassEvents.receiveBroadcastStream().listen(
      (event) {
        if (!mounted || event is! Map) return;
        final hasSensor = (event['hasSensor'] as bool?) ?? true;
        final heading = (event['heading'] as num?)?.toDouble() ?? 0.0;
        final accuracy = (event['accuracy'] as num?)?.toInt() ?? 2;

        final trueHeading = (heading + _declinationDeg + 360.0) % 360.0;
        final qiblaBearing = QiblaCalculator.bearingToKaaba(_lat, _lng);
        final delta = QiblaCalculator.signedDeltaDegrees(trueHeading, qiblaBearing);
        final alignedNow = hasSensor && delta.abs() <= 3.0;

        if (alignedNow && !_wasAligned) {
          HapticFeedback.mediumImpact();
        }
        _wasAligned = alignedNow;

        setState(() {
          _hasSensor = hasSensor;
          _magneticHeading = heading;
          _accuracy = accuracy;
        });

        if (hasSensor && accuracy <= 1 && !_promptedCalibration) {
          _promptedCalibration = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showCalibrationSheet();
          });
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _hasSensor = false;
            _accuracy = -1;
          });
        }
      },
    );
  }

  void _showCalibrationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CalibrationSheet(),
    );
  }

  void _showCityPicker() {
    final primaryTxt = AppConstants.textPrimary(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.cardSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppConstants.borderColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'اختر المدينة لحساب القبلة',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryTxt,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: SunTimesCalculator.cities.length,
                itemBuilder: (_, idx) {
                  final city = SunTimesCalculator.cities[idx];
                  final selected = !_usingGps && _locationLabel == city.nameAr;
                  return ListTile(
                    leading: Icon(
                      Icons.location_city_outlined,
                      color: selected ? AppConstants.secondary : AppConstants.textSecondary(context),
                    ),
                    title: Text(
                      city.nameAr,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        color: primaryTxt,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_circle, color: AppConstants.secondary)
                        : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await NotificationService.instance.setSelectedCityKey(city.key);
                      if (!mounted) return;
                      setState(() {
                        _lat = city.lat;
                        _lng = city.lng;
                        _locationLabel = city.nameAr;
                        _usingGps = false;
                      });
                      await _updateDeclination();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _accuracyLabel() {
    switch (_accuracy) {
      case 3:
        return 'دقة البوصلة: عالية';
      case 2:
        return 'دقة البوصلة: متوسطة';
      case 1:
        return 'دقة البوصلة: منخفضة — اضغط للمعايرة';
      case 0:
        return 'البوصلة تحتاج للمعايرة';
      default:
        return 'لا يوجد مستشعر بوصلة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConstants.isDark(context);
    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);

    final qiblaBearing = QiblaCalculator.bearingToKaaba(_lat, _lng);
    final distanceKm = QiblaCalculator.distanceToKaabaKm(_lat, _lng);
    final trueHeading = (_magneticHeading + _declinationDeg + 360.0) % 360.0;
    final delta = QiblaCalculator.signedDeltaDegrees(trueHeading, qiblaBearing);
    final isAligned = _hasSensor && delta.abs() <= 3.0;
    final accentEmerald = isDark ? const Color(0xFF10B981) : AppConstants.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'اتجاه القبلة',
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _fetchingGps
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            tooltip: 'تحديد موقعي عبر GPS',
            onPressed: _fetchingGps ? null : _refreshGpsLocation,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'معايرة البوصلة',
            onPressed: _showCalibrationSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // 1. Stylized Trajectory & Metrics Card
            Container(
              decoration: BoxDecoration(
                color: AppConstants.cardSurface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppConstants.borderColor(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SizedBox(
                    height: 132,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _TrajectoryMapPainter(
                              isDark: isDark,
                              accentColor: accentEmerald,
                              bearingDeg: qiblaBearing,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: InkWell(
                            onTap: _showCityPicker,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.black : Colors.white).withOpacity(0.75),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppConstants.borderColor(context)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _usingGps ? Icons.gps_fixed : Icons.location_on,
                                    size: 14,
                                    color: accentEmerald,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _locationLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTxt,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.keyboard_arrow_down, size: 14, color: secondaryTxt),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.black : Colors.white).withOpacity(0.75),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppConstants.borderColor(context)),
                            ),
                            child: Text(
                              'الكعبة المشرفة',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFD4AF37) : AppConstants.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppConstants.borderColor(context)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${distanceKm.toStringAsFixed(1)} كم',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTxt,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'المسافة إلى الكعبة',
                                style: TextStyle(fontSize: 11, color: secondaryTxt),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppConstants.borderColor(context),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${qiblaBearing.round()}°',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: accentEmerald,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'زاوية القبلة من الشمال',
                                style: TextStyle(fontSize: 11, color: secondaryTxt),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Fixed Target Pointer + Rotating Compass Dial
            Center(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isAligned
                          ? accentEmerald.withOpacity(0.15)
                          : AppConstants.activeSurface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAligned ? accentEmerald : AppConstants.borderColor(context),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAligned
                              ? Icons.check_circle
                              : (delta >= 0 ? Icons.turn_right : Icons.turn_left),
                          size: 16,
                          color: isAligned ? accentEmerald : primaryTxt,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          !_hasSensor
                              ? 'زاوية القبلة المحسوبة: ${qiblaBearing.round()}° من الشمال'
                              : isAligned
                                  ? 'أنت متجه نحو القبلة الآن'
                                  : (delta >= 0
                                      ? 'دُر لليمين ${delta.abs().round()}°'
                                      : 'دُر لليسار ${delta.abs().round()}°'),
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isAligned ? accentEmerald : primaryTxt,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 32,
                    color: isAligned ? accentEmerald : secondaryTxt,
                  ),
                  SizedBox(
                    width: 290,
                    height: 290,
                    child: CustomPaint(
                      painter: _CompassDialPainter(
                        headingDeg: _hasSensor ? trueHeading : 0.0,
                        qiblaBearingDeg: qiblaBearing,
                        isDark: isDark,
                        isAligned: isAligned,
                        accentColor: accentEmerald,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Heading & Accuracy Bar
            InkWell(
              onTap: _showCalibrationSheet,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppConstants.cardSurface(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _accuracy <= 1
                        ? AppConstants.tertiary.withOpacity(0.6)
                        : AppConstants.borderColor(context),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _accuracy <= 1 ? Icons.warning_amber_rounded : Icons.explore_outlined,
                      size: 18,
                      color: _accuracy <= 1 ? AppConstants.tertiary : accentEmerald,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _accuracyLabel(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryTxt,
                            ),
                          ),
                          if (_hasSensor)
                            Text(
                              'اتجاه الهاتف الحالي: ${trueHeading.round()}° • اضغط لمعايرة البوصلة',
                              style: TextStyle(fontSize: 11, color: secondaryTxt),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: secondaryTxt),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrajectoryMapPainter extends CustomPainter {
  final bool isDark;
  final Color accentColor;
  final double bearingDeg;

  _TrajectoryMapPainter({
    required this.isDark,
    required this.accentColor,
    required this.bearingDeg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF151C24), const Color(0xFF0E141A)]
            : [const Color(0xFFEFF6F3), const Color(0xFFE2EFE9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Subtle latitude/longitude grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : AppConstants.primary).withOpacity(0.06)
      ..strokeWidth = 1;
    for (double x = 24; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 24; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Place user dot and Kaaba dot meaningfully using bearing vector
    final start = Offset(size.width * 0.72, size.height * 0.34);
    final end = Offset(size.width * 0.28, size.height * 0.74);
    final ctrl = Offset(size.width * 0.48, size.height * 0.42);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);

    // Dashed curved trajectory
    final dashPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      double dist = 0.0;
      const double dashLen = 7.0;
      const double gapLen = 5.0;
      while (dist < metric.length) {
        final next = math.min(dist + dashLen, metric.length);
        canvas.drawPath(metric.extractPath(dist, next), dashPaint);
        dist += dashLen + gapLen;
      }
    }

    // User location marker
    canvas.drawCircle(start, 9, Paint()..color = accentColor.withOpacity(0.22));
    canvas.drawCircle(start, 5, Paint()..color = accentColor);

    // Miniature Kaaba marker at destination
    const kaabaSize = 16.0;
    final rect = Rect.fromCenter(center: end, width: kaabaSize, height: kaabaSize);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = const Color(0xFF181A20),
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top + 3.5, rect.width, 2.5),
      Paint()..color = const Color(0xFFD4AF37),
    );
  }

  @override
  bool shouldRepaint(covariant _TrajectoryMapPainter oldDelegate) =>
      oldDelegate.isDark != isDark ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.bearingDeg != bearingDeg;
}

class _CompassDialPainter extends CustomPainter {
  final double headingDeg;
  final double qiblaBearingDeg;
  final bool isDark;
  final bool isAligned;
  final Color accentColor;

  _CompassDialPainter({
    required this.headingDeg,
    required this.qiblaBearingDeg,
    required this.isDark,
    required this.isAligned,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;

    // Outer alignment halo
    if (isAligned) {
      canvas.drawCircle(
        center,
        radius + 10,
        Paint()
          ..color = accentColor.withOpacity(0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );
    }

    // Dial base circle
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = isDark ? const Color(0xFF1C222B) : Colors.white,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isAligned
            ? accentColor
            : (isDark ? Colors.white.withOpacity(0.14) : Colors.black.withOpacity(0.1))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isAligned ? 2.5 : 1.5,
    );

    // Rotate canvas counter-clockwise by headingDeg so North moves accurately
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-headingDeg * math.pi / 180.0);

    // Tick marks every 5 degrees
    for (int deg = 0; deg < 360; deg += 5) {
      final isMajor = deg % 30 == 0;
      final isNorth = deg == 0;
      final rad = (deg - 90) * math.pi / 180.0;
      final outerR = radius - 6;
      final innerR = isMajor ? radius - 16 : radius - 11;

      final p1 = Offset(math.cos(rad) * innerR, math.sin(rad) * innerR);
      final p2 = Offset(math.cos(rad) * outerR, math.sin(rad) * outerR);

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = isNorth
              ? accentColor
              : (isDark
                  ? Colors.white.withOpacity(isMajor ? 0.55 : 0.2)
                  : Colors.black.withOpacity(isMajor ? 0.45 : 0.15))
          ..strokeWidth = isMajor ? 2.0 : 1.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // Cardinal labels (ش / ق / ج / غ)
    const cardinals = {
      0: 'ش',
      90: 'ق',
      180: 'ج',
      270: 'غ',
    };
    for (final entry in cardinals.entries) {
      final rad = (entry.key - 90) * math.pi / 180.0;
      final labelR = radius - 32;
      final pos = Offset(math.cos(rad) * labelR, math.sin(rad) * labelR);

      final tp = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: TextStyle(
            fontSize: entry.key == 0 ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: entry.key == 0
                ? accentColor
                : (isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151)),
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      // Keep text upright relative to viewer
      canvas.rotate(headingDeg * math.pi / 180.0);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Qibla needle & custom Kaaba emblem anchored at qiblaBearingDeg
    canvas.save();
    canvas.rotate(qiblaBearingDeg * math.pi / 180.0);

    // Subtle south tail
    final tailPath = Path()
      ..moveTo(0, radius * 0.42)
      ..lineTo(-6, 0)
      ..lineTo(6, 0)
      ..close();
    canvas.drawPath(
      tailPath,
      Paint()..color = isDark ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.14),
    );

    // Primary Qibla needle pointing toward Kaaba (-Y direction)
    final needlePath = Path()
      ..moveTo(0, -(radius * 0.56))
      ..lineTo(-8, 0)
      ..lineTo(8, 0)
      ..close();
    canvas.drawPath(needlePath, Paint()..color = accentColor);

    // Custom Kaaba emblem at rim along Qibla angle
    final kaabaCenter = Offset(0, -(radius - 22));
    const kSize = 24.0;
    final kaabaRect = Rect.fromCenter(center: kaabaCenter, width: kSize, height: kSize);
    canvas.drawRRect(
      RRect.fromRectAndRadius(kaabaRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF14161B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(kaabaRect, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // Gold Kiswah band
    canvas.drawRect(
      Rect.fromLTWH(kaabaRect.left + 1, kaabaRect.top + 5, kaabaRect.width - 2, 3.2),
      Paint()..color = const Color(0xFFD4AF37),
    );

    canvas.restore();

    // Center hub pin
    canvas.drawCircle(
      Offset.zero,
      10,
      Paint()..color = isDark ? const Color(0xFF2D333B) : const Color(0xFFE5E7EB),
    );
    canvas.drawCircle(Offset.zero, 5, Paint()..color = accentColor);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) =>
      oldDelegate.headingDeg != headingDeg ||
      oldDelegate.qiblaBearingDeg != qiblaBearingDeg ||
      oldDelegate.isDark != isDark ||
      oldDelegate.isAligned != isAligned ||
      oldDelegate.accentColor != accentColor;
}

class _CalibrationSheet extends StatefulWidget {
  const _CalibrationSheet();

  @override
  State<_CalibrationSheet> createState() => _CalibrationSheetState();
}

class _CalibrationSheetState extends State<_CalibrationSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConstants.isDark(context);
    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);
    final accentColor = isDark ? const Color(0xFF10B981) : AppConstants.secondary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'معايرة البوصلة',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryTxt,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: secondaryTxt),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 170,
              height: 150,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => CustomPaint(
                  painter: _FigureEightPainter(
                    progress: _controller.value,
                    isDark: isDark,
                    accentColor: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'حرّك هاتفك في الهواء على شكل رقم 8 ثلاث مرات للوصول إلى أعلى دقة للبوصلة',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 13,
                color: primaryTxt,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('تمت المعايرة', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FigureEightPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Color accentColor;

  _FigureEightPainter({
    required this.progress,
    required this.isDark,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.height * 0.44;

    // Outer dashed ring
    for (int i = 0; i < 36; i++) {
      final a = (i * 10) * math.pi / 180.0;
      final p1 = Offset(cx + math.cos(a) * (r - 5), cy + math.sin(a) * (r - 5));
      final p2 = Offset(cx + math.cos(a) * r, cy + math.sin(a) * r);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.22)
          ..strokeWidth = 1.4,
      );
    }

    // Lemniscate figure-8 track
    final loopPath = Path();
    const aScale = 44.0;
    for (int step = 0; step <= 80; step++) {
      final t = (step / 80.0) * 2.0 * math.pi;
      final denom = 1.0 + math.sin(t) * math.sin(t);
      final x = cx + (aScale * math.cos(t)) / denom;
      final y = cy + (aScale * math.sin(t) * math.cos(t) * 1.15) / denom;
      if (step == 0) {
        loopPath.moveTo(x, y);
      } else {
        loopPath.lineTo(x, y);
      }
    }
    loopPath.close();

    canvas.drawPath(
      loopPath,
      Paint()
        ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Animated phone moving along figure-8
    final t = progress * 2.0 * math.pi;
    final denom = 1.0 + math.sin(t) * math.sin(t);
    final px = cx + (aScale * math.cos(t)) / denom;
    final py = cy + (aScale * math.sin(t) * math.cos(t) * 1.15) / denom;

    canvas.save();
    canvas.translate(px, py);
    canvas.rotate(0.45 * math.sin(t));
    final phoneRect = Rect.fromCenter(center: Offset.zero, width: 16, height: 26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(phoneRect, const Radius.circular(3.5)),
      Paint()..color = accentColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(phoneRect.deflate(2.5), const Radius.circular(2)),
      Paint()..color = isDark ? const Color(0xFF161B22) : Colors.white,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FigureEightPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}
