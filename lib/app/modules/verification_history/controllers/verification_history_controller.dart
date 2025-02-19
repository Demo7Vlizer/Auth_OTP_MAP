import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/storage_service.dart';
import '../../../data/models/user_model.dart';
import '../../../models/otp_record.dart';
import '../../auth/controllers/auth_controller.dart';
import 'dart:math' show min, max;

class VerificationHistoryController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final AuthController _authController = Get.find<AuthController>();
  Rx<GoogleMapController?> mapController = Rx<GoogleMapController?>(null);
  final mapType = MapType.normal.obs;
  final currentZoom = 5.0.obs;
  final isMapReady = false.obs;

  // Add this getter to access otpRecords from AuthController
  RxList<OtpRecord> get otpRecords => _authController.otpRecords;

  UserModel? getUser(String phoneNumber) {
    return _storage.getUser(phoneNumber);
  }

  void onMapCreated(GoogleMapController controller) {
    mapController.value = controller;
    isMapReady.value = true;

    // Apply custom style only for normal map type
    if (mapType.value == MapType.normal) {
      setMapStyle();
    }
  }

  Future<void> zoomIn() async {
    if (mapController.value != null) {
      currentZoom.value += 1.0;
      await mapController.value!.animateCamera(
        CameraUpdate.zoomIn(),
      );
    }
  }

  Future<void> zoomOut() async {
    if (mapController.value != null) {
      currentZoom.value -= 1.0;
      await mapController.value!.animateCamera(
        CameraUpdate.zoomOut(),
      );
    }
  }

  void resetPosition(List records) {
    if (records.isEmpty || mapController.value == null) return;

    // Find bounds of all markers
    double? minLat, maxLat, minLng, maxLng;

    for (var record in records) {
      if (record.latitude != null && record.longitude != null) {
        minLat =
            minLat == null ? record.latitude : min(minLat, record.latitude!);
        maxLat =
            maxLat == null ? record.latitude : max(maxLat, record.latitude!);
        minLng =
            minLng == null ? record.longitude : min(minLng, record.longitude!);
        maxLng =
            maxLng == null ? record.longitude : max(maxLng, record.longitude!);
      }
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat - 0.5, minLng - 0.5),
        northeast: LatLng(maxLat + 0.5, maxLng + 0.5),
      );

      mapController.value!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0),
      );
    }
  }

  void changeMapType(MapType type) {
    mapType.value = type;
    // Reapply map style if switching back to normal
    if (type == MapType.normal) {
      setMapStyle();
    }
    update();
  }

  Future<void> setMapStyle() async {
    if (mapController.value == null) return;

    try {
      const style = [
        {
          "featureType": "water",
          "elementType": "geometry",
          "stylers": [
            {"color": "#e9e9e9"},
            {"lightness": 17}
          ]
        },
        {
          "featureType": "landscape",
          "elementType": "geometry",
          "stylers": [
            {"color": "#f5f5f5"},
            {"lightness": 20}
          ]
        },
        {
          "featureType": "road.highway",
          "elementType": "geometry.fill",
          "stylers": [
            {"color": "#ffffff"},
            {"lightness": 17}
          ]
        },
        {
          "featureType": "poi",
          "elementType": "geometry",
          "stylers": [
            {"color": "#f5f5f5"},
            {"lightness": 21}
          ]
        },
        {
          "featureType": "poi.park",
          "elementType": "geometry",
          "stylers": [
            {"color": "#dedede"},
            {"lightness": 21}
          ]
        },
        {
          "elementType": "labels.text.stroke",
          "stylers": [
            {"visibility": "on"},
            {"color": "#ffffff"},
            {"lightness": 16}
          ]
        },
        {
          "elementType": "labels.text.fill",
          "stylers": [
            {"saturation": 36},
            {"color": "#333333"},
            {"lightness": 40}
          ]
        }
      ];

      await mapController.value!.setMapStyle(style.toString());
    } catch (e) {
      print('Error setting map style: $e');
    }
  }

  void fitMapToMarkers(List<Marker> markers) {
    if (markers.isEmpty || mapController.value == null) return;

    final bounds = boundsFromLatLngList(
      markers.map((m) => m.position).toList(),
    );

    mapController.value!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;

    for (LatLng latLng in list) {
      if (x0 == null || x1 == null || y0 == null || y1 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1) y1 = latLng.longitude;
        if (latLng.longitude < y0) y0 = latLng.longitude;
      }
    }

    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  @override
  void onClose() {
    mapController.value?.dispose();
    super.onClose();
  }
}
