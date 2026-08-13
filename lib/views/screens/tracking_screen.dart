import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/order_status_utils.dart';
import '../../data/app_repository.dart';
import '../../data/mock_data.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/providers.dart';
import '../../services/api_config.dart';
import '../../theme.dart';
import '../widgets/common.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  final _adController = PageController(viewportFraction: 0.86);
  int _adPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = ref.read(appControllerProvider);
      if (app.activeOrderId != null) {
        app.startLiveTracking(app.activeOrderId!);
      } else {
        app.fetchTracking();
      }
    });
  }

  @override
  void dispose() {
    _adController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final order = app.trackingOrder;
    final status = OrderStatusUtils.normalize(app.trackingStatus);
    final headline = OrderStatusUtils.headline(
      status,
      hasDeliveryPartner: app.trackingHasPartner,
    );
    final subtitle = OrderStatusUtils.subtitle(
      status,
      hasDeliveryPartner: app.trackingHasPartner,
    );
    final eta = app.trackingDisplayEta;
    final stepIdx = OrderStatusUtils.stepIndex(
      status,
      hasDeliveryPartner: app.trackingHasPartner,
    );
    final restaurantName = order?.displayName.isNotEmpty == true
        ? order!.displayName
        : app.restaurant.name;
    final when = OrderStatusUtils.formatTrackingDateTime(order?.createdAt);
    final itemCount = order?.itemCount ?? 0;
    final itemLabel = itemCount == 1
        ? '1 item'
        : (itemCount > 0 ? '$itemCount items' : (order?.items.isNotEmpty == true ? order!.items : 'Your order'));
    final orderNumber = order?.orderNumber ?? '';
    final delay = app.delayMessage;
    final address = (app.deliveryAddressLine != null &&
            app.deliveryAddressLine!.isNotEmpty)
        ? app.deliveryAddressLine!
        : homeAddress;
    final riderLine = app.riderName != null && app.riderName!.isNotEmpty
        ? '${app.riderName} is on the way'
        : subtitle;

    return Container(
      color: const Color(0xFFF2EFEC),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 320,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _LiveMap(
                        riderLat: app.riderLat,
                        riderLng: app.riderLng,
                        showRider: status == 'ACCEPTED' ||
                            status == 'PICKED_UP' ||
                            status == 'ON_THE_WAY' ||
                            status == 'ARRIVED',
                      ),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleIconButton(
                                icon: Icons.arrow_back_ios_new,
                                onTap: () {
                                  app.stopLiveTracking();
                                  app.toOrders();
                                },
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      restaurantName,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.body(
                                        size: 16,
                                        weight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      [
                                        if (orderNumber.isNotEmpty)
                                          '#$orderNumber',
                                        if (when.isNotEmpty) when,
                                        itemLabel,
                                      ].join(' · '),
                                      textAlign: TextAlign.center,
                                      style: AppText.body(
                                        size: 11.5,
                                        weight: FontWeight.w500,
                                        color: AppColors.bodyGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              CircleIconButton(
                                icon: Icons.more_horiz,
                                onTap: app.toggleTrackMenu,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (app.trackMenuOpen)
                        Positioned(
                          top: 60,
                          right: 16,
                          child: _TrackMenu(app: app),
                        ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (app.trackingLoading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: LinearProgressIndicator(
                              color: AppColors.accent,
                              minHeight: 2,
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        status == 'CANCELLED'
                                            ? Icons.cancel
                                            : Icons.check_circle,
                                        size: 16,
                                        color: status == 'CANCELLED'
                                            ? Colors.redAccent
                                            : AppColors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        OrderStatusUtils.label(status)
                                            .toUpperCase(),
                                        style: AppText.body(
                                          size: 12,
                                          weight: FontWeight.w800,
                                          color: status == 'CANCELLED'
                                              ? Colors.redAccent
                                              : AppColors.green,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    headline,
                                    style: AppText.display(size: 21),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    riderLine,
                                    style: AppText.body(
                                      size: 12.5,
                                      weight: FontWeight.w500,
                                      color: AppColors.bodyGrey,
                                    ),
                                  ),
                                  if (delay != null && delay.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      delay,
                                      style: AppText.body(
                                        size: 12,
                                        weight: FontWeight.w600,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (eta != null &&
                                OrderStatusUtils.isActive(status)) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '$eta',
                                      style: AppText.display(
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'mins',
                                      style: AppText.body(
                                        size: 10.5,
                                        weight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        _TrackingSteps(currentIndex: stepIdx),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1, color: AppColors.hairline),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery address',
                                    style: AppText.body(
                                      size: 14,
                                      weight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.body(
                                      size: 12,
                                      weight: FontWeight.w500,
                                      color: AppColors.bodyGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (order != null && order.items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Text(
                      order.items,
                      style: AppText.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AppColors.ink,
                        height: 1.35,
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 150,
                  child: PageView.builder(
                    controller: _adController,
                    onPageChanged: (i) => setState(() => _adPage = i),
                    itemCount: promoAds.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: PromoAdCard(
                        ad: promoAds[i],
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(promoAds.length, (i) {
                      final active = i == _adPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.accent
                              : AppColors.chipBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'ORDER DETAILS',
                        style: AppText.display(size: 14, letterSpacing: 0.5),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: AppColors.accent.withValues(alpha: 0.25),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _OrderDetailRow(
                          icon: Icons.storefront_outlined,
                          title: restaurantName,
                          subtitle: orderNumber.isNotEmpty
                              ? 'Order #$orderNumber'
                              : restAddressGeneric,
                          actionIcon: Icons.call,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: AppColors.hairline),
                        ),
                        _OrderDetailRow(
                          icon: Icons.home_outlined,
                          title: 'Delivering to Home',
                          subtitle: address,
                          actionIcon: Icons.edit_outlined,
                        ),
                        if (order != null) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child:
                                Divider(height: 1, color: AppColors.hairline),
                          ),
                          _OrderDetailRow(
                            icon: Icons.receipt_long_outlined,
                            title: 'Total paid',
                            subtitle: '₹${order.total}',
                            actionIcon: Icons.info_outline,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        app.stopLiveTracking();
                        app.toHome();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.chipBorder,
                          width: 1.5,
                        ),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Back to home',
                        style: AppText.body(size: 14, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingSteps extends StatelessWidget {
  final int currentIndex;
  const _TrackingSteps({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final steps = OrderStatusUtils.trackingSteps;
    return Column(
      children: List.generate(steps.length, (i) {
        final done = i <= currentIndex;
        final current = i == currentIndex;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.accent : Colors.white,
                      border: Border.all(
                        color: done ? AppColors.accent : AppColors.chipBorder,
                        width: 2,
                      ),
                    ),
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: 22,
                      color: i < currentIndex
                          ? AppColors.accent
                          : AppColors.chipBorder,
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[i].title,
                      style: AppText.body(
                        size: 13,
                        weight: current ? FontWeight.w800 : FontWeight.w600,
                        color: done ? AppColors.ink : AppColors.bodyGrey,
                      ),
                    ),
                    Text(
                      steps[i].subtitle,
                      style: AppText.body(
                        size: 11.5,
                        weight: FontWeight.w500,
                        color: AppColors.bodyGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _OrderDetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final IconData actionIcon;

  const _OrderDetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppColors.paleWarmBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.body(size: 14, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppColors.bodyGrey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.avatarBg,
            shape: BoxShape.circle,
          ),
          child: Icon(actionIcon, size: 15, color: AppColors.accent),
        ),
      ],
    );
  }
}

class _TrackMenu extends StatelessWidget {
  final AppController app;
  const _TrackMenu({required this.app});

  @override
  Widget build(BuildContext context) {
    final canCancel = OrderStatusUtils.isActive(app.trackingStatus) &&
        app.trackingStatus != 'ON_THE_WAY' &&
        app.trackingStatus != 'ARRIVED' &&
        app.trackingStatus != 'PICKED_UP';

    return Material(
      color: const Color(0xFF221A1F),
      borderRadius: BorderRadius.circular(16),
      elevation: 12,
      child: SizedBox(
        width: 210,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row(Icons.info_outline, 'Info', () => app.closeTrackMenu()),
            _row(Icons.support_agent, 'Help', app.toHelp),
            if (canCancel)
              _row(Icons.cancel_outlined, 'Cancel order', () {
                app.closeTrackMenu();
                app.cancelActiveOrder();
                app.toOrders();
              }),
            _row(Icons.ios_share, 'Share', () => app.closeTrackMenu()),
            _row(Icons.edit_outlined, 'Modify Address', () {
              app.closeTrackMenu();
              AppRepository.syncAddresses();
            }, badge: 'NEW'),
          ],
        ),
      ),
    );
  }

  Widget _row(
    IconData icon,
    String label,
    VoidCallback onTap, {
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppText.body(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE85A9C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: AppText.body(
                    size: 9,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveMap extends StatelessWidget {
  final double? riderLat;
  final double? riderLng;
  final bool showRider;

  const _LiveMap({
    this.riderLat,
    this.riderLng,
    this.showRider = false,
  });

  @override
  Widget build(BuildContext context) {
    final you = LatLng(ApiConfig.lat, ApiConfig.lng);
    final hasRider = showRider && riderLat != null && riderLng != null;
    final rider = hasRider ? LatLng(riderLat!, riderLng!) : null;
    final target = rider ?? you;
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('you'),
        position: you,
        infoWindow: InfoWindow(title: ApiConfig.locationLabel),
      ),
      if (rider != null)
        Marker(
          markerId: const MarkerId('rider'),
          position: rider,
          infoWindow: const InfoWindow(title: 'Delivery partner'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
    };

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: target, zoom: 14.2),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      markers: markers,
    );
  }
}
