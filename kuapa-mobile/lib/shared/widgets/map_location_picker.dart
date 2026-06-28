import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../../core/constants/maps_config.dart';
import '../../core/theme/app_theme.dart';

class PickedLocation {
  final double lat;
  final double lng;
  final String address;
  const PickedLocation({required this.lat, required this.lng, required this.address});
}

class MapLocationPicker extends StatefulWidget {
  final String title;
  final PickedLocation? initialLocation;

  const MapLocationPicker({super.key, this.title = 'Pick Location', this.initialLocation});

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  GoogleMapController? _mapController;
  LatLng _pin = const LatLng(MapsConfig.defaultLat, MapsConfig.defaultLng);
  String _address = 'Tap the map to place a pin';
  bool _loadingAddress = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _pin = LatLng(widget.initialLocation!.lat, widget.initialLocation!.lng);
      _address = widget.initialLocation!.address;
    } else {
      _goToMyLocation();
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() => _pin = latlng);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latlng, MapsConfig.defaultZoom));
      await _reverseGeocode(latlng);
    } catch (_) {
      // Fall back to default Ghana center
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    if (!MapsConfig.keyConfigured) {
      setState(() => _address = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}');
      return;
    }
    setState(() => _loadingAddress = true);
    try {
      final res = await Dio().get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '${pos.latitude},${pos.longitude}',
          'key': MapsConfig.apiKey,
        },
      );
      final results = res.data['results'] as List?;
      if (results != null && results.isNotEmpty) {
        setState(() => _address = results[0]['formatted_address'] as String);
      } else {
        setState(() => _address = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}');
      }
    } catch (_) {
      setState(() => _address = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}');
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  void _onTap(LatLng pos) {
    setState(() => _pin = pos);
    _reverseGeocode(pos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          _locating
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
                )
              : IconButton(
                  icon: const Icon(Icons.my_location),
                  tooltip: 'Go to my location',
                  onPressed: _goToMyLocation,
                ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _pin, zoom: MapsConfig.defaultZoom),
            onMapCreated: (c) => _mapController = c,
            onTap: _onTap,
            markers: {
              Marker(
                markerId: const MarkerId('pin'),
                position: _pin,
                draggable: true,
                onDragEnd: (pos) {
                  setState(() => _pin = pos);
                  _reverseGeocode(pos);
                },
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),

          // Instruction banner at top
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6)],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 16, color: AppTheme.primary),
                  SizedBox(width: 6),
                  Text('Tap map or drag the pin to select location',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),

          // Address + confirm at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_pin, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _loadingAddress
                            ? const LinearProgressIndicator()
                            : Text(_address,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadingAddress
                          ? null
                          : () => Navigator.pop(
                                context,
                                PickedLocation(lat: _pin.latitude, lng: _pin.longitude, address: _address),
                              ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Use This Location'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
