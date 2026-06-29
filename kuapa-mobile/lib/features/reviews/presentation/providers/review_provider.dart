import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

final userReviewsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, userId) async {
  final res = await ApiClient.instance.get('${ApiConstants.reviews}/user/$userId');
  return res.data as Map<String, dynamic>;
});
