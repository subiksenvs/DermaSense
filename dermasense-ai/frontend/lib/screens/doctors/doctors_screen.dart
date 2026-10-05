import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ds/ds_card.dart';
import '../../widgets/ds/ds_toast.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  Position? _currentPosition;
  String _currentCity = 'Detecting...';
  String _locationStatus = 'Detecting your location...';
  bool _isGps = false;

  List<Clinic> _clinics = [];
  bool _isLoading = true;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  final List<String> _popularCities = [
    'Bangalore',
    'Mumbai',
    'Delhi',
    'Hyderabad',
    'Chennai',
    'Pune',
    'Kolkata',
    'Jaipur',
  ];

  String _selectedFilter = 'All';
  final List<String> _specialtyFilters = [
    'All',
    'Consultant',
    'Cosmetic',
    'Laser',
    'Clinical',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors({bool forceGps = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locResult = await LocationService.determinePosition();
      final position = locResult.position;

      final clinics = await LocationService.getNearbyClinics(
        position.latitude,
        position.longitude,
        searchCityName: locResult.cityName,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _currentCity = locResult.cityName;
          _isGps = locResult.isGps;
          _locationStatus = locResult.statusDescription;
          _clinics = clinics;
          _isLoading = false;
        });

        // Center map on new location
        try {
          _mapController.move(LatLng(position.latitude, position.longitude), 13.0);
        } catch (_) {}
      }
    } catch (e) {
      // Fallback safely to Bangalore
      final fallbackPos = Position(
        latitude: 12.9716,
        longitude: 77.5946,
        timestamp: DateTime.now(),
        accuracy: 100,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      final clinics = await LocationService.getNearbyClinics(
        fallbackPos.latitude,
        fallbackPos.longitude,
        searchCityName: 'Bangalore',
      );

      if (mounted) {
        setState(() {
          _currentPosition = fallbackPos;
          _currentCity = 'Bangalore';
          _isGps = false;
          _locationStatus = 'Showing Bangalore specialists (search to change)';
          _clinics = clinics;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchCity(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final pos = await LocationService.getCoordinatesForCity(clean);
    if (pos != null) {
      final clinics = await LocationService.getNearbyClinics(
        pos.latitude,
        pos.longitude,
        searchCityName: clean,
      );

      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _currentCity = clean;
          _isGps = false;
          _locationStatus = 'Showing specialists for $clean';
          _clinics = clinics;
          _isLoading = false;
        });

        try {
          _mapController.move(LatLng(pos.latitude, pos.longitude), 13.0);
        } catch (_) {}
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        DSToast.showError(context, "Could not find coordinates for '$clean'. Please try another city.");
      }
    }
  }

  List<Clinic> get _filteredClinics {
    if (_selectedFilter == 'All') return _clinics;
    return _clinics.where((c) {
      return c.type.toLowerCase().contains(_selectedFilter.toLowerCase()) ||
          c.name.toLowerCase().contains(_selectedFilter.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Consult Dermatologist"),
        actions: [
          IconButton(
            tooltip: "Detect My GPS Location",
            icon: const Icon(Icons.my_location, color: AppTheme.primary),
            onPressed: () => _fetchDoctors(forceGps: true),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text(
                    "Discovering nearby certified dermatologists...",
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.surfaceElevated,
              onRefresh: () => _fetchDoctors(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location status banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(color: AppTheme.surfaceHighlight),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isGps ? Icons.gps_fixed : Icons.location_on,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentCity.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  _locationStatus,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _fetchDoctors(forceGps: true),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              "Refresh GPS",
                              style: TextStyle(fontSize: 12, color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.space16),

                    // Search input
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchCity,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Search city (e.g., Mumbai, Delhi, London)...",
                        hintStyle: const TextStyle(color: AppTheme.textDisabled, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppTheme.textSecondary, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) => setState(() {}),
                    ),

                    const SizedBox(height: AppTheme.space12),

                    // Popular city chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _popularCities.map((city) {
                          final isSelected = _currentCity.toLowerCase() == city.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(city),
                              selected: isSelected,
                              onSelected: (_) {
                                _searchController.text = city;
                                _searchCity(city);
                              },
                              selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                              checkmarkColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              backgroundColor: AppTheme.surfaceElevated,
                              side: BorderSide(
                                color: isSelected ? AppTheme.primary : AppTheme.surfaceHighlight,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppTheme.space16),

                    // Interactive OpenStreetMap
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(color: AppTheme.surfaceHighlight),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _currentPosition == null
                          ? const Center(child: Text("Map loading..."))
                          : FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                initialZoom: 13.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.dermasense.app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    // User location pin
                                    Marker(
                                      point: LatLng(
                                        _currentPosition!.latitude,
                                        _currentPosition!.longitude,
                                      ),
                                      width: 44,
                                      height: 44,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.my_location,
                                            color: AppTheme.primary,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Specialist clinic pins
                                    ..._filteredClinics.map(
                                      (c) => Marker(
                                        point: LatLng(c.lat, c.lon),
                                        width: 36,
                                        height: 36,
                                        child: GestureDetector(
                                          onTap: () => _showDoctorDetails(context, c),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: AppTheme.secondary,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.3),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.medical_services,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),

                    const SizedBox(height: AppTheme.space20),

                    // Filter row & results count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Specialists (${_filteredClinics.length})",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          _currentCity,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.space12),

                    // Category filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _specialtyFilters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                              selectedColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              backgroundColor: AppTheme.surfaceElevated,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: AppTheme.space16),

                    // Doctor Cards List
                    if (_filteredClinics.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              const Icon(Icons.person_search, size: 48, color: AppTheme.textSecondary),
                              const SizedBox(height: 12),
                              Text(
                                "No matching specialists found in $_currentCity",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._filteredClinics.map(
                        (clinic) => Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.space12),
                          child: _buildDoctorCard(context, clinic),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Clinic clinic) {
    return DSCard(
      variant: DSCardVariant.base,
      padding: EdgeInsets.zero,
      onTap: () => _showDoctorDetails(context, clinic),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: AppTheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                // Doctor info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinic.doctorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        clinic.type,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        clinic.name,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 13, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        clinic.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            const Divider(color: AppTheme.surfaceHighlight, height: 1),
            const SizedBox(height: AppTheme.space12),

            // Metadata row (experience, fee, address)
            Row(
              children: [
                const Icon(Icons.work_outline, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  clinic.experience,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.payments_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  clinic.fee,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    clinic.address.split(',').first,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.space12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text("Call Clinic", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _callNumber(clinic.phone),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: const Text("Consult", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showDoctorDetails(context, clinic),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callNumber(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      if (mounted) {
        DSToast.showInfo(context, 'Contact: $phone');
      }
    }
  }

  Future<void> _openWeb(String website) async {
    final uri = Uri.parse(website.startsWith('http') ? website : 'https://$website');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      if (mounted) {
        DSToast.showInfo(context, 'Opening: $website');
      }
    }
  }

  void _showDoctorDetails(BuildContext context, Clinic clinic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, color: AppTheme.primary, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clinic.doctorName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          clinic.type,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          clinic.name,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: AppTheme.surfaceHighlight),
              const SizedBox(height: 12),

              // Highlights
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("Rating", "${clinic.rating.toStringAsFixed(1)} ★"),
                  _buildStatItem("Experience", clinic.experience),
                  _buildStatItem("Fee", clinic.fee),
                  _buildStatItem("Reviews", "${clinic.reviewsCount}+"),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: AppTheme.surfaceHighlight),
              const SizedBox(height: 12),

              // Location & Timings
              const Text("Location & Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: AppTheme.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clinic.address,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Text("Timings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time, color: AppTheme.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    clinic.openingHours,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Booking and Contact Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text("Call Now"),
                      onPressed: () {
                        Navigator.pop(context);
                        _callNumber(clinic.phone);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text("Book Appointment"),
                      onPressed: () {
                        Navigator.pop(context);
                        DSToast.showSuccess(
                          context,
                          "Consultation requested with ${clinic.doctorName}! The clinic will contact you shortly.",
                          duration: const Duration(seconds: 4),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: () => _openWeb(clinic.website),
                  icon: const Icon(Icons.language, size: 16, color: AppTheme.textSecondary),
                  label: Text(
                    "Visit Clinic Website",
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
