import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapViewScreen extends StatefulWidget {
  final double? lat;
  final double? lng;
  final String? label;

  const MapViewScreen({super.key, this.lat, this.lng, this.label});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    final lat = widget.lat ?? 0.0;
    final lng = widget.lng ?? 0.0;
    final initial = LatLng(lat, lng);

    final marker = Marker(
      markerId: const MarkerId('selected'),
      position: initial,
      infoWindow: InfoWindow(title: widget.label ?? 'Selected location'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.label ?? 'Location'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: initial, zoom: 16),
        markers: {marker},
        onMapCreated: (c) => _controller = c,
        myLocationEnabled: false,
        zoomControlsEnabled: true,
      ),
    );
  }
}
