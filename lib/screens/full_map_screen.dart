import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

class FullMapScreen extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String title;

  const FullMapScreen({required this.latitude, required this.longitude, this.title = '', super.key});

  @override
  Widget build(BuildContext context) {
  // show a static tile image and open in external OSM when tapped
    return Scaffold(
      appBar: AppBar(title: Text(title.isEmpty ? 'Location' : title)),
      body: InkWell(
        onTap: () async {
          final url = Uri.parse('https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=16/$latitude/$longitude');
          // ignore: deprecated_member_use
          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
        },
        child: Image.network(
          'https://tile.openstreetmap.org/16/${_lonToTile(longitude, 16)}/${_latToTile(latitude, 16)}.png',
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, st) => Center(child: Text('Map unavailable')),
        ),
      ),
    );
  }
}

int _lonToTile(double lon, int zoom) {
  final x = ((lon + 180) / 360 * (1 << zoom)).floor();
  return x;
}

int _latToTile(double lat, int zoom) {
  final latRad = lat * math.pi / 180.0;
  final n = math.pow(2, zoom);
  final y = ((1 - (math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi)) / 2 * n).floor();
  return y;
}
