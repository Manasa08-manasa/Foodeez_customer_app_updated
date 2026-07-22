import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';
import '../../data/app_repository.dart';
import '../../data/mock_data.dart';
import '../../theme.dart';
import '../../core/responsive.dart';
import 'select_location_screen.dart';
import '../../services/location_service.dart';

class AddressBookScreen extends ConsumerStatefulWidget {
  const AddressBookScreen({super.key});

  @override
  ConsumerState<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends ConsumerState<AddressBookScreen> {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AppRepository.syncAddresses();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load addresses right now.';
      });
    }
  }

  Future<void> _addAddress() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddAddressDialog(),
    );

    if (result == null) return;

    setState(() => _loading = true);
    final ok = await AppRepository.addAddress(
      label: (result['label'] ?? 'Home').toString(),
      addressLine1: (result['addressLine1'] ?? '').toString(),
      addressLine2: result['addressLine2']?.toString(),
      city: (result['city'] ?? '').toString(),
      state: (result['state'] ?? '').toString(),
      pincode: (result['pincode'] ?? '').toString(),
      landmark: result['landmark']?.toString(),
      latitude: 0,
      longitude: 0,
      isDefault: result['isDefault'] == true,
    );

    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      setState(() => _error = 'Could not save the address.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final list = List<Map<String, dynamic>>.from(addresses);

    final bottomOffset = MediaQuery.of(context).padding.bottom + (AppResponsive.of(context).isWide ? 40 : 90);
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: app.back,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder, width: 1.5),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Address book', style: AppText.display(size: 20)),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => app.push('select-location'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAddresses,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF2F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error!, style: AppText.body(size: 13, color: AppColors.red)),
                      ),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (list.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.paleWarmBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 40, color: AppColors.accent),
                            const SizedBox(height: 12),
                            Text('No saved addresses yet', style: AppText.display(size: 16)),
                            const SizedBox(height: 8),
                            Text('Add your delivery address to use it for orders.', style: AppText.body(size: 13, color: AppColors.bodyGrey)),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => app.push('select-location'),
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text('Add address manually', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...list.map((address) {
                        final isDefault = address['isDefault'] == true;
                        final summary = formatAddressSummary(address);
                        final label = (address['label'] ?? 'Address').toString();
                        return Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              app.selectAddress(address);
                              app.back();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(label, style: AppText.body(size: 15, weight: FontWeight.w700)),
                                      ),
                                      if (isDefault)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.greenPaleBg,
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text('Default', style: AppText.body(size: 11, weight: FontWeight.w700, color: AppColors.green)),
                                        ),
                                      PopupMenuButton<String>(
                                        onSelected: (v) async {
                                          final id = (address['id'] ?? address['_id'] ?? '').toString();
                                          if (v == 'edit') {
                                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddAddressDetailsScreen(
                                              latitude: (address['latitude'] ?? address['lat'] ?? 0) is num ? (address['latitude'] ?? address['lat'] ?? 0).toDouble() : double.tryParse((address['latitude'] ?? address['lat'] ?? '0').toString()) ?? 0,
                                              longitude: (address['longitude'] ?? address['lng'] ?? 0) is num ? (address['longitude'] ?? address['lng'] ?? 0).toDouble() : double.tryParse((address['longitude'] ?? address['lng'] ?? '0').toString()) ?? 0,
                                              resolved: ResolvedAddress(addressLine1: address['addressLine1']?.toString() ?? '', city: address['city']?.toString() ?? '', state: address['state']?.toString() ?? '', pincode: address['pincode']?.toString() ?? ''),
                                              addressId: id,
                                              existing: address,
                                            )));
                                          } else if (v == 'delete') {
                                            final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                                              title: const Text('Delete address'),
                                              content: const Text('Are you sure you want to delete this address?'),
                                              actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))],
                                            ));
                                            if (confirmed == true) {
                                              final id = (address['id'] ?? address['_id'] ?? '').toString();
                                              if (id.isNotEmpty) {
                                                await AppRepository.deleteAddress(id);
                                                await _loadAddresses();
                                              }
                                            }
                                          }
                                        },
                                        itemBuilder: (ctx) => const [
                                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(summary, style: AppText.body(size: 13, color: AppColors.bodyGrey)),
                                  const SizedBox(height: 8),
                                  Builder(builder: (ctx) {
                                    final lat = address['latitude'] ?? address['lat'];
                                    final lng = address['longitude'] ?? address['lng'];
                                    if (lat == null || lng == null) return const SizedBox.shrink();
                                    double? latd;
                                    double? lngd;
                                    try {
                                      latd = lat is num ? lat.toDouble() : double.tryParse(lat.toString());
                                      lngd = lng is num ? lng.toDouble() : double.tryParse(lng.toString());
                                    } catch (_) {}
                                    if (latd == null || lngd == null) return const SizedBox.shrink();
                                    return Text('Exact: ${latd.toStringAsFixed(6)}, ${lngd.toStringAsFixed(6)}', style: AppText.body(size: 12, color: AppColors.bodyGrey));
                                  }),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomOffset),
        child: FloatingActionButton.extended(
          onPressed: () => app.push('select-location'),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add address', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

String formatAddressSummary(Map<String, dynamic> address) {
  final label = (address['label'] ?? '').toString();
  final line1 = (address['addressLine1'] ?? '').toString();
  final line2 = (address['addressLine2'] ?? '').toString();
  final city = (address['city'] ?? '').toString();
  final state = (address['state'] ?? '').toString();
  final pincode = (address['pincode'] ?? '').toString();

  final parts = <String>[
    if (line1.isNotEmpty) line1,
    if (line2.isNotEmpty) line2,
    if (city.isNotEmpty) city,
    if (state.isNotEmpty) state,
    if (pincode.isNotEmpty) pincode.isNotEmpty ? ' - $pincode' : '',
  ].where((part) => part.isNotEmpty).toList();

  final detail = parts.join(', ').replaceAll(',  -', ' -');
  if (label.isNotEmpty) {
    return '$label • $detail';
  }
  return detail;
}

class _AddAddressDialog extends StatefulWidget {
  const _AddAddressDialog();

  @override
  State<_AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<_AddAddressDialog> {
  final _labelController = TextEditingController(text: 'Home');
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  bool _isDefault = false;

  @override
  void dispose() {
    _labelController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add address', style: AppText.display(size: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            TextField(
              controller: _line1Controller,
              decoration: const InputDecoration(labelText: 'Address line 1'),
            ),
            TextField(
              controller: _line2Controller,
              decoration: const InputDecoration(labelText: 'Address line 2'),
            ),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            TextField(
              controller: _stateController,
              decoration: const InputDecoration(labelText: 'State'),
            ),
            TextField(
              controller: _pincodeController,
              decoration: const InputDecoration(labelText: 'Pincode'),
            ),
            TextField(
              controller: _landmarkController,
              decoration: const InputDecoration(labelText: 'Landmark'),
            ),
            CheckboxListTile(
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value ?? false),
              title: const Text('Set as default'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'label': _labelController.text.trim(),
              'addressLine1': _line1Controller.text.trim(),
              'addressLine2': _line2Controller.text.trim(),
              'city': _cityController.text.trim(),
              'state': _stateController.text.trim(),
              'pincode': _pincodeController.text.trim(),
              'landmark': _landmarkController.text.trim(),
              'isDefault': _isDefault,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
