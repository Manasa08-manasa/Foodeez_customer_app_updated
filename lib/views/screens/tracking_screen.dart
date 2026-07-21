import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      ref.read(appControllerProvider).fetchTracking();
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
    final rest = app.restaurant;
    final itemCount = app.cartCount;
    final itemLabel = itemCount == 1 ? '1 item' : '$itemCount items';

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
                      const _LiveMap(),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleIconButton(icon: Icons.arrow_back_ios_new, onTap: app.toOrders),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      rest.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.body(size: 16, weight: FontWeight.w800),
                                    ),
                                    Text('01:59 AM · $itemLabel', style: AppText.body(size: 11.5, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              CircleIconButton(icon: Icons.more_horiz, onTap: app.toggleTrackMenu),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: GestureDetector(
                          onTap: () {},
                          child: Column(
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.cardBorder, width: 2),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.workspace_premium_outlined, color: AppColors.accent, size: 28),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(6)),
                                child: Text('EXPLORE', style: AppText.body(size: 8.5, weight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
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
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle, size: 16, color: AppColors.green),
                                      const SizedBox(width: 6),
                                      Text('ON TIME', style: AppText.body(size: 12, weight: FontWeight.w800, color: AppColors.green, letterSpacing: 0.5)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Out for delivery', style: AppText.display(size: 21)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rider Imran is 1.2 km away, arriving soon',
                                    style: AppText.body(size: 12.5, weight: FontWeight.w500, color: AppColors.bodyGrey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  Text('12', style: AppText.display(size: 20, color: Colors.white)),
                                  Text('mins', style: AppText.body(size: 10.5, weight: FontWeight.w700, color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1, color: AppColors.hairline),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Address & instructions', style: AppText.body(size: 14, weight: FontWeight.w800)),
                                        const Icon(Icons.chevron_right, size: 18, color: AppColors.bodyGrey),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('Landmark: tender cuts lane', style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.bodyGrey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'High demand! Your order will be assigned to the next available partner.',
                          style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.ink, height: 1.35),
                        ),
                      ),
                    ],
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
                      child: PromoAdCard(ad: promoAds[i], width: double.infinity),
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
                          color: active ? AppColors.accent : AppColors.chipBorder,
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
                      Text('ORDER DETAILS', style: AppText.display(size: 14, letterSpacing: 0.5)),
                      const SizedBox(width: 10),
                      Expanded(child: Container(height: 2, color: AppColors.accent.withValues(alpha: 0.25))),
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
                          title: rest.name,
                          subtitle: restAddressGeneric,
                          actionIcon: Icons.call,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: AppColors.hairline),
                        ),
                        _OrderDetailRow(
                          icon: Icons.home_outlined,
                          title: 'Delivering to Home',
                          subtitle: homeAddress,
                          actionIcon: Icons.edit_outlined,
                        ),
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
                      onPressed: app.toHome,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.chipBorder, width: 1.5),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Back to home', style: AppText.body(size: 14, weight: FontWeight.w700)),
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
          decoration: BoxDecoration(color: AppColors.paleWarmBg, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.body(size: 14, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 12, weight: FontWeight.w500, color: AppColors.bodyGrey)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: AppColors.avatarBg, shape: BoxShape.circle),
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

  Widget _row(IconData icon, String label, VoidCallback onTap, {String? badge}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppText.body(size: 13.5, weight: FontWeight.w600, color: Colors.white))),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFE85A9C), borderRadius: BorderRadius.circular(6)),
                child: Text(badge, style: AppText.body(size: 9, weight: FontWeight.w800, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveMap extends StatelessWidget {
  const _LiveMap();

  @override
  Widget build(BuildContext context) {
    final target = LatLng(ApiConfig.lat, ApiConfig.lng);
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: target, zoom: 14.2),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      markers: {
        Marker(
          markerId: const MarkerId('you'),
          position: target,
          infoWindow: InfoWindow(title: ApiConfig.locationLabel),
        ),
      },
    );
  }
}
