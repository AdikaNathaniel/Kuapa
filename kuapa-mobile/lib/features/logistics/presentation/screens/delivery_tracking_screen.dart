import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/maps_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.pow(math.sin(dLng / 2), 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

class DeliveryTrackingScreen extends StatefulWidget {
  final String requestId;
  const DeliveryTrackingScreen({super.key, required this.requestId});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  Timer? _pollTimer;
  Map<String, dynamic>? _request;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetch());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final res = await ApiClient.instance
          .get('${ApiConstants.transportRequests}/${widget.requestId}');
      final data = res.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _request = data;
          _loading = false;
          _error = null;
        });
        final s = data['status']?.toString() ?? '';
        if (s == 'DELIVERED' || s == 'CANCELLED') _pollTimer?.cancel();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Delivery')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Request not found', style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final req        = _request!;
    final assignment = req['assignment'] as Map<String, dynamic>?;
    final status     = req['status']?.toString() ?? 'PENDING';

    final pickupLat      = (req['pickupLat']      as num?)?.toDouble();
    final pickupLng      = (req['pickupLng']      as num?)?.toDouble();
    final deliveryLat    = (req['deliveryLat']    as num?)?.toDouble();
    final deliveryLng    = (req['deliveryLng']    as num?)?.toDouble();
    final transporterLat = (assignment?['currentLat'] as num?)?.toDouble();
    final transporterLng = (assignment?['currentLng'] as num?)?.toDouble();

    double? distRemaining;
    int?    etaMinutes;
    if (transporterLat != null && deliveryLat != null) {
      distRemaining = _haversineKm(
          transporterLat, transporterLng!, deliveryLat, deliveryLng!);
      etaMinutes = (distRemaining / 40 * 60).round(); // ~40 km/h Ghana road avg
    }

    final center = transporterLat != null
        ? LatLng(transporterLat, transporterLng!)
        : (pickupLat != null
            ? LatLng(pickupLat, pickupLng!)
            : const LatLng(MapsConfig.defaultLat, MapsConfig.defaultLng));

    final markers  = <Marker>{};
    final polylines = <Polyline>{};

    if (pickupLat != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(pickupLat, pickupLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup', snippet: req['pickupAddress']?.toString()),
      ));
    }
    if (deliveryLat != null) {
      markers.add(Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(deliveryLat, deliveryLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Delivery', snippet: req['deliveryAddress']?.toString()),
      ));
    }
    if (transporterLat != null) {
      markers.add(Marker(
        markerId: const MarkerId('transporter'),
        position: LatLng(transporterLat, transporterLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: assignment?['transporterName']?.toString() ?? 'Transporter',
          snippet: 'Current position',
        ),
      ));
    }
    if (pickupLat != null && deliveryLat != null) {
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: [LatLng(pickupLat, pickupLng!), LatLng(deliveryLat, deliveryLng!)],
        color: AppTheme.primary,
        width: 3,
        patterns: [PatternItem.dash(15), PatternItem.gap(8)],
      ));
    }
    // Line from transporter → delivery when in transit
    if (transporterLat != null && deliveryLat != null) {
      polylines.add(Polyline(
        polylineId: const PolylineId('progress'),
        points: [LatLng(transporterLat, transporterLng!), LatLng(deliveryLat, deliveryLng!)],
        color: Colors.blue.shade400,
        width: 2,
        patterns: [PatternItem.dot, PatternItem.gap(6)],
      ));
    }

    final isLive = status == 'IN_TRANSIT' || status == 'PICKED_UP';
    final isTerminal = status == 'DELIVERED' || status == 'CANCELLED';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Delivery'),
        actions: [
          if (!isTerminal)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
        ],
      ),
      body: Column(
        children: [
          // Live badge
          if (isLive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primary.withValues(alpha: 0.08),
              child: const Row(
                children: [
                  SizedBox(
                    width: 10, height: 10,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Live tracking · updates every 10 s',
                    style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          // Map
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: center, zoom: MapsConfig.defaultZoom),
              markers: markers,
              polylines: polylines,
              zoomControlsEnabled: true,
              myLocationButtonEnabled: false,
            ),
          ),

          // Info panel
          _InfoPanel(
            request: req,
            assignment: assignment,
            status: status,
            distRemaining: distRemaining,
            etaMinutes: etaMinutes,
            hasTransporterLocation: transporterLat != null,
          ),
        ],
      ),
    );
  }
}

// ─── Info panel ───────────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  final Map<String, dynamic> request;
  final Map<String, dynamic>? assignment;
  final String status;
  final double? distRemaining;
  final int? etaMinutes;
  final bool hasTransporterLocation;

  const _InfoPanel({
    required this.request,
    required this.assignment,
    required this.status,
    required this.hasTransporterLocation,
    this.distRemaining,
    this.etaMinutes,
  });

  Color _statusColor(String s) => switch (s) {
        'PENDING'    => Colors.orange,
        'ACCEPTED'   => AppTheme.primaryLight,
        'PICKED_UP'  => AppTheme.primary,
        'IN_TRANSIT' => AppTheme.primary,
        'DELIVERED'  => Colors.green,
        'CANCELLED'  => Colors.red,
        _            => Colors.grey,
      };

  String _statusLabel(String s) => switch (s) {
        'PENDING'    => 'Waiting for transporter',
        'ACCEPTED'   => 'Transporter assigned — not yet collected',
        'PICKED_UP'  => 'Cargo collected — heading to delivery',
        'IN_TRANSIT' => 'On the way to destination',
        'DELIVERED'  => 'Delivered successfully ✓',
        'CANCELLED'  => 'Request cancelled',
        _            => s,
      };

  @override
  Widget build(BuildContext context) {
    final isMoving = status == 'IN_TRANSIT' || status == 'PICKED_UP';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(status),
              style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),

          // ETA chips
          if (isMoving && distRemaining != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Chip(
                    icon: Icons.straighten,
                    label: 'Distance left',
                    value: '${distRemaining!.toStringAsFixed(1)} km',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Chip(
                    icon: Icons.access_time_rounded,
                    label: 'Est. arrival',
                    value: etaMinutes! < 60
                        ? '$etaMinutes min'
                        : '${(etaMinutes! / 60).toStringAsFixed(1)} hrs',
                  ),
                ),
              ],
            ),
          ] else if (isMoving && !hasTransporterLocation) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.location_off_outlined, size: 14, color: AppTheme.textSecondary),
                SizedBox(width: 6),
                Text('Waiting for transporter to share GPS location',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ],

          // Transporter info
          if (assignment != null)
            Builder(builder: (ctx) {
              final a = assignment!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                        child: const Icon(Icons.person, color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a['transporterName']?.toString() ?? 'Transporter',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            if (a['vehicleType'] != null)
                              Text(
                                '${a['vehicleType']}  ·  ${a['vehicleNumber'] ?? ''}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      if (request['estimatedCost'] != null)
                        Text(
                          'GHS ${request['estimatedCost']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 15),
                        ),
                    ],
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Chip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
