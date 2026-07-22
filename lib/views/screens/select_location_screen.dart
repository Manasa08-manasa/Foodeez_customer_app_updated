import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../services/location_service.dart';
import '../../services/api_config.dart';
import '../../core/responsive.dart';
import '../../theme.dart';
import '../../data/app_repository.dart';
import '../../data/mock_data.dart' as store;
import '../../controllers/providers.dart';

class SelectLocationScreen extends StatefulWidget {
  /// If true, changes the home location and returns to home. If false, proceeds to address details.
  final bool forHomeLocation;

  const SelectLocationScreen({super.key, this.forHomeLocation = false});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  late LatLng _selectedLocation;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current location
    _selectedLocation = LatLng(ApiConfig.lat, ApiConfig.lng);
  }

  void _onLocationSelected(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _showMap = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showMap) {
      return LocationMapScreen(
        initialLocation: _selectedLocation,
        forHomeLocation: widget.forHomeLocation,
        onBack: () {
          setState(() => _showMap = false);
        },
      );
    }

    return LocationSearchScreen(
      onLocationSelected: _onLocationSelected,
      forHomeLocation: widget.forHomeLocation,
    );
  }
}

/// First screen: Location search with saved places and recent searches
class LocationSearchScreen extends StatefulWidget {
  final Function(LatLng) onLocationSelected;
  final bool forHomeLocation;

  const LocationSearchScreen({
    required this.onLocationSelected,
    required this.forHomeLocation,
    super.key,
  });

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  late TextEditingController _searchController;
  List<LocationSuggestion> _suggestions = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _searching = true);
    try {
      // Mock search results - in production, use Google Places API
      final suggestions = await _searchLocationsFromGoogle(query);
      setState(() => _suggestions = suggestions);
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() => _searching = false);
    }
  }

  double _parseLatLngValue(dynamic value, [double fallback = 0.0]) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  double _resolveLat(Map<String, dynamic> item, [double fallback = 0.0]) {
    return _parseLatLngValue(item['latitude'] ?? item['lat'], fallback);
  }

  double _resolveLng(Map<String, dynamic> item, [double fallback = 0.0]) {
    return _parseLatLngValue(item['longitude'] ?? item['lng'], fallback);
  }

  Future<List<LocationSuggestion>> _searchLocationsFromGoogle(String query) async {
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'address': query,
        'key': ApiConfig.defaultBaseUrl.contains('foodeez')
            ? 'AIzaSyDW9niCHIcWO0h096PG7ES8MMw8o9cliAU'
            : 'AIzaSyDW9niCHIcWO0h096PG7ES8MMw8o9cliAU',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK') {
          final results = (json['results'] as List)
              .map((r) {
                final formatted = r['formatted_address']?.toString() ?? 'Unknown';
                final parts = formatted.split(',');
                final mainAddress = parts.isNotEmpty ? parts[0].trim() : formatted;
                final subAddress = parts.length > 1 
                    ? parts.sublist(1).join(',').trim() 
                    : '';
                
                return LocationSuggestion(
                  name: mainAddress,
                  location: LatLng(
                    _parseLatLngValue(r['geometry']?['location']?['lat']),
                    _parseLatLngValue(r['geometry']?['location']?['lng']),
                  ),
                  distance: null,
                  subtitle: subAddress.isNotEmpty ? subAddress : null,
                );
              })
              .toList();
          return results;
        }
      }
    } catch (e) {
      debugPrint('Google Geocode error: $e');
    }
    return [];
  }

  Future<void> _useCurrentLocation() async {
    final pos = await LocationService.currentPosition();
    final lat = pos?.latitude ?? ApiConfig.fallbackLat;
    final lng = pos?.longitude ?? ApiConfig.fallbackLng;
    widget.onLocationSelected(LatLng(lat, lng));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select location'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            try {
              ProviderScope.containerOf(context).read(appControllerProvider).back();
            } catch (_) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _searchLocations,
                decoration: InputDecoration(
                  hintText: 'Search for area, street, landmark…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searching 
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        ),
                      )
                    : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppColors.cardBorder, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppColors.cardBorder, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // Use current location button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _useCurrentLocation,
                icon: const Icon(Icons.location_on),
                label: const Text('Use current location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.accent,
                  side: BorderSide(color: AppColors.cardBorder, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Search results or saved places
            if (_searchController.text.isNotEmpty && _suggestions.isEmpty && !_searching)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.location_off, size: 48, color: AppColors.bodyGrey),
                      const SizedBox(height: 12),
                      Text(
                        'No results found',
                        style: AppText.body(size: 14, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try searching with different keywords',
                        style: AppText.body(size: 12, color: AppColors.bodyGrey),
                      ),
                    ],
                  ),
                ),
              )
            else if (_suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEARCH RESULTS',
                      style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_suggestions.length, (index) {
                      final suggestion = _suggestions[index];
                      return Column(
                        children: [
                          _buildLocationTile(
                            suggestion.name,
                            suggestion.location,
                            null,
                            subtitle: suggestion.subtitle,
                          ),
                          if (index < _suggestions.length - 1)
                            Divider(color: AppColors.cardBorder, height: 1),
                        ],
                      );
                    }),
                  ],
                ),
              )
            else if (_searchController.text.isEmpty)
              _buildSavedAndRecent(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile(String title, LatLng location, String? distance, {String? subtitle}) {
    return GestureDetector(
      onTap: () => widget.onLocationSelected(location),
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(size: 14, weight: FontWeight.w600),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(size: 12, color: AppColors.bodyGrey),
                      ),
                    ],
                  ],
                ),
              ),
              if (distance != null)
                Text(
                  distance,
                  style: AppText.body(size: 12, color: AppColors.bodyGrey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedAndRecent() {
    final savedAddresses = List<Map<String, dynamic>>.from(store.addresses);

    Widget buildSavedTile(Map<String, dynamic> address) {
      final label = (address['label'] ?? 'Address').toString();
      final addressParts = <String>[
        address['addressLine1']?.toString() ?? '',
        address['addressLine2']?.toString() ?? '',
        address['city']?.toString() ?? '',
      ].where((part) => part.isNotEmpty).toList();
      final subtitle = addressParts.isNotEmpty ? addressParts.join(', ') : null;
      final location = LatLng(
        _resolveLat(address, ApiConfig.lat),
        _resolveLng(address, ApiConfig.lng),
      );

      return _buildLocationTile(label, location, null, subtitle: subtitle);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saved places
          Text(
            'SAVED PLACES',
            style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey),
          ),
          const SizedBox(height: 12),
          if (savedAddresses.isNotEmpty)
            ...List.generate(savedAddresses.length, (index) {
              final address = savedAddresses[index];
              return Column(
                children: [
                  buildSavedTile(address),
                  if (index < savedAddresses.length - 1)
                    Divider(color: AppColors.cardBorder, height: 1),
                ],
              );
            })
          else
            Column(
              children: [
                _buildLocationTile(
                  'Home',
                  LatLng(17.434933, 78.388254),
                  null,
                  subtitle: 'Home location',
                ),
                Divider(color: AppColors.cardBorder, height: 1),
                _buildLocationTile(
                  'Work',
                  LatLng(17.430000, 78.450000),
                  null,
                  subtitle: 'Work location',
                ),
                Divider(color: AppColors.cardBorder, height: 1),
              ],
            ),

          const SizedBox(height: 24),

          // Recent searches
          Text(
            'RECENT SEARCHES',
            style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey),
          ),
          const SizedBox(height: 12),
          _buildLocationTile('Doctor\'s Colony', LatLng(17.430000, 78.388254), '0.4 km'),
          Divider(color: AppColors.cardBorder, height: 1),
          _buildLocationTile('Hitech City Metro', LatLng(17.435000, 78.440000), '2.1 km'),
          Divider(color: AppColors.cardBorder, height: 1),
          _buildLocationTile('Inorbit Mall', LatLng(17.450000, 78.450000), '1.8 km'),
        ],
      ),
    );
  }
}

