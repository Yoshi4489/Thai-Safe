import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

class IncidentMapPicker extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng) onLocationChanged;

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
  late LatLng _selectedLocation;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _searchLocation() async {
    String address = _searchController.text.trim();
    if (address.isEmpty) return;

    try {
      List<geo.Location> locations = await geo.locationFromAddress(address);
      if (locations.isNotEmpty) {
        geo.Location first = locations.first;
        LatLng newPos = LatLng(first.latitude, first.longitude);

        setState(() => _selectedLocation = newPos);
        widget.onLocationChanged(newPos); // ส่งค่ากลับไปหน้าหลัก

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: newPos, zoom: 16)),
        );
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ไม่พบสถานที่: $address')));
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() => _selectedLocation = LatLng(position.latitude, position.longitude));
      widget.onLocationChanged(_selectedLocation);
      _mapController?.animateCamera(CameraUpdate.newLatLng(_selectedLocation));
    }
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          ),
          onSubmitted: (_) => _searchLocation(),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: 15),
              onMapCreated: (c) => _mapController = c,
              onTap: (pos) {
                setState(() => _selectedLocation = pos);
                widget.onLocationChanged(pos);
              },
              markers: {
                Marker(
                  markerId: const MarkerId('m'),
                  position: _selectedLocation,
                  draggable: true,
                  onDragEnd: (newPos) {
                    setState(() => _selectedLocation = newPos);
                    widget.onLocationChanged(newPos);
                  },
                )
              },
            ),
          ),
        ),
      ],
    );
  }
}