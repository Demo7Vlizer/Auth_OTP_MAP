import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/routes/app_pages.dart';
import 'package:geolocator/geolocator.dart';
import 'app/services/storage_service.dart';
import 'app/services/cache_service.dart';
import 'app/modules/auth/controllers/auth_controller.dart';
import 'app/services/session_service.dart';
import 'package:hive/hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive and services
  await Hive.initFlutter();
  
  // Initialize services in order
  await Get.putAsync(() => SessionService().init());
  await Get.putAsync(() => StorageService().init());
  Get.put(CacheService());
  
  // Initialize AuthController
  AuthController.instance;
  
  // Load environment variables
  await dotenv.load();
  
  // Request location permission
  await Geolocator.requestPermission();
  
  // Determine initial route based on login status
  String initialRoute = Routes.AUTH_CHOICE;
  
  // Check if user is logged in and has completed profile
  final storage = await Get.find<StorageService>();
  if (storage.isLoggedIn()) {
    final currentUser = storage.getUser();
    if (currentUser != null && storage.isProfileComplete(currentUser.phoneNumber!)) {
      initialRoute = Routes.VERIFICATION_HISTORY;
    }
  }
  
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Authentication App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      defaultTransition: Transition.fadeIn,
    );
  }
}
