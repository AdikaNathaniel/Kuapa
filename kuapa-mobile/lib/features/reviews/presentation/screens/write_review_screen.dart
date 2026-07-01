import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/kuapa_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  final String revieweeId;
  final String revieweeName;
  final String revieweeType; // FARMER | TRANSPORTER | BUYER
  final String? orderId;

  const WriteReviewScreen({
    super.key,
    required this.revieweeId,
    required this.revieweeName,
    required this.revieweeType,
    this.orderId,
  });

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  IconData _typeIcon() => switch (widget.revieweeType) {
        'TRANSPORTER' => Icons.local_shipping_outlined,
        'BUYER' => Icons.shopping_bag_outlined,
        _ => Icons.agriculture_outlined,
      };

  Color _typeColor() => switch (widget.revieweeType) {
        'TRANSPORTER' => AppTheme.primary,
        'BUYER' => AppTheme.primaryLight,
        _ => AppTheme.primary,
      };

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating'), backgroundColor: AppTheme.primary),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final user = ref.read(authUserProvider).valueOrNull;
      await ApiClient.instance.post(ApiConstants.reviews, data: {
        'revieweeId': widget.revieweeId,
        'revieweeName': widget.revieweeName,
        'revieweeType': widget.revieweeType,
        if (widget.orderId != null) 'orderId': widget.orderId,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'reviewerName': user?.displayName ?? 'User',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted!'), backgroundColor: AppTheme.primary),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('Already reviewed')
            ? 'You have already reviewed this order'
            : 'Failed to submit: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor();

    return Scaffold(
      appBar: AppBar(title: const Text('Write a Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Reviewee avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
              ),
              child: Icon(_typeIcon(), size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              widget.revieweeName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.revieweeType,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 36),
            const Text(
              'How was your experience?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 48,
                      color: filled ? AppTheme.primary : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _rating == 0
                  ? 'Tap to rate'
                  : ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][_rating],
              style: TextStyle(
                color: _rating == 0 ? Colors.grey : AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 32),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 300,
              decoration: InputDecoration(
                labelText: 'Comments (optional)',
                hintText: 'Share your experience…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 24),
            KuapaButton(
              label: 'Submit Review',
              onPressed: _submit,
              isLoading: _submitting,
              icon: Icons.send_outlined,
            ),
          ],
        ),
      ),
    );
  }
}
