import 'package:flutter_geo_hash/flutter_geo_hash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyGeoHash Tests', () {
    final geoHash = MyGeoHash();
    const geoPoint = GeoPoint(37.7749, -122.4194); // San Francisco, CA

    test('validateLocation should throw error for invalid GeoPoint', () {
      expect(
        () => geoHash.validateLocation(null),
        throwsA(isA<String>()),
      );
    });

    test('validateLocation should not throw error for valid GeoPoint', () {
      expect(() => geoHash.validateLocation(geoPoint), returnsNormally);
    });

    test('geoHashForLocation generates correct geohash', () {
      const expectedLength = 10;
      final result = geoHash.geoHashForLocation(geoPoint, precision: expectedLength);
      expect(result.length, equals(expectedLength));
      expect(result, isA<String>());
    });

    test('degreesToRadians converts correctly', () {
      const double degrees = 180; // The angle in degrees
      const double expectedRadians = 3.141592653589793; // Approximately Pi

      final result = geoHash.degreesToRadians(degrees);
      expect(result, equals(expectedRadians));
    });

    test('metersToLongitudeDegrees calculates correctly', () {
      const double distanceInMeters = 1000; // Distance in meters
      const double latitude = 45; // Latitude for the calculation
      const double expectedResult = 0.012682816934550058;

      final result = geoHash.metersToLongitudeDegrees(distanceInMeters, latitude);
      expect(result, equals(expectedResult)); // Expect a positive degree value
    });

    test('distanceBetween calculates correct distance', () {
      const startPoint = GeoPoint(0, 0); // Start point (equator)
      const endPoint = GeoPoint(0, 1); // End point 1 longitudinal degree away
      const double expectedDistance = 111.19492664455873; // 111 km per longitudinal degree at the equator

      final distance = geoHash.distanceBetween(startPoint, endPoint);
      expect(distance, equals(expectedDistance));
    });

    test('wrapLongitude handles out-of-bound values', () {
      const double longitudeOutOfBoundsPositive = 190; // Longitude > 180
      const double longitudeOutOfBoundsNegative = -200; // Longitude < -180
      const double wrappedLongitudePositive = -170; // Expected wrapped longitude for 190
      const double wrappedLongitudeNegative = 160; // Expected wrapped longitude for -200

      expect(geoHash.wrapLongitude(longitudeOutOfBoundsPositive), equals(wrappedLongitudePositive));
      expect(geoHash.wrapLongitude(longitudeOutOfBoundsNegative), equals(wrappedLongitudeNegative));
    });
  });
}
