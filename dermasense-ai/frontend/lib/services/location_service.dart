import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class Clinic {
  final String name;
  final double lat;
  final double lon;
  final String address;
  final String type;
  
  Clinic({
    required this.name,
    required this.lat,
    required this.lon,
    required this.address,
    required this.type,
  });
}

class LocationService {
  static Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  static Future<List<Clinic>> getNearbyClinics(double lat, double lon, {double radiusMeters = 10000}) async {
    final overpassQuery = """
      [out:json];
      (
        node["amenity"="doctors"](around:$radiusMeters,$lat,$lon);
        node["amenity"="clinic"](around:$radiusMeters,$lat,$lon);
        node["healthcare"="doctor"](around:$radiusMeters,$lat,$lon);
      );
      out body;
    """;

    try {
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: overpassQuery,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List<dynamic>;
        
        List<Clinic> clinics = [];
        for (var element in elements) {
          if (element['type'] == 'node') {
            final tags = element['tags'] ?? {};
            // Filter clinics/doctors
            final name = tags['name'] ?? tags['operator'] ?? 'Dermatologist Clinic';
            final street = tags['addr:street'] ?? '';
            final city = tags['addr:city'] ?? '';
            final address = street.isNotEmpty ? '$street, $city' : 'Address not listed';
            
            clinics.add(Clinic(
              name: name,
              lat: element['lat'].toDouble(),
              lon: element['lon'].toDouble(),
              address: address,
              type: tags['healthcare:speciality'] ?? 'Dermatologist / Skin Clinic',
            ));
          }
        }
        return clinics;
      }
    } catch (e) {
      print("Overpass API error: $e");
    }
    return [];
  }
}
