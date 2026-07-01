import 'package:dio/dio.dart';

/// Converts a raw Dio or server error into a short, user-readable string.
String parseApiError(Object? error) {
  if (error == null) return 'Something went wrong. Please try again.';

  if (error is DioException) {
    final status = error.response?.statusCode;
    final data   = error.response?.data;

    // Pull the backend message out of the response body
    String? serverMsg;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) {
        serverMsg = msg;
      } else if (msg is List && msg.isNotEmpty) {
        serverMsg = msg.map((e) => e.toString()).join('\n');
      }
    }

    // Detect duplicate-account errors (backend often returns 500 + TypeORM text)
    final lowerMsg  = (serverMsg ?? '').toLowerCase();
    final lowerData = data?.toString().toLowerCase() ?? '';
    if (lowerMsg.contains('duplicate') ||
        lowerMsg.contains('already') ||
        lowerMsg.contains('unique') ||
        lowerMsg.contains('exist') ||
        lowerData.contains('duplicate') ||
        lowerData.contains('unique constraint') ||
        lowerData.contains('already exist')) {
      return 'An account with this email or phone number is already registered. Please sign in instead.';
    }

    // Use a clean backend message when it is short enough to be readable
    if (serverMsg != null && serverMsg.length <= 120 && !serverMsg.startsWith('Internal')) {
      return serverMsg;
    }

    // Status-code fallbacks
    switch (status) {
      case 400: return 'Invalid details. Please check your information and try again.';
      case 401: return 'Incorrect phone number or password.';
      case 403: return 'You do not have permission for this action.';
      case 404: return 'Account not found. Please check your details.';
      case 409: return 'An account with this email or phone number already exists.';
      case 500: return 'Server error. Please try again later.';
    }

    // Network / timeout errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Please check your internet connection.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network and try again.';
    }

    return 'Network error. Please try again.';
  }

  return 'Something went wrong. Please try again.';
}
