# Thai Safe

Thai Safe is a Flutter mobile application for reporting emergencies, viewing
nearby incidents, and coordinating updates between users, rescue teams, and
administrators.

## Developer team

- Palat (Yoshi)
- Waiyawat (Leo)

## Maps

The app uses [`flutter_map`](https://pub.dev/packages/flutter_map) with
OpenStreetMap tiles, so a Google Maps API key is not required.

The default tile endpoint is:

```text
https://tile.openstreetmap.org/{z}/{x}/{y}.png
```

For a production deployment, set a different OpenStreetMap-compatible tile
provider without changing the source:

```shell
flutter run --dart-define=MAP_TILE_URL=https://your-provider/{z}/{x}/{y}.png
```

OpenStreetMap attribution is displayed on every map and links to the applicable
copyright and ODbL information. When using the community tile endpoint, follow
the [OpenStreetMap tile usage policy](https://operations.osmfoundation.org/policies/tiles/).
