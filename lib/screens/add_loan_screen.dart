import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lendwise/models/borrower.dart';
import 'package:lendwise/services/auth_service.dart';
import 'package:lendwise/services/borrower_service.dart';
import 'package:lendwise/services/loan_service.dart';
import 'package:lendwise/services/settings_service.dart';

class AddLoanScreen extends StatefulWidget {
  final Borrower? borrower;

  const AddLoanScreen({
    super.key,
    this.borrower,
  });

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loanCodeController = TextEditingController();
  final _capitalController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _processingFeeController = TextEditingController();
  final _authService = AuthService();
  final _borrowerService = BorrowerService();
  final _loanService = LoanService();
  final _settingsService = SettingsService();
  final _currencyFormatter = NumberFormat.currency(symbol: '₦', decimalDigits: 2);
  
  Borrower? _selectedBorrower;
  List<Borrower> _borrowers = [];
  DateTime _startDate = DateTime.now();
  DateTime? _dueDate;
  bool _isLoading = false;
  bool _isLoadingBorrowers = true;
  String? _errorMessage;
  double _actualAmountToReceive = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedBorrower = widget.borrower;
    _loadInitialData();
  }

  @override
  void dispose() {
    _loanCodeController.dispose();
    _capitalController.dispose();
    _interestRateController.dispose();
    _processingFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingBorrowers = true);
    
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return;
      
      final settings = await _settingsService.getSettingsByUserId(user.id);
      final borrowers = await _borrowerService.getBorrowersByUserId(user.id);
      
      setState(() {
        _borrowers = borrowers;
        _interestRateController.text = settings?.defaultInterestRate.toString() ?? '20';
        _processingFeeController.text = settings?.defaultProcessingFeePercentage.toString() ?? '10';
        _isLoadingBorrowers = false;
      });
      
      _calculateActualAmount();
    } catch (e) {
      setState(() => _isLoadingBorrowers = false);
    }
  }

  void _calculateActualAmount() {
    final capital = double.tryParse(_capitalController.text) ?? 0.0;
    final feePercent = double.tryParse(_processingFeeController.text) ?? 0.0;
    final processingFee = capital * (feePercent / 100);
    setState(() => _actualAmountToReceive = capital - processingFee);
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_dueDate ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _dueDate = date;
        }
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedBorrower == null) {
      setState(() => _errorMessage = 'Please select a borrower');
      return;
    }
    
    if (_dueDate == null) {
      setState(() => _errorMessage = 'Please select a due date');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        setState(() => _errorMessage = 'User not found');
        return;
      }

      final capital = double.parse(_capitalController.text);
      final feePercent = double.parse(_processingFeeController.text);
      final processingFee = capital * (feePercent / 100);
      final interestRate = double.parse(_interestRateController.text);

      final loan = await _loanService.createLoan(
        userId: user.id,
        borrowerId: _selectedBorrower!.id,
        loanCode: _loanCodeController.text.trim(),
        capitalAmount: capital,
        processingFee: processingFee,
        interestRate: interestRate,
        startDate: _startDate,
        dueDate: _dueDate!,
      );

      if (loan != null) {
        await _borrowerService.addLoanToBorrower(_selectedBorrower!.id, loan.id);
        
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() => _errorMessage = 'Failed to create loan');
      }
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('MMM dd, yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Loan'),
        centerTitle: true,
      ),
      body: _isLoadingBorrowers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Borrower Selection
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
                              'Borrower',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            DropdownButtonFormField<Borrower>(
                              value: _selectedBorrower,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                                hintText: 'Select Borrower',
                              ),
                              items: _borrowers.map((borrower) {
                                return DropdownMenuItem(
                                  value: borrower,
                                  child: Text(borrower.name),
                                );
                              }).toList(),
                              onChanged: (borrower) {
                                setState(() => _selectedBorrower = borrower);
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a borrower';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Loan Details
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
                            
                            TextFormField(
                              controller: _loanCodeController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Loan Code *',
                                prefixIcon: Icon(Icons.tag),
                                border: OutlineInputBorder(),
                                hintText: 'e.g., FMPCSFMCY',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter loan code';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _capitalController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(
                                labelText: 'Capital Amount (₦) *',
                                prefixIcon: Icon(Icons.payments),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => _calculateActualAmount(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter capital amount';
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return 'Please enter a valid amount';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _processingFeeController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Processing Fee (%)',
                                      prefixIcon: Icon(Icons.percent),
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => _calculateActualAmount(),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      final fee = double.tryParse(value);
                                      if (fee == null || fee < 0 || fee > 100) {
                                        return 'Invalid %';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _interestRateController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Interest Rate (%)',
                                      prefixIcon: Icon(Icons.trending_up),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      final rate = double.tryParse(value);
                                      if (rate == null || rate < 0) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            
                            if (_actualAmountToReceive > 0) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: theme.colorScheme.onPrimaryContainer,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Borrower receives: ${_currencyFormatter.format(_actualAmountToReceive)}',
                                        style: TextStyle(
                                          color: theme.colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Dates
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
                              'Dates',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(context, isStartDate: true),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Start Date',
                                        prefixIcon: Icon(Icons.calendar_today),
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Text(dateFormatter.format(_startDate)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(context, isStartDate: false),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Due Date *',
                                        prefixIcon: Icon(Icons.event),
                                        border: OutlineInputBorder(),
                                      ),
                                      child: Text(
                                        _dueDate != null
                                            ? dateFormatter.format(_dueDate!)
                                            : 'Select date',
                                        style: TextStyle(
                                          color: _dueDate == null
                                              ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    FilledButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Loan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}