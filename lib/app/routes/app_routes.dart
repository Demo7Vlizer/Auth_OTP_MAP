// ignore_for_file: constant_identifier_names

part of 'app_pages.dart';

abstract class Routes {
  static const AUTH_CHOICE = _Paths.AUTH_CHOICE;
  static const LOGIN = _Paths.LOGIN;
  static const REGISTER = _Paths.REGISTER;
  static const AUTH = '/auth';
  static const VERIFY_OTP = _Paths.VERIFY_OTP;
  static const VERIFICATION_HISTORY = _Paths.VERIFICATION_HISTORY;
  static const PROFILE_UPDATE = _Paths.PROFILE_UPDATE;
  static const GALLERY = _Paths.GALLERY;
}

abstract class _Paths {
  static const AUTH_CHOICE = '/auth-choice';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const VERIFY_OTP = '/verify-otp';
  static const VERIFICATION_HISTORY = '/verification-history';
  static const PROFILE_UPDATE = '/profile-update';
  static const GALLERY = '/gallery';
} 