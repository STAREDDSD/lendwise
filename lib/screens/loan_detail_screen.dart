import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lendwise/models/loan.dart';
import 'package:lendwise/models/borrower.dart';
import 'package:lendwise/models/payment.dart';
import 'package:lendwise/services/borrower_service.dart';
import 'package:lendwise/services/loan_service.dart';
import 'package:lendwise/services/payment_service.dart';
import 'package:lendwise/screens/record_payment_screen.dart';

class LoanDetailScreen extends StatefulWidget {
  final Loan loan;
  
  const LoanDetailScreen({
    super.key,
    required this.loan,
  });

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  final _borrowerService = BorrowerService();
  final _loanService = LoanService();
  final _paymentService = PaymentService();
  final _currencyFormatter = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
  final _dateFormatter = DateFormat('MMM dd, yyyy');
  
  Loan? _loan;
  Borrower? _borrower;
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loan = widget.loan;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final loan = await _loanService.getLoanById(widget.loan.id);
      final borrower = await _borrowerService.getBorrowerById(widget.loan.borrowerId);
      final payments = await _paymentService.getPaymentsByLoanId(widget.loan.id);
      
      setState(() {
        _loan = loan;
        _borrower = borrower;
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleInterest() async {
    if (_loan == null) return;
    
    final updatedLoan = await _loanService.toggleInterestPause(_loan!.id);
    if (updatedLoan != null) {
      setState(() => _loan = updatedLoan);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updatedLoan.interestPaused
                ? 'Interest paused for this loan'
                : 'Interest resumed for this loan'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loan = _loan;
    
    if (_isLoading || loan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loan Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (loan.isOverdue) {
      statusColor = theme.colorScheme.error;
      statusIcon = Icons.warning;
      statusText = 'Overdue';
    } else if (loan.status == LoanStatus.completed) {
      statusColor = theme.colorScheme.tertiary;
      statusIcon = Icons.check_circle;
      statusText = 'Completed';
    } else {
      statusColor = theme.colorScheme.primary;
      statusIcon = Icons.schedule;
      statusText = 'Active';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loan.loanCode),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Card(
                elevation: 0,
                color: statusColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusText,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_borrower != null)
                              Text(
                                _borrower!.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: statusColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Loan Amount Details
              Card(
                elevation: 0,
                color: theme.brightness == Brightness.light 
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF1E2430),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'Capital Amount',
                        value: _currencyFormatter.format(loan.capitalAmount),
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'Processing Fee',
                        value: _currencyFormatter.format(loan.processingFee),
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'Amount Received',
                        value: _currencyFormatter.format(loan.actualAmountReceived),
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'Current Balance',
                        value: _currencyFormatter.format(loan.currentBalance),
                        valueColor: loan.status == LoanStatus.completed 
                            ? theme.colorScheme.tertiary 
                            : null,
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'Interest Rate',
                        value: '${loan.interestRate}% per month',
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Dates Card
              Card(
                elevation: 0,
                color: theme.brightness == Brightness.light 
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF1E2430),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timeline',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'Start Date',
                        value: _dateFormatter.format(loan.startDate),
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'Due Date',
                        value: _dateFormatter.format(loan.dueDate),
                        valueColor: loan.isOverdue ? theme.colorScheme.error : null,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Interest Control
              Card(
                elevation: 0,
                color: theme.brightness == Brightness.light 
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF1E2430),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Interest Status',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loan.interestPaused ? 'Paused' : 'Active',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: loan.interestPaused 
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: loan.status == LoanStatus.completed ? null : _toggleInterest,
                        child: Text(loan.interestPaused ? 'Resume' : 'Pause'),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Payments Section
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Payment History',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (loan.status != LoanStatus.completed)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RecordPaymentScreen(loan: loan),
                          ),
                        ).then((_) => _loadData());
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Record'),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              if (_payments.isEmpty)
                Card(
                  elevation: 0,
                  color: theme.brightness == Brightness.light 
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF1E2430),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No payments recorded yet',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ..._payments.map((payment) => Card(
                  elevation: 0,
                  color: theme.brightness == Brightness.light 
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF1E2430),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.payments,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currencyFormatter.format(payment.amount),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _dateFormatter.format(payment.paymentDate),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              if (payment.notes.isNotEmpty)
                                Text(
                                  payment.notes,
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: loan.status != LoanStatus.completed
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RecordPaymentScreen(loan: loan),
                  ),
                ).then((_) => _loadData());
              },
              label: const Text('Record Payment'),
              icon: const Icon(Icons.payments),
            )
          : null,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}