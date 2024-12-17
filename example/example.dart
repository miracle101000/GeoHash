import 'package:flutter_geo_hash/flutter_geo_hash.dart';

void main() {
  // Create an instance of MyGeoHash
  final geoHash = MyGeoHash();

  // Example 1: Validate a GeoPoint
  try {
    final point = GeoPoint(37.7749, -122.4194); // San Francisco
    geoHash.validateLocation(point);
    print('Valid GeoPoint: $point');
  } catch (e) {
    print('Invalid GeoPoint: $e');
  }

  // Example 2: Generate a geohash for a location
  final point = GeoPoint(37.7749, -122.4194); // San Francisco
  final hash = geoHash.geoHashForLocation(point, precision: 8);
  print('Geohash for $point: $hash');

  // Example 3: Calculate distance between two locations
  final pointA = GeoPoint(37.7749, -122.4194); // San Francisco
  final pointB = GeoPoint(34.0522, -118.2437); // Los Angeles
  final distance = geoHash.distanceBetween(pointA, pointB);
  print('Distance between $pointA and $pointB: ${distance.toStringAsFixed(2)} km');

  // Example 4: Wrap a longitude to [-180, 180] range
  final wrappedLongitude = geoHash.wrapLongitude(190.0);
  print('Wrapped Longitude: $wrappedLongitude');

  // Example 5: Calculate bounding box for a given GeoPoint and radius
  final center = GeoPoint(37.7749, -122.4194); // San Francisco
  final radius = 5000.0; // 5 km radius
  final boundingBox = geoHash.boundingBoxCoordinates(center, radius);
  print('Bounding Box for $center with radius $radius: $boundingBox');
}
