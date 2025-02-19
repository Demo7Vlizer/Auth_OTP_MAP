import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_auth/app/data/models/gallery_image.dart';
import 'package:new_auth/app/services/storage_service.dart';
import '../../../services/cloudinary_service.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class GalleryController extends GetxController {
  final images = <GalleryImage>[].obs;
  final isLoading = false.obs;
  final String? userName = Get.parameters['name'];
  final String? phoneNumber = Get.parameters['phone'];

  @override
  void onInit() {
    super.onInit();
    loadImages();
  }

  Future<void> loadImages() async {
    // Load images from user's gallery
    final user = Get.find<StorageService>().getUser(phoneNumber ?? '');
    if (user != null && user.galleryImages.isNotEmpty) {
      images.assignAll(user.galleryImages
          .map((url) => GalleryImage(
                url: url,
                uploadedAt: DateTime.now(),
                id: DateTime.now().millisecondsSinceEpoch.toString(),
              ))
          .toList());
    }
  }

  void showImageSourceDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.purple),
              title: const Text('Take Photo'),
              onTap: () {
                Get.back();
                captureImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.purple),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                captureImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> captureImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image != null) {
        isLoading.value = true;

        try {
          final cloudinaryUrl =
              await CloudinaryService.instance.uploadImage(File(image.path));

          // Add to local list
          images.add(GalleryImage(
            url: cloudinaryUrl,
            uploadedAt: DateTime.now(),
            id: DateTime.now().millisecondsSinceEpoch.toString(),
          ));

          // Save to user's gallery images
          final user = Get.find<StorageService>().getUser(phoneNumber ?? '');
          if (user != null) {
            final updatedUser = user.copyWith(
              galleryImages: [...user.galleryImages, cloudinaryUrl],
            );
            await Get.find<StorageService>().saveUser(updatedUser);
          }

          Get.snackbar(
            'Success',
            'Image uploaded successfully',
            backgroundColor: Colors.green.shade100,
          );
        } catch (uploadError) {
          print('Upload error: $uploadError');
          Get.snackbar(
            'Error',
            'Failed to upload image. Please try again.',
            backgroundColor: Colors.red.shade100,
          );
        }
      }
    } catch (e) {
      print('Image capture error: $e');
      Get.snackbar(
        'Error',
        'Failed to capture image. Please try again.',
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void showFullImage(String imageUrl) {
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => Get.back(),
          child: Center(
            child: Hero(
              tag: imageUrl,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> deleteImage(GalleryImage image) async {
    try {
      // First delete from Cloudinary
      final deleted = await CloudinaryService.instance.deleteImage(image.url);
      if (!deleted) {
        throw Exception('Failed to delete from Cloudinary');
      }

      // Then update local storage
      final user = Get.find<StorageService>().getUser(phoneNumber ?? '');
      if (user != null) {
        // Remove from gallery images list
        final updatedGalleryImages =
            user.galleryImages.where((url) => url != image.url).toList();

        // Update user model
        final updatedUser = user.copyWith(
          galleryImages: updatedGalleryImages,
        );

        // Save updated user to storage
        await Get.find<StorageService>().saveUser(updatedUser);

        // Update UI by removing from local list
        images.removeWhere((i) => i.url == image.url);

        Get.back(); // Close any open dialogs
        Get.snackbar(
          'Success',
          'Image deleted successfully',
          backgroundColor: Colors.green.shade100,
        );
      }
    } catch (e) {
      print('Delete error: $e');
      Get.snackbar(
        'Error',
        'Failed to delete image completely. Please try again.',
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  void showImageOptions(GalleryImage image) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.purple),
              title: Text(
                  'Uploaded on: ${DateFormat('MMM d, yyyy HH:mm').format(image.uploadedAt)}'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Image'),
              onTap: () {
                Get.back();
                Get.dialog(
                  AlertDialog(
                    title: const Text('Delete Image'),
                    content: const Text(
                        'Are you sure you want to delete this image?'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.back();
                          deleteImage(image);
                        },
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
