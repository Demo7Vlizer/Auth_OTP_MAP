import 'package:dio/dio.dart';
import 'package:get/get.dart';

class DioService extends GetxService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://67b57bf4a9acbdb38ed28a42.mockapi.io/api/v1';

  Dio get dio => _dio;

  @override
  void onInit() {
    super.onInit();
    _dio.options.baseUrl = baseUrl;
    _dio.options.validateStatus = (status) => status! < 500;
  }
} 