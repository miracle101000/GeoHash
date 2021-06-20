# GeoHash Flutter

<a href="https://pub.dev/packages/flutter_geo_hash"><img src="https://img.shields.io/pub/v/flutter_geo_hash.svg" alt="Pub"></a>

[Firebase Solutions Geoqueries](https://firebase.google.com/docs/firestore/solutions/geoqueries)

Geohash is a system for encoding a `(latitude, longitude)` pair into a single Base32 string. In the Geohash system the world is divided into a rectangular grid. Each character of a Geohash string specifies one of 32 subdivisions of the prefix hash. For example the Geohash `abcd` is one of 32 four-character hashes fully contained within the larger Geohash `abc`.

The longer the shared prefix between two hashes, the closer they are to each other. For example `abcdef` is closer to `abcdeg` than `abcdff`. However the converse is not true! Two areas may be very close to each other while having very different Geohashes:

<img width="302" alt="Screen Shot 2021-06-20 at 1 58 09 PM" src="https://user-images.githubusercontent.com/83901702/122663789-8e411f00-d1cf-11eb-9a84-c05246d97a0d.png">
```dart
// Compute the GeoHash for a lat/lng point
double lat = 51.5074;
double lng = 0.1278;
MyGeoHash myGeoHash = MyGeoHash();

String hash = geofire.geohashForLocation(GeoPoint(lat, lng));

// Add the hash and the lat/lng to the document. We will use the hash
// for queries and the lat/lng for distance comparisons.
CollectionReference londonRef = FirebaseFirestore.instance.collection('cities').doc('LON');
londonRef.update({
'geohash': hash,
'lat': lat,
'lng': lng
}).then((){
// ...
});

// Find cities within 50km of London
GeoPoint center = GeoPoint(51.5074, 0.1278);
double radiusInM = 50 \* 1000;

// Each item in 'bounds' represents a startAt/endAt pair. We have to issue
// a separate query for each pair. There can be up to 9 pairs of bounds
// depending on overlap, but in most cases there are 4.
List<List<String>> bounds = geofire.geohashQueryBounds(center, radiusInM);
List<Future> futures = [];
for (List<String> b of bounds) {
var q = FirebaseFirestore.instance.collection('cities')
.orderBy('geohash')
.startAt([b[0]])
.endAt([b[1]]);
futures.add(q.get());
}

// Collect all the query results together into a single list
await Future.wait(futures).then((snapshots){
var matchingDocs = [];

for (var snap of snapshots) {
for (var doc of snap.docs) {
var lat = doc['lat'];
var lng = doc['lng'];

      // We have to filter out a few false positives due to GeoHash
      // accuracy, but most will match
      double distanceInKm = myGeoHash.distanceBetween(GeoPoint(lat, lng), center);
      double distanceInM = distanceInKm * 1000;
      if (distanceInM <= radiusInM) {
        matchingDocs.add(doc);
      }
    }

}
return matchingDocs;
<<<<<<< HEAD
}).then((matchingDocs){
// Process the matching documents
// ...
});

```

# Limitations

Using Geohashes for querying locations gives us new capabilities, but comes with its own set of limitations:

False Positives - querying by Geohash is not exact, and you have to filter out false-positive results on the client side. These extra reads add cost and latency to your app.

Edge Cases - this query method relies on estimating the distance between lines of longitude/latitude. The accuracy of this estimate decreases as points get closer to the North or South Pole which means Geohash queries have more false positives at extreme latitudes.
=======
}).then((matchingDocs) => {
  // Process the matching documents
  // ...
});

```

> > > > > > > 22da765 (Update README.md)
