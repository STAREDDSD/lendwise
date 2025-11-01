import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lendwise/models/user.dart';
import 'package:lendwise/services/auth_service.dart';
import 'package:lendwise/services/loan_service.dart';
import 'package:lendwise/screens/loans_screen.dart';
import 'package:lendwise/screens/borrowers_screen.dart';
import 'package:lendwise/screens/add_loan_screen.dart';
import 'package:lendwise/screens/settings_screen.dart';
import 'package:lendwise/screens/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _loanService = LoanService();
  final _currencyFormatter =
      NumberFormat.currency(symbol: '₦', decimalDigits: 0);

  User? _currentUser;
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      final statistics = await _loanService.getLoanStatistics(user!.id);

      setState(() {
        _currentUser = user;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = [
      _buildDashboardContent(),
      const LoansScreen(),
      const BorrowersScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Loans',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Borrowers',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(builder: (_) => const AddLoanScreen()),
                    )
                    .then((_) => _loadData());
              },
              label: const Text('Add Loan'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDashboardContent() {
    final theme = Theme.of(context);
    final statistics = _statistics;

    if (statistics == null) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        _currentUser?.name ?? 'User',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Statistics Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _StatCard(
                  title: 'Active Loans',
                  value: '${statistics['activeLoans']}',
                  icon: Icons.trending_up,
                  color: theme.colorScheme.primary,
                ),
                _StatCard(
                  title: 'Overdue',
                  value: '${statistics['overdueLoans']}',
                  icon: Icons.warning,
                  color: theme.colorScheme.error,
                ),
                Text(
                  _currentUser?.name ?? 'User',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _StatCard(
                  title: 'Total Outstanding',
                  value:
                      _currencyFormatter.format(statistics['totalOutstanding']),
                  icon: Icons.account_balance,
                  color: theme.colorScheme.tertiary,
                  isAmount: true,
                ),
                _StatCard(
                  title: 'Total Given',
                  value: _currencyFormatter
                      .format(statistics['totalCapitalGiven']),
                  icon: Icons.payments,
                  color: theme.colorScheme.secondary,
                  isAmount: true,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 0,
              color: theme.brightness == Brightness.light
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFF1E2430),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _QuickActionTile(
                      icon: Icons.add_circle,
                      title: 'Add New Loan',
                      subtitle: 'Create a loan for a borrower',
                      onTap: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                  builder: (_) => const AddLoanScreen()),
                            )
                            .then((_) => _loadData());
                      },
                    ),
                    const Divider(),
                    _QuickActionTile(
                      icon: Icons.people_alt,
                      title: 'Manage Borrowers',
                      subtitle: 'View and edit borrower profiles',
                      onTap: () => setState(() => _currentIndex = 2),
                    ),
                    const Divider(),
                    _QuickActionTile(
                      icon: Icons.analytics,
                      title: 'View Reports',
                      subtitle: 'Generate and export reports',
                      onTap: () {
                        // TODO: Navigate to reports screen
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Recent Activity Summary
            Text(
              'Summary',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 0,
              color: theme.brightness == Brightness.light
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFF1E2430),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Total Loans',
                      value: '${statistics['totalLoans']}',
                    ),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      label: 'Completed Loans',
                      value: '${statistics['completedLoans']}',
                    ),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      label: 'Processing Fees Earned',
                      value: _currencyFormatter
                          .format(statistics['totalProcessingFees']),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100), // Space for FAB
          ],
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
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(icon, color: color, size: 12),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isAmount ? 18 : 24,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
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
          ),
        ),
      ],
    );
  }
}
