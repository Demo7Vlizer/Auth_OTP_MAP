import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../auth/controllers/auth_controller.dart';
import 'dart:io';
import '../../../modules/verification_history/controllers/verification_history_controller.dart';
import '../../../modules/verification_history/views/widgets/map_view_tab.dart';
import '../../../services/storage_service.dart';

class VerificationHistoryView extends GetView<AuthController> {
  const VerificationHistoryView({super.key});

  VerificationHistoryController get historyController => 
      Get.find<VerificationHistoryController>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text(
            'Verification History',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.purple),
              onPressed: () {
                final phoneNumber = Get.find<StorageService>().getUser()?.phoneNumber;
                if (phoneNumber != null) {
                  Get.toNamed(
                    Routes.PROFILE_UPDATE,
                    parameters: {'phone': phoneNumber},
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.purple),
              onPressed: controller.refreshRecords,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.purple),
              onPressed: controller.logout,
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.purple,
            tabs: const [
              Tab(
                icon: Icon(Icons.list_alt),
                text: 'List View',
              ),
              Tab(
                icon: Icon(Icons.map),
                text: 'Map View',
              ),
            ],
          ),
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: [
            // List View Tab
            Obx(() => controller.otpRecords.isEmpty
                ? _buildEmptyState()
                : _buildListView()),
            
            // Map View Tab
            const MapViewTab(),
          ],
        ),
        bottomNavigationBar: Container(
          height: 4,
          child: TabPageSelector(
            color: Colors.grey.shade300,
            selectedColor: Colors.purple,
            indicatorSize: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 50,
              color: Colors.purple.shade300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No verification records found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: controller.refreshRecords,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: () async => controller.refreshRecords(),
      color: Colors.deepPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.otpRecords.length,
        itemBuilder: (context, index) {
          final record = controller.otpRecords[index];
          final user = historyController.getUser(record.phoneNumber);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.shade100.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: user?.profileImage != null 
                    ? (user!.profileImage!.startsWith('http')
                        ? NetworkImage(user.profileImage!)
                        : FileImage(File(user.profileImage!)) as ImageProvider)
                    : null,
                child: user?.profileImage == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              title: Text(
                user?.name ?? 'User',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phone: ${record.phoneNumber}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Verified at: ${record.createdAt.toString().substring(0, 16)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  if (record.latitude != null && record.longitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.purple.shade300,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${record.latitude?.toStringAsFixed(6)}, ${record.longitude?.toStringAsFixed(6)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              onTap: () => Get.toNamed(
                Routes.GALLERY,
                parameters: {
                  'phone': record.phoneNumber,
                  'name': user?.name ?? 'User',
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