/// Location suggestion model
class LocationSuggestion {
  final String name;
  final LatLng location;
  final String? distance;
  final String? subtitle;

  LocationSuggestion({
    required this.name,
    required this.location,
    this.distance,
    this.subtitle,
  });
}

/// Second screen: Map to fine-tune location
class LocationMapScreen extends StatefulWidget {
  final LatLng initialLocation;
  final bool forHomeLocation;
  final VoidCallback onBack;

  const LocationMapScreen({
    required this.initialLocation,
    required this.forHomeLocation,
    required this.onBack,
    super.key,
  });

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  final Completer<GoogleMapController> _ctl = Completer();
  late LatLng _target;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _target = widget.initialLocation;
  }

  void _onCameraMove(CameraPosition p) {
    _target = p.target;
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    final resolved = await LocationService.resolveAddressDetails(_target.latitude, _target.longitude);
    if (!mounted) return;

    if (widget.forHomeLocation) {
      // Update home location in ApiConfig
      ApiConfig.setLocation(
        latitude: _target.latitude,
        longitude: _target.longitude,
        label: resolved.addressLine1,
      );
      // Reset the flag
      try {
        final appController = ProviderScope.containerOf(context).read(appControllerProvider);
        appController.selectLocationForHome = false;
        // Refresh nearby restaurants with new location
        appController.refreshLocationAndNearby();
        // Return to home screen
        appController.back();
      } catch (_) {
        Navigator.of(context).pop();
      }
    } else {
      setState(() => _loading = false);
      // Open add-address details screen (Navigator push to retain main stack)
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddAddressDetailsScreen(
        latitude: _target.latitude,
        longitude: _target.longitude,
        resolved: resolved,
      )));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = AppResponsive.of(context).isWide;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomOffset = bottomInset + (isWide ? 40.0 : 90.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select location'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: widget.onBack,
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _target, zoom: 17),
            onMapCreated: (c) => _ctl.complete(c),
            onCameraMove: _onCameraMove,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          const Center(child: Icon(Icons.location_on, size: 48, color: Colors.red)),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomOffset,
            child: ElevatedButton(
              onPressed: _loading ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Confirm Location',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple add-address details screen pushed after map confirm.
class AddAddressDetailsScreen extends ConsumerStatefulWidget {
  final double latitude;
  final double longitude;
  final ResolvedAddress resolved;
  final String? addressId;
  final Map<String, dynamic>? existing;
  const AddAddressDetailsScreen({required this.latitude, required this.longitude, required this.resolved, this.addressId, this.existing, super.key});

  @override
  ConsumerState<AddAddressDetailsScreen> createState() => _AddAddressDetailsScreenState();
}

class _AddAddressDetailsScreenState extends ConsumerState<AddAddressDetailsScreen> {
  late final TextEditingController _line1Controller;
  late final TextEditingController _line2Controller;
  late final TextEditingController _landmarkController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String _label = 'Home';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _line1Controller = TextEditingController(text: widget.existing?['addressLine1']?.toString() ?? widget.resolved.addressLine1);
    _line2Controller = TextEditingController(text: widget.existing?['addressLine2']?.toString() ?? '');
    _landmarkController = TextEditingController(text: widget.existing?['landmark']?.toString() ?? '');
    _nameController = TextEditingController(text: widget.existing?['receiverName']?.toString() ?? '');
    _phoneController = TextEditingController(text: widget.existing?['receiverPhone']?.toString() ?? '');
    if (widget.existing != null) {
      _label = widget.existing?['label']?.toString() ?? _label;
    }
  }

  @override
  void dispose() {
    _line1Controller.dispose();
    _line2Controller.dispose();
    _landmarkController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = {
      'label': _label,
      'addressLine1': _line1Controller.text.trim(),
      'addressLine2': _line2Controller.text.trim(),
      'city': widget.resolved.city,
      'state': widget.resolved.state,
      'pincode': widget.resolved.pincode,
      'landmark': _landmarkController.text.trim(),
      'latitude': widget.latitude,
      'longitude': widget.longitude,
    };

    bool ok = false;
    if (widget.addressId != null && widget.addressId!.isNotEmpty) {
      ok = await AppRepository.updateAddress(widget.addressId!, data);
    } else {
      ok = await AppRepository.addAddress(
        label: data['label'].toString(),
        addressLine1: data['addressLine1'].toString(),
        addressLine2: data['addressLine2']?.toString(),
        city: data['city'].toString(),
        state: data['state'].toString(),
        pincode: data['pincode'].toString(),
        landmark: data['landmark']?.toString(),
        latitude: data['latitude'] is double ? data['latitude'] as double : double.tryParse(data['latitude'].toString()) ?? 0,
        longitude: data['longitude'] is double ? data['longitude'] as double : double.tryParse(data['longitude'].toString()) ?? 0,
        isDefault: false,
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      // refresh addresses in repo
      await AppRepository.syncAddresses();
      if (!mounted) return;
      // Pop this details route, then pop the select-location screen from app stack
      Navigator.of(context).pop();
      // Pop the select-location custom screen so user returns to address-book
      try {
        ref.read(appControllerProvider).back();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Address Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.paleWarmBg),
                    child: Center(child: Text(widget.resolved.addressLine1, style: AppText.body(size: 14))),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: OutlinedButton(
                      onPressed: () async {
                        if (mounted) {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SelectLocationScreen()));
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${widget.resolved.addressLine1}, ${widget.resolved.city}', style: AppText.body(size: 13))),
                ],
              ),
              const SizedBox(height: 8),
              Text('Exact location: ${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}', style: AppText.body(size: 12, color: AppColors.bodyGrey)),
              const SizedBox(height: 12),
              Text('Add address', style: AppText.display(size: 16)),
              const SizedBox(height: 12),
              TextField(controller: _line1Controller, decoration: const InputDecoration(labelText: 'House No. & Floor')),
              const SizedBox(height: 12),
              TextField(controller: _line2Controller, decoration: const InputDecoration(labelText: 'Building & Block No. (Optional)')),
              const SizedBox(height: 12),
              TextField(controller: _landmarkController, decoration: const InputDecoration(labelText: 'Landmark & Area Name (Optional)')),
              const SizedBox(height: 18),
              Text('Add address label', style: AppText.body(size: 14, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                ChoiceChip(label: const Text('Home'), selected: _label == 'Home', onSelected: (_) => setState(() => _label = 'Home')),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Work'), selected: _label == 'Work', onSelected: (_) => setState(() => _label = 'Work')),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Other'), selected: _label == 'Other', onSelected: (_) => setState(() => _label = 'Other')),
              ]),
              const SizedBox(height: 18),
              Text('Receiver details', style: AppText.body(size: 14, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Receiver's Name")),
              const SizedBox(height: 12),
              TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Receiver's Phone Number")),
              const SizedBox(height: 20),
              SizedBox(height: 60),
            ],
          ),
        ),
      ),
      bottomSheet: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('SAVE ADDRESS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
