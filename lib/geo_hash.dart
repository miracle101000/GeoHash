import 'dart:math';

import 'package:flutter/material.dart';

class MyGeoHash {
  static const GEOHASH_PRECISION = 10;

// Characters used in location geohashes
  static const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

// The meridional circumference of the earth in meters
  static const EARTH_MERI_CIRCUMFERENCE = 40007860;

// Length of a degree latitude at the equator
  static const METERS_PER_DEGREE_LATITUDE = 110574;

// Number of bits per geohash character
  static const int BITS_PER_CHAR = 5;

// Maximum length of a geohash in bits
  static const MAXIMUM_BITS_PRECISION = 22 * BITS_PER_CHAR;

// Equatorial radius of the earth in meters
  static const EARTH_EQ_RADIUS = 6378137.0;

// The following value assumes a polar radius of
// const EARTH_POL_RADIUS = 6356752.3;
// The formulate to calculate E2 is
// E2 == (EARTH_EQ_RADIUS^2-EARTH_POL_RADIUS^2)/(EARTH_EQ_RADIUS^2)
// The exact value is used here to avoid rounding errors
  static const E2 = 0.00669447819799;

// Cutoff for rounding errors on double calculations
  static const EPSILON = 1e-12;

//  export type Geopoint = [number, number];
//  export type Geohash = string;
//  export type GeohashRange = [Geohash, Geohash];

  static log2(double x) {
    return log(x) / log(2);
  }

  /// Validates the inputted key and throws an error if it is invalid.
  ///
  /// @param key The key to be verified.

  static validateKey(String key) {
    String error;
    if (key is String == false) {
      error = 'key must be a string';
    } else if (key.length == 0) {
      error = 'key cannot be the empty string';
    } else if (1 + GEOHASH_PRECISION + key.length > 755) {
      // Firebase can only stored child paths up to 768 characters
      // The child path for this key is at the least: 'i/<geohash>key'
      error = 'key is too long to be stored in Firebase';
    } else if (key.contains('/[\[\].#\$\/\u0000-\u001F\u007F]/')) {
      // Firebase does not allow node keys to contain the following characters
      error =
          "key cannot contain any of the following characters: . # /\$ ] [ /";
    }

    if (error != null) {
      throw ('Invalid GeoFire key \'' + key + '\': ' + error);
    }
  }

  /// Validates the inputted location and throws an error if it is invalid.
  /// @param location The [latitude, longitude] pair to be verified.
  static _validateLocation(GeoPoint location) {
    String error;

    if (location is GeoPoint == false) {
      error = 'location must be of type GeoPoint';
    } else if (location == null) {
      error = 'location cannot be null';
    } else {
      double latitude = location.latitude;
      double longitude = location.longitude;

      if (latitude is double != true || latitude.isNaN) {
        error = 'latitude must be a number';
      } else if (latitude < -90 || latitude > 90) {
        error = 'latitude must be within the range [-90, 90]';
      } else if (longitude is double != true || longitude.isNaN) {
        error = 'longitude must be a number';
      } else if (longitude < -180 || longitude > 180) {
        error = 'longitude must be within the range [-180, 180]';
      }
    }

    if (error != null) {
      throw ('Invalid GeoFire location \'' +
          location.toString() +
          '\': ' +
          error);
    }
  }

  /// Validates the inputted geohash and throws an error if it is invalid.
  ///  @param geohash The geohash to be validated.
  static _validateGeoHash(String geohash) {
    String error;

    if (geohash is String == false) {
      error = 'geohash must be a string';
    } else if (geohash.length == 0) {
      error = 'geohash cannot be the empty string';
    } else {
      geohash.runes.forEach((int rune) {
        var character = new String.fromCharCode(rune);
        if (BASE32.indexOf(character) == -1) {
          error = 'geohash cannot contain \'' + character + '\'';
        }
      });
    }
    if (error != null) {
      throw ('Invalid GeoFire geohash \'' + geohash + '\': ' + error);
    }
  }

  /// Converts degrees to radians.
  /// @param degrees The number of degrees to be converted to radians.
  /// @returns The number of radians equal to the inputted number of degrees.
  static degreesToRadians(double degrees) {
    if (degrees is double == false || degrees.isNaN) {
      throw ('Error: degrees must be a number');
    }
    return (degrees * pi / 180);
  }

