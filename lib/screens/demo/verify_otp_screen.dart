import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/demo_class.dart';
import '../../providers/demo_provider.dart';
import '../../services/location_logger.dart';

/// The teacher arrives at the guardian's home, the guardian reads out the OTP
/// that was SMSed to their phone ~2 hours before the demo, and the teacher
/// pastes it here. On submit the app sends the code together with the teacher's
/// LIVE GPS + device-integrity flags to the backend, which verifies the code
/// and records how far the teacher was from the guardian's address. This is the
/// proof the teacher actually met the guardian — a remote paste or fake GPS is
/// caught server-side.
class VerifyOtpScreen extends StatefulWidget {
  final DemoClass demo;
  const VerifyOtpScreen({super.key, required this.demo});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _verifying = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    // Log a location ping tagged to this tuition as soon as the teacher opens
    // the verify screen at the guardian's home (best-effort, silent).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationLogger.log(
        tuitionId: widget.demo.tuitionId,
        context: 'otp_verify_open',
      );
    });
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _otpCtrl.text.trim();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the OTP the guardian gave you.')),
      );
      return;
    }
    setState(() => _verifying = true);
    final provider = Provider.of<DemoProvider>(context, listen: false);
    final result = await provider.verifyOtp(widget.demo, code);
    if (!mounted) return;
    setState(() => _verifying = false);

    final success = result['success'] == true;
    final message = (result['message'] ?? '').toString();
    final distance = result['distance_m'];

    if (success) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.verified, color: AppTheme.successColor, size: 40),
          title: const Text('Demo Verified'),
          content: Text(
            distance != null
                ? 'Verified successfully.\nYou were about ${distance}m from the '
                    'guardian address when you verified.'
                : 'Verified successfully.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isEmpty ? 'Verification failed.' : message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final provider = Provider.of<DemoProvider>(context, listen: false);
    final ok = await provider.resendOtp(widget.demo);
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'A fresh OTP has been sent to the guardian\'s phone.'
            : 'Could not resend the OTP. Please try again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final demo = widget.demo;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Demo OTP')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(demo.guardianName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.tag, size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(demo.tuitionCode,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place, size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(demo.address,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ask the guardian for the code that was sent to their phone, then '
            'enter it here. Your current location is captured automatically as '
            'proof you are at the guardian\'s home.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(fontSize: 26, letterSpacing: 8),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              counterText: '',
              hintText: '••••••',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _verifying ? null : _verify,
              icon: _verifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified),
              label: const Text('Verify at Guardian\'s Home',
                  style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _resending ? null : _resend,
            icon: _resending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sms),
            label: const Text('Resend OTP to guardian'),
          ),
        ],
      ),
    );
  }
}
