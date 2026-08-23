import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  Position? _currentPosition;
  List<Clinic> _clinics = [];
  bool _isLoading = true;
  String? _errorMessage;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final position = await LocationService.determinePosition();
      setState(() {
        _currentPosition = position;
      });

      final clinics = await LocationService.getNearbyClinics(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _clinics = clinics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Consult Dermatologist"),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _fetchDoctors();
                          },
                          child: const Text("Retry"),
                        )
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      TextField(
                        decoration: InputDecoration(
                          hintText: "Search doctors by name or specialization...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Map View
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _currentPosition == null 
                            ? const Center(child: Text("Location not available"))
                            : FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                  initialZoom: 13.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.dermasense',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      // User location
                                      Marker(
                                        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                        width: 40,
                                        height: 40,
                                        child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                                      ),
                                      // Clinics
                                      ..._clinics.map((c) => Marker(
                                        point: LatLng(c.lat, c.lon),
                                        width: 40,
                                        height: 40,
                                        child: Icon(Icons.local_hospital, color: Theme.of(context).colorScheme.primary, size: 30),
                                      )),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        _clinics.isEmpty ? "No specialists found nearby" : "Available Specialists (${_clinics.length})",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      ..._clinics.map((clinic) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildDoctorCard(
                          context,
                          clinic.name,
                          clinic.type,
                          "Location: ${clinic.address}",
                        ),
                      )),
                      
                      // Fallback dummy data if nothing found
                      if (_clinics.isEmpty) ...[
                        _buildDoctorCard(context, "Dr. Emily Chen (Demo)", "Dermatologist", "12 Years Exp."),
                        const SizedBox(height: 12),
                        _buildDoctorCard(context, "Dr. Marcus Johnson (Demo)", "Cosmetic Dermatologist", "8 Years Exp."),
                      ]
                    ],
                  ),
                ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, String name, String spec, String details) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spec,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(child: Text(details, style: TextStyle(color: Colors.grey[600], fontSize: 12))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Calling clinic...")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        child: const Text("Contact"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
