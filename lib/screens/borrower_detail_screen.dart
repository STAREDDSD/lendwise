import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lendwise/models/borrower.dart';
import 'package:lendwise/models/loan.dart';
import 'package:lendwise/services/loan_service.dart';
import 'package:lendwise/screens/loan_detail_screen.dart';
import 'package:lendwise/screens/add_loan_screen.dart';

class BorrowerDetailScreen extends StatefulWidget {
  final Borrower borrower;

  const BorrowerDetailScreen({
    super.key,
    required this.borrower,
  });

  @override
  State<BorrowerDetailScreen> createState() => _BorrowerDetailScreenState();
}

class _BorrowerDetailScreenState extends State<BorrowerDetailScreen> {
  final _loanService = LoanService();
  final _currencyFormatter = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
  
  List<Loan> _loans = [];
  bool _isLoading = true;
  double _totalOutstanding = 0.0;
  int _activeLoans = 0;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    setState(() => _isLoading = true);
    
    try {
      final loans = await _loanService.getLoansByBorrowerId(widget.borrower.id);
      
      double outstanding = 0.0;
      int active = 0;
      
      for (final loan in loans) {
        if (loan.status == LoanStatus.active) {
          outstanding += loan.currentBalance;
          active++;
        }
      }
      
      setState(() {
        _loans = loans;
        _totalOutstanding = outstanding;
        _activeLoans = active;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.borrower.name),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLoans,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Borrower Info Card
                    Card(
                      elevation: 0,
                      color: theme.brightness == Brightness.light 
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF1E2430),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                widget.borrower.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.borrower.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.phone, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                                const SizedBox(width: 4),
                                Text(
                                  widget.borrower.phone,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.borrower.address.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.location_on, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      widget.borrower.address,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Statistics
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Active Loans',
                            value: '$_activeLoans',
                            icon: Icons.account_balance_wallet,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Total Outstanding',
                            value: _currencyFormatter.format(_totalOutstanding),
                            icon: Icons.payments,
                            color: theme.colorScheme.tertiary,
                            isAmount: true,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Loans Section
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Loans',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddLoanScreen(borrower: widget.borrower),
                              ),
                            ).then((_) => _loadLoans());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Loan'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    if (_loans.isEmpty)
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
                                  Icons.account_balance_wallet_outlined,
                                  size: 48,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No loans yet',
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
                      ..._loans.map((loan) => _LoanItem(
                        loan: loan,
                        currencyFormatter: _currencyFormatter,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LoanDetailScreen(loan: loan),
                            ),
                          ).then((_) => _loadLoans());
                        },
                      )),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isAmount;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isAmount = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      color: theme.brightness == Brightness.light 
          ? const Color(0xFFF8FAFC)
          : const Color(0xFF1E2430),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isAmount ? 16 : 20,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanItem extends StatelessWidget {
  final Loan loan;
  final NumberFormat currencyFormatter;
  final VoidCallback onTap;

  const _LoanItem({
    required this.loan,
    required this.currencyFormatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('MMM dd, yyyy');
    
    Color statusColor;
    if (loan.isOverdue) {
      statusColor = theme.colorScheme.error;
    } else if (loan.status == LoanStatus.completed) {
      statusColor = theme.colorScheme.tertiary;
    } else {
      statusColor = theme.colorScheme.primary;
    }
    
    return Card(
      elevation: 0,
      color: theme.brightness == Brightness.light 
          ? const Color(0xFFF8FAFC)
          : const Color(0xFF1E2430),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loan.loanCode,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      loan.status.name.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          currencyFormatter.format(loan.currentBalance),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          dateFormatter.format(loan.dueDate),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}