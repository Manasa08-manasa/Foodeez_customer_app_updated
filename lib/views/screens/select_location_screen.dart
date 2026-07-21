import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../services/location_service.dart';
import '../../core/responsive.dart';
import '../../theme.dart';
import '../../data/app_repository.dart';
import '../../controllers/providers.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final Completer<GoogleMapController> _ctl = Completer();
  LatLng? _target;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPos();
  }

  Future<void> _initPos() async {
    final pos = await LocationService.currentPosition();
    final lat = pos?.latitude ?? 17.4477;
    final lng = pos?.longitude ?? 78.3913;
    setState(() {
      _target = LatLng(lat, lng);
      _loading = false;
    });
  }

  void _onCameraMove(CameraPosition p) {
    _target = p.target;
  }

  Future<void> _confirm() async {
    if (_target == null) return;
    setState(() => _loading = true);
    final resolved = await LocationService.resolveAddressDetails(_target!.latitude, _target!.longitude);
    if (!mounted) return;
    setState(() => _loading = false);
    // Open add-address details screen (Navigator push to retain main stack)
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddAddressDetailsScreen(
      latitude: _target!.latitude,
      longitude: _target!.longitude,
      resolved: resolved,
    )));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = AppResponsive.of(context).isWide;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomOffset = bottomInset + (isWide ? 40.0 : 90.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Location'),
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
      body: _loading || _target == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: _target!, zoom: 17),
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
                    child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Confirm Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
                    child: Center(child: Text('${widget.resolved.addressLine1}', style: AppText.body(size: 14))),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SelectLocationScreen()));
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
