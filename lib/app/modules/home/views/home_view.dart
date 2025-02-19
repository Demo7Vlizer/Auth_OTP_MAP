import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';

class HomeView extends GetView<AuthController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Records'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.otpRecords.isEmpty) {
          return const Center(
            child: Text('No OTP records found'),
          );
        }

        return ListView.builder(
          itemCount: controller.otpRecords.length,
          itemBuilder: (context, index) {
            final record = controller.otpRecords[index];
            return ListTile(
              leading: const Icon(Icons.phone_android),
              title: Text('Phone: ${record.phoneNumber}'),
              subtitle: Text('ID: ${record.id}'),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.fetchOtpRecords,
        child: const Icon(Icons.refresh),
      ),
    );
  }
} 