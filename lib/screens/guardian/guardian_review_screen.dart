import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/guardian_provider.dart';

/// Guardian rates and reviews the teacher assigned to them.
/// Submits to the backend (guardian_reviews, one per guardian+teacher).
class GuardianReviewScreen extends StatefulWidget {
  final int teacherId;
  final String teacherName;
  final int? assignmentId;

  const GuardianReviewScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
    this.assignmentId,
  });

  @override
  State<GuardianReviewScreen> createState() => _GuardianReviewScreenState();
}

class _GuardianReviewScreenState extends State<GuardianReviewScreen> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final guardian = Provider.of<GuardianProvider>(context, listen: false);
    final res = await guardian.submitReview({
      'teacher_id': widget.teacherId,
      'assignment_id': widget.assignmentId,
      'rating': _rating,
      'comment': _commentCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _submitting = false);

    final ok = res['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']?.toString() ??
            (ok ? 'Review submitted' : 'Failed to submit')),
        backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Teacher')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.teacherName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'How is your experience with this teacher?',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    iconSize: 40,
                    icon: Icon(
                      star <= _rating ? Icons.star : Icons.star_border,
                      color: AppTheme.accentColor,
                    ),
                    onPressed: () => setState(() => _rating = star),
                  );
                }),
              ),
              Center(
                child: Text(
                  _ratingLabel(_rating),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _commentCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Your comment (optional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Submit Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Good';
      case 3:
        return 'Average';
      case 2:
        return 'Poor';
      default:
        return 'Very Poor';
    }
  }
}
