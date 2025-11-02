// lib/features/home/widgets/recipe_detail_screen.dart
import 'package:flutter/material.dart';
import '../../../core/models/curated_content_item.dart';

class RecipeDetailScreen extends StatelessWidget {
  final CuratedContentItem recipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.04;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          recipe.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image Placeholder
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
              ),
              child: recipe.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        recipe.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildImagePlaceholder(colorScheme),
                      ),
                    )
                  : _buildImagePlaceholder(colorScheme),
            ),
            
            const SizedBox(height: 24),
            
            // Recipe Title and Description
            Text(
              recipe.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              recipe.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Keywords/Tags
            if (recipe.keywords.isNotEmpty) ...[
              _buildSectionTitle('Tags', Icons.local_offer, colorScheme, context),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recipe.keywords.map((keyword) {
                  return Chip(
                    label: Text(
                      keyword.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    backgroundColor: colorScheme.primaryContainer,
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            
            // Ingredients Section
            _buildSectionTitle('Ingredients', Icons.shopping_cart, colorScheme, context),
            const SizedBox(height: 12),
            _buildIngredientsCard(colorScheme, context),
            
            const SizedBox(height: 24),
            
            // Nutrition Information
            _buildSectionTitle('Nutrition Facts', Icons.analytics, colorScheme, context),
            const SizedBox(height: 12),
            _buildNutritionCard(colorScheme, context),
            
            const SizedBox(height: 24),
            
            // Cooking Instructions
            _buildSectionTitle('How to Make', Icons.restaurant, colorScheme, context),
            const SizedBox(height: 12),
            _buildCookingInstructionsCard(colorScheme, context),
            
            const SizedBox(height: 24),
            
            // Health Benefits
            if (recipe.healthBenefit != null) ...[
              _buildSectionTitle('Health Benefits', Icons.favorite, colorScheme, context),
              const SizedBox(height: 12),
              _buildHealthBenefitsCard(colorScheme, context),
              const SizedBox(height: 24),
            ],
            
            // Allergen Information
            if (recipe.allergens.isNotEmpty) ...[
              _buildSectionTitle('Allergen Information', Icons.warning, colorScheme, context),
              const SizedBox(height: 12),
              _buildAllergenCard(colorScheme, context),
              const SizedBox(height: 24),
            ],
            
            // Good/Bad for Diseases
            if (recipe.goodForDiseases.isNotEmpty || recipe.badForDiseases.isNotEmpty) ...[
              _buildSectionTitle('Health Considerations', Icons.health_and_safety, colorScheme, context),
              const SizedBox(height: 12),
              _buildHealthConsiderationsCard(colorScheme, context),
            ],
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 48,
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Recipe Image',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, ColorScheme colorScheme, BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsCard(ColorScheme colorScheme, BuildContext context) {
    // Use actual ingredients from recipe data from Firebase
    final ingredients = recipe.ingredients.isNotEmpty 
      ? recipe.ingredients 
      : ['No ingredients information available'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ll need:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...ingredients.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 12, top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(ColorScheme colorScheme, BuildContext context) {
    // Use actual nutrition data from recipe from Firebase
    final nutritionData = recipe.nutrition.isNotEmpty 
      ? recipe.nutrition 
      : {'Info': 'No nutrition information available'};

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Per Serving:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 8,
              ),
              itemCount: nutritionData.length,
              itemBuilder: (context, index) {
                final entry = nutritionData.entries.elementAt(index);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        entry.value,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookingInstructionsCard(ColorScheme colorScheme, BuildContext context) {
    // Use actual instructions from recipe data from Firebase
    final instructions = recipe.instructions.isNotEmpty 
      ? recipe.instructions 
      : ['No cooking instructions available'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Prep Time: 15 minutes',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Instructions:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...instructions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 12, top: 2),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthBenefitsCard(ColorScheme colorScheme, BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Why this is good for you:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recipe.healthBenefit ?? 'This recipe provides essential nutrients for your health.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergenCard(ColorScheme colorScheme, BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, size: 20, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Allergen Warning:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This recipe contains: ${recipe.allergens.join(', ')}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthConsiderationsCard(ColorScheme colorScheme, BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.goodForDiseases.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.check_circle, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Good for:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recipe.goodForDiseases.join(', '),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            if (recipe.badForDiseases.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.cancel, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Avoid if you have:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recipe.badForDiseases.join(', '),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}