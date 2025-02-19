import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/gallery_controller.dart';
import 'package:intl/intl.dart';

class GalleryView extends GetView<GalleryController> {
  const GalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          controller.userName ?? 'Gallery',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Obx(() => GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: controller.images.length + 1, // +1 for add button
        itemBuilder: (context, index) {
          if (index == 0) {
            return InkWell(
              onTap: controller.showImageSourceDialog,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_a_photo,
                  color: Colors.purple,
                  size: 32,
                ),
              ),
            );
          }
          
          final image = controller.images[index - 1];
          return InkWell(
            onTap: () => controller.showFullImage(image.url),
            onLongPress: () => controller.showImageOptions(image),
            child: Stack(
              children: [
                Hero(
                  tag: image.url,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: image.url.startsWith('http')
                            ? NetworkImage(image.url)
                            : FileImage(File(image.url)) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      DateFormat('MMM d').format(image.uploadedAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      )),
    );
  }
} 