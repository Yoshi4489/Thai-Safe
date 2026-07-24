import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class OpenStreetMapConfig {
  static const tileUrlTemplate = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  static const userAgentPackageName = 'com.example.thai_safe';
  static const maxNativeZoom = 19;
  static final copyrightUri = Uri.parse(
    'https://www.openstreetmap.org/copyright',
  );
}

class OpenStreetMapTileLayer extends StatelessWidget {
  const OpenStreetMapTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: OpenStreetMapConfig.tileUrlTemplate,
      userAgentPackageName: OpenStreetMapConfig.userAgentPackageName,
      maxNativeZoom: OpenStreetMapConfig.maxNativeZoom,
    );
  }
}

class OpenStreetMapAttribution extends StatelessWidget {
  const OpenStreetMapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return RichAttributionWidget(
      attributions: [
        TextSourceAttribution(
          '© OpenStreetMap contributors',
          onTap: () => launchUrl(OpenStreetMapConfig.copyrightUri),
        ),
      ],
    );
  }
}
