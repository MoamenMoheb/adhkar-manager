import 'dart:math' as math;

class QiblaCalculator {
  static const double kaabaLat = 21.422487;
  static const double kaabaLng = 39.826206;

  /// Great-circle initial bearing from [lat],[lng] to the Kaaba in degrees [0, 360).
  static double bearingToKaaba(double lat, double lng) {
    const double rad = math.pi / 180.0;
    const double deg = 180.0 / math.pi;

    final double lat1 = lat * rad;
    final double lng1 = lng * rad;
    const double lat2 = kaabaLat * rad;
    const double lng2 = kaabaLng * rad;
    final double dLng = lng2 - lng1;

    final double y = math.sin(dLng) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final double bearing = (math.atan2(y, x) * deg + 360.0) % 360.0;
    return bearing;
  }

  /// Haversine surface distance from [lat],[lng] to the Kaaba in kilometers.
  static double distanceToKaabaKm(double lat, double lng) {
    const double earthRadiusKm = 6371.0088;
    const double rad = math.pi / 180.0;

    final double dLat = (kaabaLat - lat) * rad;
    final double dLng = (kaabaLng - lng) * rad;
    final double lat1 = lat * rad;
    const double lat2 = kaabaLat * rad;

    final double sinDLat = math.sin(dLat / 2.0);
    final double sinDLng = math.sin(dLng / 2.0);
    final double a = sinDLat * sinDLat +
        math.cos(lat1) * math.cos(lat2) * sinDLng * sinDLng;
    final double c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    return earthRadiusKm * c;
  }

  /// Shortest signed rotation angle from [headingDeg] to [targetDeg] in (-180, 180].
  /// Positive means rotate clockwise (right); negative means rotate counter-clockwise (left).
  static double signedDeltaDegrees(double headingDeg, double targetDeg) {
    return (targetDeg - headingDeg + 540.0) % 360.0 - 180.0;
  }
}
