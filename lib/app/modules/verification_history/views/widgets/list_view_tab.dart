import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/verification_history_controller.dart';
import '../../../auth/controllers/auth_controller.dart';

class ListViewTab extends GetView<VerificationHistoryController> {
  const ListViewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GetBuilder<AuthController>(
          builder: (authController) {
            final records = authController.otpRecords;

            if (records.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No verification history',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: records.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final record = records[index];
                final user = controller.getUser(record.phoneNumber);
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade100,
                      child: Text(
                        user?.name?[0] ?? 'U',
                        style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      user?.name ?? 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Phone: ${record.phoneNumber}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verified at: ${record.createdAt.toString().substring(0, 16)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.verified_user,
                      color: Colors.green[400],
                    ),
                  ),
                );
              },
            );
          },
        ),
        // Right edge swipe indicator
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.purple.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.chevron_right,
                color: Colors.purple.withOpacity(0.3),
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 