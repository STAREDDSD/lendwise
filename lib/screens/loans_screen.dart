import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lendwise/models/loan.dart';
import 'package:lendwise/models/borrower.dart';
import 'package:lendwise/services/auth_service.dart';
import 'package:lendwise/services/loan_service.dart';
import 'package:lendwise/services/borrower_service.dart';
import 'package:lendwise/screens/loan_detail_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final _authService = AuthService();
  final _loanService = LoanService();
  final _borrowerService = BorrowerService();
  final _searchController = TextEditingController();
  final _currencyFormatter = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
  
  List<Loan> _loans = [];
  List<Loan> _filteredLoans = [];
  Map<String, Borrower> _borrowersCache = {};
  bool _isLoading = true;
  String _selectedFilter = 'All';
  
  final List<String> _filterOptions = ['All', 'Active', 'Overdue', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return;
      
      final loans = await _loanService.getLoansByUserId(user.id);
      final borrowers = await _borrowerService.getBorrowersByUserId(user.id);
      
      final borrowersMap = <String, Borrower>{};
      for (final borrower in borrowers) {
        borrowersMap[borrower.id] = borrower;
      }
      
      setState(() {
        _loans = loans;
        _filteredLoans = loans;
        _borrowersCache = borrowersMap;
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Loan> filtered = List.from(_loans);
    
    // Apply status filter
    switch (_selectedFilter) {
      case 'Active':
        filtered = filtered.where((loan) => loan.status == LoanStatus.active).toList();
        break;
      case 'Overdue':
        filtered = filtered.where((loan) => loan.isOverdue).toList();
        break;
      case 'Completed':
        filtered = filtered.where((loan) => loan.status == LoanStatus.completed).toList();
        break;
    }
    
    // Apply search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((loan) {
        final borrower = _borrowersCache[loan.borrowerId];
        return loan.loanCode.toLowerCase().contains(query) ||
               (borrower?.name.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // Sort by creation date (latest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    setState(() => _filteredLoans = filtered);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search loans or borrowers...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
                
                const SizedBox(height: 16),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedFilter = filter);
                            _applyFilters();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Loans List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLoans.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadLoans,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _filteredLoans.length,
                          itemBuilder: (context, index) {
                            final loan = _filteredLoans[index];
                            final borrower = _borrowersCache[loan.borrowerId];
                            
                            return _LoanCard(
                              loan: loan,
                              borrower: borrower,
                              currencyFormatter: _currencyFormatter,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LoanDetailScreen(loan: loan),
                                  ),
                                ).then((_) => _loadLoans());
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No loans found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter criteria',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final Borrower? borrower;
  final NumberFormat currencyFormatter;
  final VoidCallback onTap;

  const _LoanCard({
    required this.loan,
    required this.borrower,
    required this.currencyFormatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('MMM dd, yyyy');
    
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
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          borrower?.name ?? 'Unknown Borrower',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Code: ${loan.loanCode}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Amount Information
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Capital',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          currencyFormatter.format(loan.capitalAmount),
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
                          'Current Balance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          currencyFormatter.format(loan.currentBalance),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: loan.status == LoanStatus.completed 
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Date Information
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Date',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          dateFormatter.format(loan.startDate),
                          style: theme.textTheme.bodyMedium,
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: loan.isOverdue ? theme.colorScheme.error : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
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