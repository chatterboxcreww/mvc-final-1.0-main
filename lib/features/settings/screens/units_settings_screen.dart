import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_background.dart';
import '../../../core/providers/user_data_provider.dart';

class UnitsSettingsScreen extends StatefulWidget {
  const UnitsSettingsScreen({super.key});

  @override
  State<UnitsSettingsScreen> createState() => _UnitsSettingsScreenState();
}

class _UnitsSettingsScreenState extends State<UnitsSettingsScreen>
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
        title: 'Units Preference',
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
                final unitSystem = userProvider.userData.unitSystem;
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      
                      // Description
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Choose your preferred unit system for displaying measurements throughout the app.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Metric Option
                      _buildUnitOption(
                        context,
                        'Metric',
                        'Kilometers, Kilograms, Celsius',
                        'metric',
                        unitSystem == 'metric',
                        Icons.straighten_rounded,
                        () => _updateUnitSystem(context, userProvider, 'metric'),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Imperial Option
                      _buildUnitOption(
                        context,
                        'Imperial',
                        'Miles, Pounds, Fahrenheit',
                        'imperial',
                        unitSystem == 'imperial',
                        Icons.square_foot_rounded,
                        () => _updateUnitSystem(context, userProvider, 'imperial'),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Preview Card
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.preview_rounded,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Preview',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildPreviewRow('Distance', 
                              unitSystem == 'metric' ? '5.0 km' : '3.1 mi'),
                            const SizedBox(height: 8),
                            _buildPreviewRow('Weight', 
                              unitSystem == 'metric' ? '70 kg' : '154 lbs'),
                            const SizedBox(height: 8),
                            _buildPreviewRow('Height', 
                              unitSystem == 'metric' ? '175 cm' : '5\'9"'),
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

  Widget _buildUnitOption(
    BuildContext context,
    String title,
    String subtitle,
    String value,
    bool isSelected,
    IconData icon,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      onTap: onTap,
      gradientColors: isSelected
          ? [
              colorScheme.primary.withOpacity(0.2),
              colorScheme.primary.withOpacity(0.1),
            ]
          : null,
      border: Border.all(
        color: isSelected 
            ? colorScheme.primary.withOpacity(0.3)
            : Colors.white.withOpacity(0.2),
        width: isSelected ? 2 : 1,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? colorScheme.primary.withOpacity(0.2)
                  : colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: colorScheme.primary,
              size: 28,
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _updateUnitSystem(
    BuildContext context,
    UserDataProvider userProvider,
    String unitSystem,
  ) async {
    await userProvider.updateUserData(
      userProvider.userData.copyWith(unitSystem: unitSystem),
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Unit system updated to ${unitSystem == 'metric' ? 'Metric' : 'Imperial'}'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
