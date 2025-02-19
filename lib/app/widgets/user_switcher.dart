import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/user_model.dart';
import '../services/storage_service.dart';

class UserSwitcher extends StatelessWidget {
  final StorageService _storage = Get.find<StorageService>();

  UserSwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.switch_account),
      onPressed: () {
        final users = _storage.getAllUsers();
        _showUserSwitchDialog(context, users);
      },
    );
  }

  void _showUserSwitchDialog(BuildContext context, List<UserModel> users) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch User'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user.name?[0] ?? 'U'),
                ),
                title: Text(user.name ?? 'Unknown'),
                subtitle: Text(user.phoneNumber ?? ''),
                trailing: user.isLoggedIn ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () async {
                  await _storage.switchUser(user.phoneNumber!);
                  Get.back();
                  Get.offAllNamed('/home'); // Restart app from home
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
} 