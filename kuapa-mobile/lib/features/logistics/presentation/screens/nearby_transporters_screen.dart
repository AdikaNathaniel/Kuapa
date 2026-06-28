import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/maps_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';

final _nearbyTransportersProvider =
    FutureProvider.autoDispose.family<List<dynamic>, LatLng>((ref, center) async {
  final res = await ApiClient.instance.get(
    ApiConstants.nearbyTransporters,
    queryParams: {
      'lat': center.latitude.toString(),
      'lng': center.longitude.toString(),
      'radiusKm': MapsConfig.nearbyRadiusKm.toString(),
    },
  );
  return (res.data as List?) ?? [];
});

class NearbyTransportersScreen extends ConsumerStatefulWidget {
  final double? pickupLat;
  final double? pickupLng;
  final double? deliveryLat;
  final double? deliveryLng;

  const NearbyTransportersScreen({
    super.key,
    this.pickupLat,
    this.pickupLng,
    this.deliveryLat,
    this.deliveryLng,
  });

  @override
  ConsumerState<NearbyTransportersScreen> createState() => _NearbyTransportersScreenState();
}

class _NearbyTransportersScreenState extends ConsumerState<NearbyTransportersScreen> {
  LatLng? _center;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initCenter();
  }

  Future<void> _initCenter() async {
    LatLng center;
    if (widget.pickupLat != null && widget.pickupLng != null) {
      center = LatLng(widget.pickupLat!, widget.pickupLng!);
    } else {
      try {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          center = const LatLng(MapsConfig.defaultLat, MapsConfig.defaultLng);
        } else {
          final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
          center = LatLng(pos.latitude, pos.longitude);
        }
      } catch (_) {
        center = const LatLng(MapsConfig.defaultLat, MapsConfig.defaultLng);
      }
    }
    if (mounted) setState(() { _center = center; _loading = false; });
  }

  Set<Marker> _buildMarkers(List<dynamic> transporters) {
    final markers = <Marker>{};

    if (_center != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: _center!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Your Location / Pickup'),
      ));
    }

    if (widget.deliveryLat != null && widget.deliveryLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(widget.deliveryLat!, widget.deliveryLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Delivery Destination'),
      ));
    }

    for (final t in transporters) {
      final lat = t['currentLat'];
      final lng = t['currentLng'];
      if (lat != null && lng != null) {
        markers.add(Marker(
          markerId: MarkerId('t_${t['userId'] ?? t['id']}'),
          position: LatLng((lat as num).toDouble(), (lng as num).toDouble()),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: t['fullName'] ?? 'Transporter',
            snippet: '${(t['vehicleType'] ?? '').toString().replaceAll('_', ' ')}'
                '${t['distanceKm'] != null ? ' · ${t['distanceKm']} km' : ''}',
          ),
        ));
      }
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_center == null || widget.deliveryLat == null || widget.deliveryLng == null) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_center!, LatLng(widget.deliveryLat!, widget.deliveryLng!)],
        color: AppTheme.primary,
        width: 3,
        patterns: [PatternItem.dash(15), PatternItem.gap(8)],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _center == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Finding your location…', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    final transportersAsync = ref.watch(_nearbyTransportersProvider(_center!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Transporters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(_nearbyTransportersProvider(_center!)),
          ),
        ],
      ),
      body: transportersAsync.when(
        loading: () => Stack(
          children: [
            _buildMap(const []),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
        error: (e, _) => Column(
          children: [
            Expanded(flex: 2, child: _buildMap(const [])),
            Expanded(
              child: ErrorView(
                message: e.toString(),
                onRetry: () => ref.refresh(_nearbyTransportersProvider(_center!)),
              ),
            ),
          ],
        ),
        data: (transporters) => Column(
          children: [
            Expanded(flex: 3, child: _buildMap(transporters)),
            _BottomPanel(transporters: transporters),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(List<dynamic> transporters) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _center!, zoom: MapsConfig.defaultZoom),
      onMapCreated: (_) {},
      markers: _buildMarkers(transporters),
      polylines: _buildPolylines(),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final List<dynamic> transporters;
  const _BottomPanel({required this.transporters});

  @override
  Widget build(BuildContext context) {
    final withLocation = transporters.where((t) => t['currentLat'] != null).toList();
    final withoutLocation = transporters.where((t) => t['currentLat'] == null).toList();
    final sorted = [...withLocation, ...withoutLocation];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sorted.isEmpty
                      ? 'No transporters in this area'
                      : '${sorted.length} transporter${sorted.length == 1 ? '' : 's'} available',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  'within ${MapsConfig.nearbyRadiusKm.toInt()} km',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No available transporters nearby right now.\nPost a request — transporters in your region will be notified.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 156,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                itemCount: sorted.length,
                itemBuilder: (_, i) => _TransporterCard(t: sorted[i]),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _TransporterCard extends StatelessWidget {
  final Map<String, dynamic> t;
  const _TransporterCard({required this.t});

  String _emoji(String? type) {
    switch (type) {
      case 'MOTORCYCLE': return '🏍';
      case 'PICKUP':     return '🛻';
      case 'MINIVAN':    return '🚐';
      case 'TRUCK':      return '🚛';
      default:           return '🚗';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dist = t['distanceKm'];
    final rating = (t['rating'] as num?)?.toDouble() ?? 0.0;
    final vehicleLabel = (t['vehicleType'] ?? 'Unknown').toString().replaceAll('_', ' ');

    return Container(
      width: 158,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: Text(_emoji(t['vehicleType']), style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t['fullName'] ?? 'Transporter',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.star, size: 12, color: Colors.amber),
            const SizedBox(width: 2),
            Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Text(vehicleLabel, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          dist != null
              ? Text('~$dist km away',
                  style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600))
              : const Text('Location not shared', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          if (t['capacityKg'] != null) ...[
            const SizedBox(height: 2),
            Text('${t['capacityKg']} kg capacity',
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ],
      ),
    );
  }
}
