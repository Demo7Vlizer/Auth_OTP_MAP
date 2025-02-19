import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../../../routes/app_pages.dart';
import '../../../data/models/user_model.dart';
import '../../../services/storage_service.dart';
import 'dart:io';
import '../../../services/cloudinary_service.dart';

class ProfileController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final formKey = GlobalKey<FormState>();
  
  // TextEditingControllers for form fields
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  
  final imageFile = Rxn<XFile>();
  final latitude = 0.0.obs;
  final longitude = 0.0.obs;
  final isLoading = false.obs;

  final _dio = Dio();
  final String _baseUrl = 'https://67b57bf4a9acbdb38ed28a42.mockapi.io/api/v1';

  @override
  void onInit() {
    super.onInit();
    loadUserDetails();
    _checkPermissions();
  }

  void loadUserDetails() {
    final phoneNumber = Get.parameters['phone'];
    if (phoneNumber == null) return;

    // First try to get from local storage
    final user = _storage.getUser(phoneNumber);
    if (user != null) {
      nameController.text = user.name ?? '';
      emailController.text = user.email ?? '';
      phoneController.text = user.phoneNumber ?? '';
      latitude.value = user.latitude ?? 0.0;
      longitude.value = user.longitude ?? 0.0;
      if (user.profileImage?.isNotEmpty == true) {
        imageFile.value = XFile(user.profileImage!);
      }
    }

    // Then fetch from API to ensure latest data
    _loadUserFromApi(phoneNumber);
  }

  Future<void> _loadUserFromApi(String phoneNumber) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/users',
        queryParameters: {'phoneNumber': phoneNumber},
      );

      if (response.data != null && (response.data as List).isNotEmpty) {
        final userData = (response.data as List).first;
        
        // Always update with latest data from API
        if (userData['name'] != null) {
          nameController.text = userData['name'];
        }
        if (userData['email'] != null) {
          emailController.text = userData['email'];
        }
        
        // Save the updated data to local storage
        final updatedUser = UserModel(
          phoneNumber: phoneNumber,
          name: nameController.text,
          email: emailController.text,
          profileImage: imageFile.value?.path,
          latitude: latitude.value,
          longitude: longitude.value,
          isLoggedIn: true,
        );
        await _storage.saveUser(updatedUser);
      }
    } catch (e) {
      print('Error loading user from API: $e');
      Get.snackbar(
        'Error',
        'Failed to load user details',
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('Error', 'Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('Error', 'Location permissions are denied');
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      latitude.value = position.latitude;
      longitude.value = position.longitude;
      Get.snackbar('Success', 'Location updated');
    } catch (e) {
      print('Location error: $e');
      Get.snackbar('Error', 'Could not get location. Please try again.');
    }
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (image != null) {
        isLoading.value = true;
        
        // Update the UI immediately with local file
        imageFile.value = image;
        
        try {
          // Upload to Cloudinary
          final cloudinaryUrl = await CloudinaryService.instance
              .uploadImage(File(image.path));
          
          // Save to storage with Cloudinary URL
          final phoneNumber = Get.parameters['phone'];
          if (phoneNumber != null) {
            final currentUser = _storage.getUser(phoneNumber);
            if (currentUser != null) {
              _cleanupOldImage(currentUser.profileImage);
              final updatedUser = currentUser.copyWith(
                profileImage: cloudinaryUrl,
              );
              await _storage.saveUser(updatedUser);
              
              Get.snackbar(
                'Success', 
                'Profile image uploaded successfully',
                backgroundColor: Colors.green.shade100,
              );
            }
          }
        } catch (uploadError) {
          print('Upload error: $uploadError');
          Get.snackbar(
            'Error',
            'Failed to upload image to cloud. Please try again.',
            backgroundColor: Colors.red.shade100,
          );
        }
      }
    } catch (e) {
      print('Image picker error: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image. Please try again.',
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile() async {
    if (!formKey.currentState!.validate()) return;
    
    isLoading.value = true;
    try {
      final phoneNumber = Get.parameters['phone'];
      if (phoneNumber == null) throw Exception('Phone number not found');

      // Get current user
      final currentUser = _storage.getUser(phoneNumber);
      if (currentUser == null) throw Exception('User not found');

      // Update user with new details including image
      final updatedUser = UserModel(
        phoneNumber: phoneNumber,
        name: nameController.text,
        email: emailController.text,
        profileImage: imageFile.value?.path,  // Save the image path
        latitude: latitude.value,
        longitude: longitude.value,
        isLoggedIn: true,
      );

      // Save to local storage
      await _storage.saveUser(updatedUser);

      // Update API
      final response = await _dio.get(
        '$_baseUrl/users',
        queryParameters: {'phoneNumber': phoneNumber},
      );

      if (response.data != null && (response.data as List).isNotEmpty) {
        final existingUser = (response.data as List).first;
        
        // Update with new data
        await _dio.put(
          '$_baseUrl/users/${existingUser['id']}',
          data: {
            'phoneNumber': phoneNumber,
            'name': nameController.text,
            'email': emailController.text,
            'profileImage': updatedUser.profileImage, // This will be the Cloudinary URL
            'location': {
              'latitude': latitude.value,
              'longitude': longitude.value,
            },
          },
        );
      }

      Get.snackbar(
        'Success', 
        'Profile updated successfully',
        backgroundColor: Colors.green.shade100,
      );
      Get.offAllNamed(Routes.VERIFICATION_HISTORY);
    } catch (e) {
      print('Update profile error: $e');
      Get.snackbar(
        'Error', 
        'Failed to update profile: $e',
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  void _cleanupOldImage(String? oldImagePath) {
    if (oldImagePath != null && 
        !oldImagePath.startsWith('http') && 
        File(oldImagePath).existsSync()) {
      try {
        File(oldImagePath).deleteSync();
      } catch (e) {
        print('Error deleting old image: $e');
      }
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
