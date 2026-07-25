import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:thai_safe/core/config/remote_config_service.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class OpenStreetMapConfig {
  static const communityTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static String get tileUrlTemplate {
    const compileTime = String.fromEnvironment('MAP_TILE_URL');
    if (compileTime.isNotEmpty) return compileTime;
    try {
      final remote = RemoteConfigService.instance.mapTileUrl;
      return remote.isEmpty ? communityTileUrl : remote;
    } catch (_) {
      return communityTileUrl;
    }
  }

  static const userAgentPackageName = 'com.example.thai_safe';
  static const maxNativeZoom = 19;
  static final copyrightUri = Uri.parse(
    'https://www.openstreetmap.org/copyright',
  );

  static bool get usesCommunityFallback =>
      tileUrlTemplate.contains('tile.openstreetmap.org');
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
    var attribution = '© OpenStreetMap contributors';
    try {
      final remote = RemoteConfigService.instance.mapAttribution;
      if (remote.isNotEmpty) attribution = remote;
    } catch (_) {
      // Widget tests and pre-bootstrap rendering use the safe attribution.
    }
    return RichAttributionWidget(
      attributions: [
        TextSourceAttribution(
          attribution,
          onTap: () => launchUrl(OpenStreetMapConfig.copyrightUri),
        ),
      ],
    );
  }
}
