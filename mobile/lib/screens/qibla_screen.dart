import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/constants.dart';
import '../core/utils/qibla_calculator.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with WidgetsBindingObserver {
  static const EventChannel _compassEvents =
      EventChannel('com.moamenmoheb.adhkar_sanctuary/qibla_compass');
  static const MethodChannel _locationChannel =
      MethodChannel('com.moamenmoheb.adhkar_sanctuary/qibla_location');

  StreamSubscription<dynamic>? _compassSub;

  double? _lat;
  double? _lng;
  bool _permissionChecked = false;
  bool _hasLocationPermission = false;
  bool _gpsAttempted = false;
  bool _fetchingGps = false;

  double _declinationDeg = 0.0;
  double _magneticHeading = 0.0;
  int _accuracy = 2; // 0=unreliable, 1=low, 2=medium, 3=high, -1=none
  bool _hasSensor = true;
  bool _wasAligned = false;

  bool get _hasGpsFix => _lat != null && _lng != null;
  bool get _hasAccuracyWarning => !_hasSensor || _accuracy <= 1;
  bool get _canApplyQibla =>
      _hasLocationPermission && _hasGpsFix && !_hasAccuracyWarning;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndFetch();
    _startCompassStream();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permission and GPS automatically if user returns from App Settings
    if (state == AppLifecycleState.resumed && (!_hasLocationPermission || !_hasGpsFix)) {
      _checkPermissionAndFetch(autoRequest: false);
    }
  }

  Future<void> _checkPermissionAndFetch({bool autoRequest = true}) async {
    bool granted = false;
    try {
      granted =
          await _locationChannel.invokeMethod<bool>('hasLocationPermission') ?? false;
    } catch (_) {
      granted = false;
    }
    if (!mounted) return;
    setState(() {
      _permissionChecked = true;
      _hasLocationPermission = granted;
    });
    if (granted) {
      await _refreshGpsLocation();
    } else if (autoRequest) {
      await _refreshGpsLocation();
    }
  }

  Future<void> _updateDeclination() async {
    final lat = _lat;
    final lng = _lng;
    if (lat == null || lng == null) return;
    try {
      final decl = await _locationChannel.invokeMethod<double>('getDeclination', {
        'lat': lat,
        'lng': lng,
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
      final res =
          await _locationChannel.invokeMapMethod<String, dynamic>('getCurrentLocation');
      final bool granted =
          await _locationChannel.invokeMethod<bool>('hasLocationPermission') ?? false;
      if (!mounted) return;

      if (granted && res != null && res['lat'] != null && res['lng'] != null) {
        setState(() {
          _permissionChecked = true;
          _hasLocationPermission = true;
          _gpsAttempted = true;
          _lat = (res['lat'] as num).toDouble();
          _lng = (res['lng'] as num).toDouble();
        });
        await _updateDeclination();
      } else {
        setState(() {
          _permissionChecked = true;
          _hasLocationPermission = granted;
          _gpsAttempted = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _permissionChecked = true;
          _gpsAttempted = true;
        });
      }
    } finally {
      if (mounted) setState(() => _fetchingGps = false);
    }
  }

  Future<void> _openAppSettings() async {
    try {
      await _locationChannel.invokeMethod('openAppSettings');
    } catch (_) {}
  }

  void _startCompassStream() {
    _compassSub = _compassEvents.receiveBroadcastStream().listen(
      (event) {
        if (!mounted || event is! Map) return;
        final hasSensor = (event['hasSensor'] as bool?) ?? true;
        final heading = (event['heading'] as num?)?.toDouble() ?? 0.0;
        final accuracy = (event['accuracy'] as num?)?.toInt() ?? 2;

        final bool canApplyNow =
            _hasLocationPermission && _hasGpsFix && hasSensor && accuracy >= 2;
        if (canApplyNow) {
          final trueHeading = (heading + _declinationDeg + 360.0) % 360.0;
          final qiblaBearing = QiblaCalculator.bearingToKaaba(_lat!, _lng!);
          final delta = QiblaCalculator.signedDeltaDegrees(trueHeading, qiblaBearing);
          final alignedNow = delta.abs() <= 3.0;
          if (alignedNow && !_wasAligned) {
            HapticFeedback.mediumImpact();
          }
          _wasAligned = alignedNow;
        } else {
          _wasAligned = false;
        }

        setState(() {
          _hasSensor = hasSensor;
          _magneticHeading = heading;
          _accuracy = accuracy;
        });
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _hasSensor = false;
            _accuracy = -1;
            _wasAligned = false;
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

  String _accuracyLabel() {
    switch (_accuracy) {
      case 3:
        return 'دقة البوصلة: عالية';
      case 2:
        return 'دقة البوصلة: متوسطة';
      case 1:
        return 'دقة البوصلة: منخفضة — يجب المعايرة أولاً';
      case 0:
        return 'دقة البوصلة غير مستقرة — يجب المعايرة أولاً';
      default:
        return 'لا يوجد مستشعر بوصلة في هذا الجهاز';
    }
  }

  Widget _buildPermissionGate(BuildContext context, Color accentEmerald) {
    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppConstants.cardSurface(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppConstants.borderColor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.tertiary.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off_outlined,
                  size: 40,
                  color: AppConstants.tertiary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'صلاحية الموقع مطلوبة لتشغيل القبلة',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: primaryTxt,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'لن يتم تفعيل بوصلة القبلة دون السماح بالوصول إلى الموقع (GPS) لضمان دقة الاتجاه لموقعك الحالي.',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  color: secondaryTxt,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentEmerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: _fetchingGps
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.my_location),
                  label: const Text(
                    'السماح بصلاحية الموقع',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _fetchingGps ? null : _refreshGpsLocation,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTxt,
                    side: BorderSide(color: AppConstants.borderColor(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text('فتح إعدادات التطبيق'),
                  onPressed: _openAppSettings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGpsRequiredGate(BuildContext context, Color accentEmerald) {
    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppConstants.cardSurface(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppConstants.borderColor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.activeSurface(context),
                  shape: BoxShape.circle,
                ),
                child: _fetchingGps
                    ? CircularProgressIndicator(strokeWidth: 2.5, color: accentEmerald)
                    : const Icon(
                        Icons.gps_off,
                        size: 38,
                        color: AppConstants.tertiary,
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                _fetchingGps
                    ? 'جاري تحديد موقعك بدقة...'
                    : 'تعذر قراءة الموقع من GPS',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryTxt,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _fetchingGps
                    ? 'يرجى الانتظار لحظات حتى يتم تحديد إحداثياتك.'
                    : 'تأكد من تفعيل خدمة الموقع (GPS) على الهاتف ثم اضغط على إعادة المحاولة.',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  color: secondaryTxt,
                  height: 1.5,
                ),
              ),
              if (!_fetchingGps && _gpsAttempted) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentEmerald,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'إعادة محاولة تحديد الموقع',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _refreshGpsLocation,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConstants.isDark(context);
    final primaryTxt = AppConstants.textPrimary(context);
    final secondaryTxt = AppConstants.textSecondary(context);
    final accentEmerald = isDark ? const Color(0xFF10B981) : AppConstants.secondary;

    Widget bodyContent;
    if (!_permissionChecked || (_fetchingGps && !_hasLocationPermission)) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (!_hasLocationPermission) {
      bodyContent = _buildPermissionGate(context, accentEmerald);
    } else if (!_hasGpsFix) {
      bodyContent = _buildGpsRequiredGate(context, accentEmerald);
    } else {
      final qiblaBearing = QiblaCalculator.bearingToKaaba(_lat!, _lng!);
      final distanceKm = QiblaCalculator.distanceToKaabaKm(_lat!, _lng!);
      final trueHeading = (_magneticHeading + _declinationDeg + 360.0) % 360.0;
      final delta = QiblaCalculator.signedDeltaDegrees(trueHeading, qiblaBearing);
      final isAligned = _canApplyQibla && delta.abs() <= 3.0;

      bodyContent = ListView(
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
                              Icon(Icons.gps_fixed, size: 14, color: accentEmerald),
                              const SizedBox(width: 5),
                              Text(
                                'الموقع الحالي (GPS)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTxt,
                                ),
                              ),
                            ],
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
                              _canApplyQibla ? '${qiblaBearing.round()}°' : '--°',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _canApplyQibla ? accentEmerald : AppConstants.tertiary,
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

          const SizedBox(height: 20),

          // 2. Accuracy Warning Guard OR Live Compass
          if (_hasAccuracyWarning)
            _CalibrationInlineCard(
              hasSensor: _hasSensor,
              accuracyLabel: _accuracyLabel(),
            )
          else ...[
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
                          isAligned
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
                        headingDeg: trueHeading,
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
                  border: Border.all(color: AppConstants.borderColor(context)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.explore_outlined,
                      size: 18,
                      color: accentEmerald,
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
                          Text(
                            'اتجاه الهاتف الحالي: ${trueHeading.round()}° • اضغط لعرض طريقة المعايرة',
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
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'اتجاه القبلة',
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (_hasLocationPermission)
            IconButton(
              icon: _fetchingGps
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              tooltip: 'تحديث الموقع عبر GPS',
              onPressed: _fetchingGps ? null : _refreshGpsLocation,
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'معايرة البوصلة',
            onPressed: _showCalibrationSheet,
          ),
        ],
      ),
      body: SafeArea(child: bodyContent),
    );
  }
}

class _CalibrationInlineCard extends StatefulWidget {
  final bool hasSensor;
  final String accuracyLabel;

  const _CalibrationInlineCard({
    required this.hasSensor,
    required this.accuracyLabel,
  });

  @override
  State<_CalibrationInlineCard> createState() => _CalibrationInlineCardState();
}

class _CalibrationInlineCardState extends State<_CalibrationInlineCard>
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.cardSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.tertiary.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.tertiary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: AppConstants.tertiary),
                const SizedBox(width: 6),
                Text(
                  widget.accuracyLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.tertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (widget.hasSensor) ...[
            SizedBox(
              width: 180,
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
              'لن يتم عرض اتجاه القبلة أثناء ضعف دقة البوصلة',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryTxt,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'حرّك هاتفك في الهواء على شكل رقم 8 ثلاث مرات بعيداً عن المعادن حتى ترتفع الدقة تلقائياً.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12,
                color: secondaryTxt,
                height: 1.5,
              ),
            ),
          ] else ...[
            const Icon(Icons.sensors_off, size: 46, color: AppConstants.tertiary),
            const SizedBox(height: 12),
            Text(
              'تعذر تشغيل بوصلة القبلة',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: primaryTxt,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'هذا الجهاز لا يدعم مستشعر البوصلة المغناطيسية اللازم لتحديد الاتجاه بدقة.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12,
                color: secondaryTxt,
              ),
            ),
          ],
        ],
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

    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : AppConstants.primary).withOpacity(0.06)
      ..strokeWidth = 1;
    for (double x = 24; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 24; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final start = Offset(size.width * 0.72, size.height * 0.34);
    final end = Offset(size.width * 0.28, size.height * 0.74);
    final ctrl = Offset(size.width * 0.48, size.height * 0.42);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);

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

    canvas.drawCircle(start, 9, Paint()..color = accentColor.withOpacity(0.22));
    canvas.drawCircle(start, 5, Paint()..color = accentColor);

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

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-headingDeg * math.pi / 180.0);

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
      canvas.rotate(headingDeg * math.pi / 180.0);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    canvas.save();
    canvas.rotate(qiblaBearingDeg * math.pi / 180.0);

    final tailPath = Path()
      ..moveTo(0, radius * 0.42)
      ..lineTo(-6, 0)
      ..lineTo(6, 0)
      ..close();
    canvas.drawPath(
      tailPath,
      Paint()..color = isDark ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.14),
    );

    final needlePath = Path()
      ..moveTo(0, -(radius * 0.56))
      ..lineTo(-8, 0)
      ..lineTo(8, 0)
      ..close();
    canvas.drawPath(needlePath, Paint()..color = accentColor);

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
    canvas.drawRect(
      Rect.fromLTWH(kaabaRect.left + 1, kaabaRect.top + 5, kaabaRect.width - 2, 3.2),
      Paint()..color = const Color(0xFFD4AF37),
    );

    canvas.restore();

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
                child: const Text('إغلاق', style: TextStyle(fontWeight: FontWeight.bold)),
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