  /// Generates a geohash of the specified precision/string length from the  [latitude, longitude]
  /// pair, specified as an array.
  ///
  /// @param location The [latitude, longitude] pair to encode into a geohash.
  /// @param precision The length of the geohash to create. If no precision is specified, the
  /// global default is used.
  /// @returns The geohash of the inputted location.
  static String geoHashForLocation(GeoPoint location,
      {int precision = GEOHASH_PRECISION}) {
    _validateLocation(location);
    if (precision != null) {
      if (precision is int == false || precision.isNaN) {
        throw ('precision must be an integer');
      } else if (precision <= 0) {
        throw ('precision must be greater than 0');
      } else if (precision > 22) {
        throw ('precision cannot be greater than 22');
      }
    }
    var latitudeRange = {'min': -90.0, 'max': 90.0};
    var longitudeRange = {'min': -180.0, 'max': 180.0};
    String hash = '';
    int hashVal = 0;
    int bits = 0;
    bool even = true;
    while (hash.length < precision) {
      var val = even ? location.longitude : location.latitude;
      var range = even ? longitudeRange : latitudeRange;
      double mid = (range['min'] + range['max']) / 2;

      if (val > mid) {
        hashVal = (hashVal << 1) + 1;
        range['min'] = mid;
      } else {
        hashVal = (hashVal << 1) + 0;
        range['max'] = mid;
      }
      even = !even;
      if (bits < 4) {
        bits++;
      } else {
        bits = 0;
        hash += BASE32[hashVal];
        hashVal = 0;
      }
    }
    return hash;
  }

  /// Calculates the number of degrees a given distance is at a given latitude.
  ///
  /// @param distance The distance to convert.
  /// @param latitude The latitude at which to calculate.
  /// @returns The number of degrees the distance corresponds to.
  static double metersToLongitudeDegrees(double distance, double latitude) {
    var radians = degreesToRadians(latitude);
    var num = cos(radians) * EARTH_EQ_RADIUS * pi / 180;
    var denom = 1 / sqrt(1 - E2 * sin(radians) * sin(radians));
    var deltaDeg = num * denom;
    if (deltaDeg < EPSILON) {
      return distance > 0 ? 360 : 0;
    } else {
      return min(360, distance / deltaDeg);
    }
  }

  /// Calculates the bits necessary to reach a given resolution, in meters, for the longitude at a
  /// given latitude.
  ///
  /// @param resolution The desired resolution.
  /// @param latitude The latitude used in the conversion.
  /// @return The bits necessary to reach a given resolution, in meters.
  static double _longitudeBitsForResolution(
      double resolution, double latitude) {
    var degs = metersToLongitudeDegrees(resolution, latitude);
    return (degs.abs() > 0.000001) ? max(1, log2(360 / degs)) : 1;
  }

  /// Calculates the bits necessary to reach a given resolution, in meters, for the latitude.
  ///
  /// @param resolution The bits necessary to reach a given resolution, in meters.
  /// @returns Bits necessary to reach a given resolution, in meters, for the latitude.
  static double _latitudeBitsForResolution(double resolution) {
    return min(log2(EARTH_MERI_CIRCUMFERENCE / 2 / resolution),
        MAXIMUM_BITS_PRECISION.toDouble());
  }

  /// Wraps the longitude to [-180,180].
  ///
  /// @param longitude The longitude to wrap.
  /// @returns longitude The resulting longitude.
  static double _wrapLongitude(double longitude) {
    if (longitude <= 180 && longitude >= -180) {
      return longitude;
    }
    var adjusted = longitude + 180;
    if (adjusted > 0) {
      return (adjusted % 360) - 180;
    } else {
      return 180 - (-adjusted % 360);
    }
  }

  /// Calculates the maximum number of bits of a geohash to get a bounding box that is larger than a
  /// given size at the given coordinate.
  ///
  /// @param coordinate The coordinate as a [latitude, longitude] pair.
  /// @param size The size of the bounding box.
  /// @returns The number of bits necessary for the geohash.
  static int boundingBoxBits(GeoPoint point, double size) {
    var latDeltaDegrees = size / METERS_PER_DEGREE_LATITUDE;
    var latitudeNorth = min(90, point.latitude + latDeltaDegrees);
    var latitudeSouth = max(-90, point.latitude - latDeltaDegrees);
    var bitsLat = (_latitudeBitsForResolution(size)).floor() * 2;
    var bitsLongNorth =
        (_longitudeBitsForResolution(size, latitudeNorth)).floor() * 2 - 1;
    var bitsLongSouth =
        (_longitudeBitsForResolution(size, latitudeSouth)).floor() * 2 - 1;
    return [bitsLat, bitsLongNorth, bitsLongSouth, MAXIMUM_BITS_PRECISION]
        .reduce(min);
  }

