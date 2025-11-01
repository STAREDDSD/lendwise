import 'package:flutter/material.dart';
import 'package:lendwise/services/auth_service.dart';
import 'package:lendwise/services/settings_service.dart';
import 'package:lendwise/models/settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _settingsService = SettingsService();
  
  Settings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return;
      
      final settings = await _settingsService.getSettingsByUserId(user.id);
      
      setState(() {
        _settings = settings;
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
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Default Settings Card
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
                            'Default Loan Settings',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _SettingRow(
                            label: 'Default Interest Rate',
                            value: '${_settings?.defaultInterestRate ?? 20}%',
                            icon: Icons.trending_up,
                            onTap: () {
                              // TODO: Implement edit dialog
                            },
                          ),
                          const Divider(height: 24),
                          
                          _SettingRow(
                            label: 'Default Processing Fee',
                            value: '${_settings?.defaultProcessingFeePercentage ?? 10}%',
                            icon: Icons.percent,
                            onTap: () {
                              // TODO: Implement edit dialog
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Bank Details Card
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
                            'Bank Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _SettingRow(
                            label: 'Bank Information',
                            value: _settings?.bankDetails ?? 'Not set',
                            icon: Icons.account_balance,
                            onTap: () {
                              // TODO: Implement edit dialog
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Message Template Card
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
                            'Message Template',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _SettingRow(
                            label: 'SMS Template',
                            value: 'Tap to edit',
                            icon: Icons.message,
                            onTap: () {
                              // TODO: Implement edit dialog
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Preferences Card
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
                            'Preferences',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Icon(Icons.notifications, color: theme.colorScheme.primary),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Notifications',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                              Switch(
                                value: _settings?.notificationsEnabled ?? true,
                                onChanged: (value) {
                                  // TODO: Implement toggle
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // About Section
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
                            'About',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _SettingRow(
                            label: 'Version',
                            value: '1.0.0',
                            icon: Icons.info,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final content = Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyLarge,
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
      ],
    );
    
    return onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: content,
            ),
          )
        : content;
  }
}