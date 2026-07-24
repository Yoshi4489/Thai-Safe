import 'package:flutter_test/flutter_test.dart';
import 'package:thai_safe/core/maps/open_street_map.dart';

void main() {
  test('uses an OpenStreetMap-compatible provider by default', () {
    expect(
      OpenStreetMapConfig.tileUrlTemplate,
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
    expect(
      OpenStreetMapConfig.copyrightUri,
      Uri.parse('https://www.openstreetmap.org/copyright'),
    );
    expect(OpenStreetMapConfig.userAgentPackageName, isNotEmpty);
  });
}
