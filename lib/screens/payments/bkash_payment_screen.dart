import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/theme.dart';

/// Opens the bKash payment gateway in a WebView. Monitors the URL for the
/// success redirect (when the backend callback finishes and returns to the
/// teachers.payments route) and closes automatically, returning true.
class BkashPaymentScreen extends StatefulWidget {
  final String bkashUrl;
  final String paymentId;

  const BkashPaymentScreen({
    super.key,
    required this.bkashUrl,
    required this.paymentId,
  });

  @override
  State<BkashPaymentScreen> createState() => _BkashPaymentScreenState();
}

class _BkashPaymentScreenState extends State<BkashPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            // The backend callback redirects to route('teachers.payments') on
            // success. Detect that final redirect to close the WebView.
            if (url.contains('/teachers/payments') &&
                !url.contains('/bkash/callback')) {
              // Success! Close and return true.
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            // Allow bKash gateway, callback, and intermediate pages.
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.bkashUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('bKash Payment'),
        backgroundColor: const Color(0xFFE2136E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFE2136E),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading bKash...',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
