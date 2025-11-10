import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_background.dart';
import '../../../core/providers/user_data_provider.dart';

class IntegrationsSettingsScreen extends StatefulWidget {
  const IntegrationsSettingsScreen({super.key});

  @override
  State<IntegrationsSettingsScreen> createState() => _IntegrationsSettingsScreenState();
}

class _IntegrationsSettingsScreenState extends State<IntegrationsSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Integrations',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GlassBackgroundPainter(
                animation: _controller,
                colorScheme: colorScheme,
              ),
            ),
          ),
          SafeArea(
            child: Consumer<UserDataProvider>(
              builder: (context, userProvider, child) {
                final integrations = userProvider.userData.integrations;
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      
                      // Description
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Connect with other health and fitness apps to sync your data automatically.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Google Fit
                      _buildIntegrationTile(
                        context,
                        'Google Fit',
                        'Sync steps, calories, and activities',
                        'googleFit',
                        integrations['googleFit'] ?? false,
                        Icons.fitness_center_rounded,
                        Colors.red,
                        () => _toggleIntegration(context, userProvider, 'googleFit'),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Apple Health
                      _buildIntegrationTile(
                        context,
                        'Apple Health',
                        'Sync health data with Apple Health',
                        'appleHealth',
                        integrations['appleHealth'] ?? false,
                        Icons.favorite_rounded,
                        Colors.pink,
                        () => _toggleIntegration(context, userProvider, 'appleHealth'),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Fitbit
                      _buildIntegrationTile(
                        context,
                        'Fitbit',
                        'Connect your Fitbit device',
                        'fitbit',
                        integrations['fitbit'] ?? false,
                        Icons.watch_rounded,
                        Colors.teal,
                        () => _toggleIntegration(context, userProvider, 'fitbit'),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Warning Card
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Note',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Integration features are currently in development. Enabling these options will prepare your account for future updates.',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationTile(
    BuildContext context,
    String title,
    String subtitle,
    String key,
    bool enabled,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (enabled) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Connected',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (_) => onTap(),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleIntegration(
    BuildContext context,
    UserDataProvider userProvider,
    String integrationKey,
  ) async {
    final currentIntegrations = Map<String, bool>.from(userProvider.userData.integrations);
    final currentValue = currentIntegrations[integrationKey] ?? false;
    currentIntegrations[integrationKey] = !currentValue;
    
    await userProvider.updateUserData(
      userProvider.userData.copyWith(integrations: currentIntegrations),
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                !currentValue ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                '${_getIntegrationName(integrationKey)} ${!currentValue ? 'connected' : 'disconnected'}',
              ),
            ],
          ),
          backgroundColor: !currentValue ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getIntegrationName(String key) {
    switch (key) {
      case 'googleFit':
        return 'Google Fit';
      case 'appleHealth':
        return 'Apple Health';
      case 'fitbit':
        return 'Fitbit';
      default:
        return key;
    }
  }
}
