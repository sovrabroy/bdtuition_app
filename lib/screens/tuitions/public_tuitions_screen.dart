import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'tuition_list_screen.dart';

/// Standalone, logged-out view of all available tuitions.
///
/// [TuitionListScreen] itself is a bare Column designed to live inside the
/// HomeScreen's bottom-nav (no Scaffold of its own). This wrapper gives it an
/// AppBar + Scaffold so it can be pushed from the welcome screen before the
/// user signs in. Browsing tuitions requires no auth token — only applying
/// does, and that path already routes through login.
class PublicTuitionsScreen extends StatelessWidget {
  const PublicTuitionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Tuitions'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const TuitionListScreen(),
    );
  }
}
