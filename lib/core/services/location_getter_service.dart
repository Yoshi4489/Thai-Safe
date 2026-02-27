import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationGetterService {
  static Future<Position> getCurrentLocation() async{
    bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return Future.error("Location is not enabled");
    }

    LocationPermission locationPermission = await Geolocator.requestPermission(); 
    if (locationPermission == PermissionStatus.denied) {
      locationPermission = await Geolocator.requestPermission();
      if (locationPermission == PermissionStatus.denied) {
        return Future.error("Location permission denied"); 
      }
    }

    if (locationPermission == LocationPermission.deniedForever) {
      return Future.error("Location permissions are permanently denied, we can't request permission");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
  }
}