  /// Calculates eight points on the bounding box and the center of a given circle. At least one
  /// geohash of these nine coordinates, truncated to a precision of at most radius, are guaranteed
  /// to be prefixes of any geohash that lies within the circle.
  ///
  /// @param center The center given as [latitude, longitude].
  /// @param radius The radius of the circle in meters.
  /// @returns The center of the box, and the eight bounding box points.
  static List<GeoPoint> boundingBoxCoordinates(GeoPoint center, double radius) {
    double latDegrees = radius / METERS_PER_DEGREE_LATITUDE;
    double latitudeNorth = min(90, center.latitude + latDegrees);
    double latitudeSouth = max(-90, center.latitude - latDegrees);
    double longDegsNorth = metersToLongitudeDegrees(radius, latitudeNorth);
    double longDegsSouth = metersToLongitudeDegrees(radius, latitudeSouth);
    double longDegs = max(longDegsNorth, longDegsSouth);
    return [
      center,
      GeoPoint(center.latitude, _wrapLongitude(center.longitude - longDegs)),
      GeoPoint(center.latitude, _wrapLongitude(center.longitude + longDegs)),
      GeoPoint(latitudeNorth, center.longitude),
      GeoPoint(latitudeNorth, _wrapLongitude(center.longitude - longDegs)),
      GeoPoint(latitudeNorth, _wrapLongitude(center.longitude + longDegs)),
      GeoPoint(latitudeSouth, center.longitude),
      GeoPoint(latitudeSouth, _wrapLongitude(center.longitude - longDegs)),
      GeoPoint(latitudeSouth, _wrapLongitude(center.longitude + longDegs)),
    ];
  }

  /// Calculates the bounding box query for a geohash with x bits precision.
  ///
  /// @param geohash The geohash whose bounding box query to generate.
  /// @param bits The number of bits of precision.
  /// @returns A [start, end] pair of geohashes.
  static List<String> geohashQuery(String geoHash, int bits) {
    _validateGeoHash(geoHash);
    var precision = (bits / BITS_PER_CHAR).ceil();
    if (geoHash.length < precision) {
      return [geoHash, geoHash + '~'];
    }
    geoHash = geoHash.substring(0, precision);
    String base = geoHash.substring(0, geoHash.length - 1);
    int lastValue = BASE32.indexOf(geoHash[geoHash.length - 1]);
    int significantBits = bits - (base.length * BITS_PER_CHAR);
    int unusedBits = (BITS_PER_CHAR - significantBits);
    // delete unused bits
    var startValue = (lastValue >> unusedBits) << unusedBits;
    var endValue = startValue + (1 << unusedBits);
    if (endValue > 31) {
      return [base + BASE32[startValue], base + '~'];
    } else {
      return [base + BASE32[startValue], base + BASE32[endValue]];
    }
  }

  /// Calculates a set of query bounds to fully contain a given circle, each being a [start, end] pair
  /// where any geohash is guaranteed to be lexicographically larger than start and smaller than end.
  ///
  /// @param center The center given as [latitude, longitude] pair.
  /// @param radius The radius of the circle.
  /// @return An array of geohash query bounds, each containing a [start, end] pair.
  static List<List<String>> geohashQueryBounds(GeoPoint center, double radius) {
    _validateLocation(center);
    int queryBits = max(1, boundingBoxBits(center, radius));
    var geohashPrecision = (queryBits / BITS_PER_CHAR).ceil();
    var coordinates = boundingBoxCoordinates(center, radius);
    var queries = coordinates.map((coordinate) {
      return geohashQuery(
              geoHashForLocation(coordinate, precision: geohashPrecision),
              queryBits)
          .toList();
    });
    List<List<String>> filteredList = [];
    var tempList =
        queries.toList().map((e) => e.toString()).toList().toSet().toList();
    for (int i = 0; i < tempList.length; i++) {
      filteredList.add([
        tempList[i].split(',')[0].replaceAll('[', '').trim(),
        tempList[i].split(',')[1].replaceAll(']', '').trim()
      ]);
    }
    return filteredList;
  }

  /// Method which calculates the distance, in kilometers, between two locations,
  /// via the Haversine formula. Note that this is approximate due to the fact that the
  /// Earth's radius varies between 6356.752 km and 6378.137 km.
  ///
  /// @param location1 The [latitude, longitude] pair of the first location.
  /// @param location2 The [latitude, longitude] pair of the second location.
  /// @returns The distance, in kilometers, between the inputted locations.
  static double distanceBetween(GeoPoint location1, GeoPoint location2) {
    _validateLocation(location1);
    _validateLocation(location2);
    var radius = 6371; // Earth's radius in kilometers
    var latDelta = degreesToRadians(location2.latitude - location1.latitude);
    var lonDelta = degreesToRadians(location2.longitude - location1.longitude);

    var a = (sin(latDelta / 2) * sin(latDelta / 2)) +
        (cos(degreesToRadians(location1.latitude)) *
            cos(degreesToRadians(location2.latitude)) *
            sin(lonDelta / 2) *
            sin(lonDelta / 2));

    var c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return radius * c;
  }
}

/// Represents a geographical point by its longitude and latitude
@immutable
class GeoPoint {
  /// Create [GeoPoint] instance.
  const GeoPoint(this.latitude, this.longitude)
      : assert(latitude >= -90 && latitude <= 90),
        assert(longitude >= -180 && longitude <= 180);

  final double latitude; // ignore: public_member_api_docs
  final double longitude; // ignore: public_member_api_docs

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => hashValues(latitude, longitude);
}
