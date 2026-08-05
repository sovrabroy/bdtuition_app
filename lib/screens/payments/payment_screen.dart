import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/teacher_provider.dart';
import 'bkash_payment_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TeacherProvider>(context, listen: false);
      provider.loadPayments();
      // Total Paid / Pending Due live on the dashboard payload — make sure it's
      // loaded so the summary at the top of this screen has values.
      if (provider.dashboardData == null) {
        provider.loadDashboard();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Payment summary — Total Paid + Pending Due (moved here from the
        // dashboard). Reads from the dashboard payload.
        Consumer<TeacherProvider>(
          builder: (context, provider, _) {
            final data = provider.dashboardData;
            final totalPaid = data?['total_earnings'] ?? 0;
            final pendingDue = data?['pending_due'] ?? 0;
            return Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      icon: Icons.check_circle,
                      label: 'Total Paid',
                      value: '৳$totalPaid',
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryTile(
                      icon: Icons.pending_actions,
                      label: 'Pending Due',
                      value: '৳$pendingDue',
                      color: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Due Payments'),
              Tab(text: 'Payment History'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: Consumer<TeacherProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.paymentsData == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.error != null && provider.paymentsData == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppTheme.errorColor),
                      const SizedBox(height: 12),
                      Text(
                        provider.error!,
                        style:
                            const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.loadPayments(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final data = provider.paymentsData;
              final duePayments = _extractDuePayments(data);
              final paymentHistory = List<dynamic>.from(
                data?['payment_history'] ??
                    data?['payments'] ??
                    data?['history'] ??
                    [],
              );

              return TabBarView(
                controller: _tabController,
                children: [
                  // Due Payments tab
                  _DuePaymentsList(
                    payments: duePayments,
                    onRefresh: () => provider.loadPayments(),
                    onPay: _showPaymentDialog,
                  ),

                  // Payment History tab
                  _PaymentHistoryList(
                    payments: paymentHistory,
                    onRefresh: () => provider.loadPayments(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Automatic bKash payment. Asks only for the amount, then opens the bKash
  /// hosted checkout in a WebView. No manual transaction ID — the backend
  /// confirms the payment via its bKash callback.
  void _showPaymentDialog(Map<String, dynamic> assignment) {
    final dueAmount = _dueAmountOf(assignment);
    final amountController = TextEditingController(
      text: dueAmount > 0 ? dueAmount.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Pay with bKash'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tuition info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        assignment['tuition_code'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due: ৳${dueAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Amount
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '৳ ',
                  ),
                ),
                const SizedBox(height: 12),

                // bKash note
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'You will be redirected to bKash to complete the '
                        'payment securely.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2136E),
              ),
              icon: const Icon(Icons.phone_android, size: 18),
              label: const Text('Pay with bKash'),
              onPressed: () {
                final amountText = amountController.text.trim();
                final amount = double.tryParse(amountText);

                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                if (amount > dueAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Amount cannot be more than the due'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);
                _startBkashPayment(
                  assignment['assignment_id'] ?? assignment['id'],
                  amount,
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Creates the bKash checkout session and opens the gateway WebView.
  Future<void> _startBkashPayment(dynamic assignmentId, double amount) async {
    final provider = Provider.of<TeacherProvider>(context, listen: false);

    // Loading while the checkout session is created.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await provider.createBkashPayment(
      assignmentId is int
          ? assignmentId
          : int.tryParse('$assignmentId') ?? 0,
      amount,
    );

    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    if (result['success'] != true || result['bkash_url'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ??
              'Could not start bKash payment.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Open the bKash hosted checkout. Returns true when the success redirect
    // is detected.
    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BkashPaymentScreen(
          bkashUrl: result['bkash_url'].toString(),
          paymentId: result['payment_id']?.toString() ?? '',
        ),
      ),
    );

    if (!mounted) return;

    if (paid == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment completed successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      // Refresh both the payment list and the dashboard summary (paid/due).
      provider.loadPayments();
      provider.loadDashboard();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment was not completed.'),
          backgroundColor: AppTheme.textSecondary,
        ),
      );
      // Reload in case the payment did go through but the redirect was missed.
      provider.loadPayments();
    }
  }
}

/// Parse a due amount from any of the common backend field names.
/// Returns 0 when nothing usable is present.
double _dueAmountOf(Map<String, dynamic> m) {
  const keys = [
    'due_amount',
    'due',
    'due_payment',
    'pending_due',
    'pending_amount',
    'remaining',
    'remaining_amount',
    'balance',
  ];
  for (final k in keys) {
    final v = m[k];
    if (v == null) continue;
    final d = v is num ? v.toDouble() : double.tryParse('$v'.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (d != null && d > 0) return d;
  }
  return 0;
}

/// Build the list of due payments, resilient to different response shapes.
/// 1) Use an explicit due list if the API sends one.
/// 2) Otherwise derive it from assignments that carry a positive due amount.
List<dynamic> _extractDuePayments(Map<String, dynamic>? data) {
  if (data == null) return [];

  final explicit = data['due_payments'] ?? data['dues'] ?? data['due'];
  if (explicit is List && explicit.isNotEmpty) return List<dynamic>.from(explicit);

  // Fall back: scan any assignment-like list for positive dues.
  final candidates = [
    data['assignments'],
    data['active_assignments'],
    data['tuitions'],
    data['payments'],
  ];
  for (final c in candidates) {
    if (c is List) {
      final derived = c
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => _dueAmountOf(e) > 0)
          .toList();
      if (derived.isNotEmpty) return derived;
    }
  }
  return [];
}

class _DuePaymentsList extends StatelessWidget {
  final List<dynamic> payments;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onPay;

  const _DuePaymentsList({
    required this.payments,
    required this.onRefresh,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'No due payments',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'All payments are up to date',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index] as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          payment['tuition_code'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'DUE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Location
                  if (payment['area'] != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${payment['area']}, ${payment['city'] ?? ''}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),

                  // Due amount
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '৳${_dueAmountOf(payment).toStringAsFixed(0)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => onPay(payment),
                      icon: const Icon(Icons.phone_android, size: 18),
                      label: const Text('Pay with bKash'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE2136E),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PaymentHistoryList extends StatelessWidget {
  final List<dynamic> payments;
  final Future<void> Function() onRefresh;

  const _PaymentHistoryList({
    required this.payments,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'No payment history',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index] as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: _getMethodColor(payment['payment_method'])
                    .withOpacity(0.15),
                child: Icon(
                  Icons.receipt,
                  color: _getMethodColor(payment['payment_method']),
                  size: 20,
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      payment['tuition_code'] ?? 'Payment',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '৳${payment['amount'] ?? '0'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getMethodColor(payment['payment_method'])
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getMethodLabel(payment['payment_method']),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color:
                                  _getMethodColor(payment['payment_method']),
                            ),
                          ),
                        ),
                        if (payment['transaction_id'] != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            'TxID: ${payment['transaction_id']}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatDate(payment['created_at'] ?? payment['date']),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getMethodColor(String? method) {
    switch (method?.toLowerCase()) {
      case 'bkash':
        return const Color(0xFFE2136E);
      case 'nagad':
        return const Color(0xFFF6921E);
      case 'rocket':
        return const Color(0xFF8B2F87);
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getMethodLabel(String? method) {
    switch (method?.toLowerCase()) {
      case 'bkash':
        return 'bKash';
      case 'nagad':
        return 'Nagad';
      case 'rocket':
        return 'Rocket';
      default:
        return method ?? 'N/A';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

/// Compact summary tile used in the payment header for Total Paid / Pending Due.
class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
