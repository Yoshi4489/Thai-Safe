import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:thai_safe/core/maps/open_street_map.dart';

class IncidentMapPicker extends StatefulWidget {
  final LatLng initialLocation;
  final ValueChanged<LatLng> onLocationChanged;

  const IncidentMapPicker({
    super.key,
    required this.initialLocation,
    required this.onLocationChanged,
  });

  @override
  State<IncidentMapPicker> createState() => _IncidentMapPickerState();
}

class _IncidentMapPickerState extends State<IncidentMapPicker> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  late LatLng _selectedLocation;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _selectLocation(LatLng location, {bool moveMap = false}) {
    setState(() => _selectedLocation = location);
    widget.onLocationChanged(location);

    if (moveMap && _isMapReady) {
      _mapController.move(location, 16);
    }
  }

  Future<void> _searchLocation() async {
    final address = _searchController.text.trim();
    if (address.isEmpty) return;

    try {
      final locations = await geo.locationFromAddress(address);
      if (locations.isEmpty || !mounted) return;

      final first = locations.first;
      _selectLocation(LatLng(first.latitude, first.longitude), moveMap: true);
      FocusScope.of(context).unfocus();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ไม่พบสถานที่: $address')));
    }
  }

  Future<void> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;

    _selectLocation(
      LatLng(position.latitude, position.longitude),
      moveMap: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'ค้นหาชื่อหมู่บ้าน, ถนน หรือสถานที่...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: _searchLocation,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 0,
            ),
          ),
          onSubmitted: (_) => _searchLocation(),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 15,
                minZoom: 3,
                maxZoom: 19,
                onMapReady: () => _isMapReady = true,
                onTap: (_, point) => _selectLocation(point),
                onLongPress: (_, point) => _selectLocation(point),
              ),
              children: [
                const OpenStreetMapTileLayer(),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                    ),
                  ],
                ),
                const OpenStreetMapAttribution(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Row(
          children: [
            Icon(Icons.touch_app, size: 16, color: Colors.black54),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'แตะแผนที่เพื่อเลือกจุดเกิดเหตุ',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
