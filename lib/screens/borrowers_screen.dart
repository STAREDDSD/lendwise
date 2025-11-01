import 'package:flutter/material.dart';
import 'package:lendwise/models/borrower.dart';
import 'package:lendwise/services/auth_service.dart';
import 'package:lendwise/services/borrower_service.dart';
import 'package:lendwise/services/loan_service.dart';
import 'package:lendwise/screens/borrower_detail_screen.dart';
import 'package:lendwise/screens/add_borrower_screen.dart';

class BorrowersScreen extends StatefulWidget {
  const BorrowersScreen({super.key});

  @override
  State<BorrowersScreen> createState() => _BorrowersScreenState();
}

class _BorrowersScreenState extends State<BorrowersScreen> {
  final _authService = AuthService();
  final _borrowerService = BorrowerService();
  final _loanService = LoanService();
  final _searchController = TextEditingController();
  
  List<Borrower> _borrowers = [];
  List<Borrower> _filteredBorrowers = [];
  Map<String, int> _borrowerLoanCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBorrowers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBorrowers() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return;
      
      final borrowers = await _borrowerService.getBorrowersByUserId(user.id);
      final loanCounts = <String, int>{};
      
      for (final borrower in borrowers) {
        final loans = await _loanService.getLoansByBorrowerId(borrower.id);
        loanCounts[borrower.id] = loans.length;
      }
      
      setState(() {
        _borrowers = borrowers;
        _filteredBorrowers = borrowers;
        _borrowerLoanCounts = loanCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applySearch() {
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() => _filteredBorrowers = List.from(_borrowers));
      return;
    }
    
    setState(() {
      _filteredBorrowers = _borrowers.where((borrower) {
        return borrower.name.toLowerCase().contains(query) ||
               borrower.phone.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrowers'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddBorrowerScreen()),
              ).then((_) => _loadBorrowers());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search borrowers by name or phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applySearch();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _applySearch(),
            ),
          ),
          
          // Borrowers List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBorrowers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadBorrowers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _filteredBorrowers.length,
                          itemBuilder: (context, index) {
                            final borrower = _filteredBorrowers[index];
                            final loanCount = _borrowerLoanCounts[borrower.id] ?? 0;
                            
                            return _BorrowerCard(
                              borrower: borrower,
                              loanCount: loanCount,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BorrowerDetailScreen(borrower: borrower),
                                  ),
                                ).then((_) => _loadBorrowers());
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddBorrowerScreen()),
          ).then((_) => _loadBorrowers());
        },
        label: const Text('Add Borrower'),
        icon: const Icon(Icons.person_add),
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
            Icons.people_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No borrowers found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Add your first borrower to get started'
                : 'Try adjusting your search criteria',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _BorrowerCard extends StatelessWidget {
  final Borrower borrower;
  final int loanCount;
  final VoidCallback onTap;

  const _BorrowerCard({
    required this.borrower,
    required this.loanCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  borrower.name.isNotEmpty ? borrower.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Borrower Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      borrower.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          borrower.phone,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$loanCount ${loanCount == 1 ? 'loan' : 'loans'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
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
        ),
      ),
    );
  }
}