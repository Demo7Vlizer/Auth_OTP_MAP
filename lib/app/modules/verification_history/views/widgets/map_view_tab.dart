import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/verification_history_controller.dart';

class MapViewTab extends GetView<VerificationHistoryController> {
  const MapViewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        final records = authController.otpRecords;

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No locations to display',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final initialPosition = records.firstWhere(
          (record) => record.latitude != null && record.longitude != null,
          orElse: () => records.first,
        );

        return Stack(
          children: [
            Obx(() => GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      initialPosition.latitude ?? 20.5937,
                      initialPosition.longitude ?? 78.9629,
                    ),
                    zoom: 5,
                  ),
                  markers: _createMarkers(records),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: true,
                  compassEnabled: false,
                  mapType: controller.mapType.value,
                  onMapCreated: controller.onMapCreated,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                )),

            // Map Controls - Left
            Positioned(
              left: 16,
              bottom: MediaQuery.of(context).size.height * 0.2,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.layers, color: Colors.purple),
                      onPressed: () {
                        Get.bottomSheet(
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    'Map Type',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.map,
                                      color: Colors.purple),
                                  title: const Text('Normal'),
                                  selected: controller.mapType.value ==
                                      MapType.normal,
                                  onTap: () {
                                    controller.changeMapType(MapType.normal);
                                    Get.back();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.satellite,
                                      color: Colors.purple),
                                  title: const Text('Satellite'),
                                  selected: controller.mapType.value ==
                                      MapType.satellite,
                                  onTap: () {
                                    controller.changeMapType(MapType.satellite);
                                    Get.back();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.terrain,
                                      color: Colors.purple),
                                  title: const Text('Terrain'),
                                  selected: controller.mapType.value ==
                                      MapType.terrain,
                                  onTap: () {
                                    controller.changeMapType(MapType.terrain);
                                    Get.back();
                                  },
                                ),
                              ],
                            ),
                          ),
                          isDismissible: true,
                          enableDrag: true,
                        );
                      },
                      tooltip: 'Change Map Type',
                    ),
                    const Divider(height: 1),
                    IconButton(
                      icon: const Icon(Icons.my_location, color: Colors.purple),
                      onPressed: () => controller.resetPosition(records),
                      tooltip: 'Reset Location',
                    ),
                  ],
                ),
              ),
            ),

            // Zoom Controls - Right
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).size.height * 0.2,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        onTap: () => controller.zoomIn(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Icon(Icons.add,
                              color: Colors.purple, size: 28),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        onTap: () => controller.zoomOut(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Icon(Icons.remove,
                              color: Colors.purple, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Edge Swipe Areas
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 20,
              child: GestureDetector(
                onHorizontalDragEnd: (DragEndDetails details) {
                  if (details.primaryVelocity! > 0) {
                    final TabController? tabController =
                        DefaultTabController.of(context);
                    if (tabController != null && tabController.index > 0) {
                      tabController.animateTo(tabController.index - 1);
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.purple.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Set<Marker> _createMarkers(List records) {
    return records
        .where((record) => record.latitude != null && record.longitude != null)
        .map((record) {
      final user = controller.getUser(record.phoneNumber);
      return Marker(
        markerId: MarkerId(record.id),
        position: LatLng(record.latitude!, record.longitude!),
        infoWindow: InfoWindow(
          title: user?.name ?? 'User',
          snippet:
              'Phone: ${record.phoneNumber}\n${record.createdAt.toString().substring(0, 16)}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      );
    }).toSet();
  }
}
