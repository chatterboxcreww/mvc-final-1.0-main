// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\home\widgets\feed_section.dart

// lib/features/home/widgets/feed_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/activity.dart';
import '../../../core/models/curated_content_item.dart';
import '../../../core/models/user_data.dart';
import '../../../core/models/app_enums.dart';
import '../../../core/providers/activity_provider.dart';
import '../../../core/providers/curated_content_provider.dart';
import '../../../core/providers/experience_provider.dart';
import '../../../core/providers/step_counter_provider.dart';
import '../../../core/providers/trends_provider.dart';
import '../../../core/providers/user_data_provider.dart';
import '../../../core/providers/achievement_provider.dart'; // Added import
import '../../../core/providers/comment_provider.dart'; // Added import
import '../../../shared/widgets/animated_list_item.dart';
import '../../../shared/widgets/glass_container.dart';
import 'coach_insight_card.dart';
import 'daily_checkin_card.dart';
import 'leaderboard_card.dart';
import 'recipe_detail_screen.dart';
// import 'comment_section.dart'; // Removed import

class FeedSection extends StatefulWidget {
  const FeedSection({super.key});

  @override
  State<FeedSection> createState() => _FeedSectionState();
}

class _FeedSectionState extends State<FeedSection> {
  String? selectedCoffeeType;
  String? selectedTeaType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final trendsProvider = context.read<TrendsProvider>();
        final stepHistory = context.read<StepCounterProvider>().weeklyStepData;
        trendsProvider.generateCoachInsight(stepHistory);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserDataProvider>().userData;
    final curatedContentProvider = context.watch<CuratedContentProvider>();
    final trendsProvider = context.watch<TrendsProvider>();

    final List<CuratedContentItem> filteredCuratedContent =
    curatedContentProvider.getFilteredContent(userData);
    final List<Widget> healthAdviceWidgets =
    _buildStaticHealthAdvice(context, userData);

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.04;
    
    return RefreshIndicator(
      onRefresh: () async {
        try {
          await context.read<CuratedContentProvider>().refreshFeed();
          if (mounted) {
            final stepHistory = context.read<StepCounterProvider>().weeklyStepData;
            context.read<TrendsProvider>().generateCoachInsight(stepHistory);
          }
        } catch (e) {
          print('Error refreshing feed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to refresh feed. Please try again.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
        children: [
          // Health Advice Section Header
          if (healthAdviceWidgets.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.health_and_safety_outlined, 
                     color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Personalized Health Tips',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Based on your health profile',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          ...healthAdviceWidgets.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: AnimatedListItem(index: entry.key + 2, child: entry.value),
            );
          }),
          const SizedBox(height: 24),
          _buildCuratedFeedHeader(context),
          const SizedBox(height: 8),
          _buildCuratedFeedBody(
              context, filteredCuratedContent, curatedContentProvider),
        ],
      ),
    );
  }

  Widget _buildCuratedFeedHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.auto_awesome_outlined, color: colorScheme.tertiary),
        const SizedBox(width: 8),
        Text(
          'Today\'s Feed',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCuratedFeedBody(BuildContext context,
      List<CuratedContentItem> content, CuratedContentProvider provider) {
    if (content.isNotEmpty) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: content.length,
        itemBuilder: (context, index) {
          try {
            return AnimatedListItem(
              index: index,
              child: _buildCuratedCard(context, content[index]),
            );
          } catch (e) {
            print('Error building curated card at index $index: $e');
            return GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unable to load this item',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      );
    } else {
      final int currentHour = DateTime.now().hour;
      String message;
      IconData icon;
      
      if (!provider.isContentAvailable) {
        message = "Today's feed is being prepared...\nPull down to refresh.";
        icon = Icons.refresh;
      } else if (currentHour >= 4 && currentHour < 11) {
        message = "No breakfast items match your profile today.\nCheck back after 11 AM for lunch!";
        icon = Icons.free_breakfast_outlined;
      } else if (currentHour >= 11 && currentHour < 17) {
        message = "No lunch items match your profile right now.\nCheck back after 5 PM for dinner!";
        icon = Icons.lunch_dining_outlined;
      } else {
        message = "That's all for today!\nA fresh feed will be ready for you tomorrow morning.";
        icon = Icons.dinner_dining_outlined;
      }
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCuratedCard(BuildContext context, CuratedContentItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Validate item data
    if (item.title.isEmpty) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: colorScheme.error),
              const SizedBox(width: 8),
              Text(
                'Invalid recipe data',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Consumer<ActivityProvider>(
      builder: (context, provider, child) {
        final bool isAdded =
        provider.containsActivity(label: item.title, type: 'CuratedIdea');
        IconData leadingIconData;

        if (item.category.toLowerCase().contains('food') || 
            item.category.toLowerCase().contains('coffee') ||
            item.category.toLowerCase().contains('tea')) {
          leadingIconData = Icons.restaurant_menu_outlined;
        } else if (item.category.toLowerCase().contains('exercise')) {
          leadingIconData = Icons.fitness_center_outlined;
        } else {
          leadingIconData = Icons.lightbulb_outline;
        }

        return GlassCard(
          child: ExpansionTile(
            key: PageStorageKey(item.id),
            leading: item.imagePlaceholder != null &&
                item.imagePlaceholder!.startsWith('assets/')
                ? ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset(item.imagePlaceholder!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(leadingIconData,
                            size: 36, color: colorScheme.tertiary)))
                : Icon(leadingIconData, size: 36, color: colorScheme.tertiary),
            title: Text(item.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: isAdded
                  ? Icon(Icons.check_circle, color: colorScheme.primary)
                  : Icon(Icons.add_task_outlined, color: colorScheme.secondary),
              tooltip: isAdded
                  ? "Remove from today's tasks"
                  : "Add to today's tasks",
              onPressed: () {
                final activityProvider = context.read<ActivityProvider>();
                final experienceProvider = context.read<ExperienceProvider>();
                final userDataProvider = context.read<UserDataProvider>();
                
                if (isAdded) {
                  activityProvider.removeActivityByLabelAndType(
                      label: item.title, type: 'CuratedIdea');
                  
                  // Reduce XP when food item is removed from tasks
                  if (item.category.toLowerCase().contains('food')) {
                    // Determine meal type based on time of day
                    final hour = DateTime.now().hour;
                    String mealType = 'snack';
                    if (hour >= 5 && hour < 11) {
                      mealType = 'breakfast';
                    } else if (hour >= 11 && hour < 16) {
                      mealType = 'lunch';
                    } else if (hour >= 16 && hour < 22) {
                      mealType = 'dinner';
                    }
                    

                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('"${item.title}" removed from your tasks!')));
                } else {
                  final newActivity = Activity(
                      id: const Uuid().v4(),
                      label: item.title,
                      type: 'CuratedIdea',
                      isCustom: false);
                  activityProvider.addActivity(newActivity);
                  
                  // Add XP when food item is added to tasks
                  if (item.category.toLowerCase().contains('food')) {
                    // Determine meal type based on time of day
                    final hour = DateTime.now().hour;
                    String mealType = 'snack';
                    if (hour >= 5 && hour < 11) {
                      mealType = 'breakfast';
                    } else if (hour >= 11 && hour < 16) {
                      mealType = 'lunch';
                    } else if (hour >= 16 && hour < 22) {
                      mealType = 'dinner';
                    }
                    
                    // Add XP for meal using processGains
                    experienceProvider.processGains(
                      userDataProvider.userData
                    );

                    // Check achievements after XP gain
                    final achievementProvider = context.read<AchievementProvider>();
                    final stepCounterProvider = context.read<StepCounterProvider>();
                    final trendsProvider = context.read<TrendsProvider>();
                    achievementProvider.checkAchievements(
                      userDataProvider.userData,
                      stepCounterProvider.weeklyStepData,
                      trendsProvider.checkinHistory,
                      context.read<CommentProvider>().totalCommentCount,
                    );
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('"${item.title}" added to your tasks!')));
                }
              },
            ),
            childrenPadding: const EdgeInsets.all(16.0),
            children: [
              Text(item.description,
                  style: Theme.of(context).textTheme.bodyMedium),
              if (item.allergens.isNotEmpty &&
                  item.allergens.first.toLowerCase() != "none")
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("Potential Allergens: ${item.allergens.join(', ')}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                          fontStyle: FontStyle.italic)),
                ),
              const SizedBox(height: 16),
              // More Details Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailScreen(recipe: item),
                        ),
                      );
                    } catch (e) {
                      print('Error navigating to recipe details: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Unable to load recipe details'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.restaurant_menu, size: 18),
                  label: Text('More Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildStaticHealthAdvice(BuildContext context, UserData userData) {
    final colorScheme = Theme.of(context).colorScheme;
    List<Widget> widgets = [];
    
    // Prioritize medical conditions first
    if (userData.hasDiabetes == true) {
      widgets.add(_buildExpansionTile(context, 'Managing Diabetes', [
        'Monitor blood sugar as directed by your healthcare provider - timing varies by individual needs.',
        'Follow a balanced diet with consistent carbohydrate intake as recommended by your doctor.',
        'Engage in regular physical activity as approved by your healthcare team.',
        'Take medications exactly as prescribed by your healthcare provider.',
        'Maintain regular medical appointments for HbA1c monitoring and complications screening.',
        'Learn to recognize symptoms of high blood sugar (hyperglycemia) and low blood sugar (hypoglycemia).',
        'Stay hydrated with water and limit sugar-sweetened beverages.',
        'Consider diabetes education classes to learn proper self-management techniques.',
        'Keep emergency supplies (glucose tablets, glucagon) as recommended by your doctor.',
        'Maintain good foot care and inspect feet daily for cuts or changes.',
        'Get annual eye exams to screen for diabetic retinopathy.',
        'Manage stress through healthy coping strategies as stress can affect blood glucose.'
      ], Icons.bloodtype_outlined, colorScheme.error));
    }

    // Nutritional deficiencies second
    if (userData.hasProteinDeficiency == true) {
      List<String> proteinAdvice = [
        'Aim for the recommended 0.8g protein per kg body weight daily (minimum for adults).',
      ];
      
      // Add diet-specific protein sources
      if (userData.dietPreference == DietPreference.vegetarian) {
        proteinAdvice.add('Include protein sources like dairy, legumes, nuts, seeds, and plant-based proteins.');
      } else if (userData.dietPreference == DietPreference.vegan) {
        proteinAdvice.add('Include protein sources like legumes, nuts, seeds, quinoa, and plant-based proteins.');
      } else {
        proteinAdvice.add('Include protein sources like lean meats, fish, dairy, legumes, and nuts.');
      }
      
      proteinAdvice.addAll([
        'Distribute protein intake across meals for better absorption and utilization.',
        'Consider 15-30g protein per meal as suggested by nutrition guidelines.',
        'Choose complete proteins (containing all essential amino acids) when possible.',
        'Combine plant proteins (like rice and beans) to create complete amino acid profiles.',
        'Include protein-rich snacks between meals if needed to meet daily goals.',
        'Consult a registered dietitian for personalized protein recommendations.',
        'Track protein intake initially to ensure you meet your individual needs.',
        'Choose high-quality protein sources over processed protein products when possible.',
        'Consider individual factors like age, activity level, and health conditions.',
        'Discuss protein supplements with your healthcare provider if dietary intake is insufficient.'
      ]);
      
      widgets.add(_buildExpansionTile(context, 'Boosting Protein Intake', proteinAdvice, Icons.food_bank_outlined, colorScheme.primary));
    }

    // Body composition and fitness third
    if (userData.isSkinnyFat == true) {
      widgets.add(_buildExpansionTile(context, 'Body Composition & Fitness', [
        'Consult a fitness professional for a personalized exercise program.',
        'Include resistance training as recommended by fitness guidelines.',
        'Focus on compound movements that work multiple muscle groups.',
        'Ensure adequate protein intake to support muscle maintenance and growth.',
        'Prioritize 7-9 hours of quality sleep as recommended by sleep medicine guidelines.',
        'Consider combining strength training with cardiovascular exercise.',
        'Track progress through body measurements rather than weight alone.',
        'Be consistent with your exercise routine for sustainable results.',
        'Focus on proper form and technique to prevent injury.',
        'Allow adequate recovery time between intense training sessions.',
        'Maintain a balanced diet with adequate nutrients for recovery.',
        'Set realistic goals and timelines for body composition changes.',
        'Consider working with healthcare providers for comprehensive health assessment.'
      ], Icons.fitness_center_outlined, colorScheme.primary));
    }

    // Beverage preferences with enhanced dropdowns
    if (userData.prefersCoffee == true) {
      widgets.add(_buildCoffeeDropdownSection(context));
    }

    if (userData.prefersTea == true) {
      widgets.add(_buildTeaDropdownSection(context));
    }

    // Always include general wellness at the end
    widgets.add(_buildExpansionTile(context, 'Daily Wellness Essentials', [
      'Stay adequately hydrated - fluid needs vary by individual, climate, and activity level.',
      'Aim for 7-9 hours of sleep per night as recommended by sleep medicine guidelines.',
      'Practice stress management techniques like deep breathing or meditation.',
      'Take regular breaks from screens to reduce eye strain and mental fatigue.',
      'Engage in regular physical activity as recommended by health guidelines.',
      'Spend time outdoors when possible for fresh air and potential vitamin D exposure.',
      'Maintain social connections for mental and emotional well-being.',
      'Schedule regular preventive healthcare appointments and screenings.',
      'Practice good posture, especially during prolonged sitting or screen use.',
      'Limit alcohol consumption according to health guidelines and avoid tobacco use.',
      'Maintain a balanced diet with variety from all food groups.',
      'Practice good hygiene including regular handwashing.',
      'Create a consistent sleep schedule and relaxing bedtime routine.',
      'Listen to your body and rest when needed.',
      'Consult healthcare providers for personalized health advice and concerns.'
    ], Icons.spa_outlined, colorScheme.secondary));

    return widgets;
  }


  Widget _buildExpansionTile(BuildContext context, String title,
      List<String> advicePoints, IconData icon, Color iconColor) {
    return GlassCard(
      child: ExpansionTile(
        key: PageStorageKey(title),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color.fromRGBO(iconColor.red, iconColor.green, iconColor.blue, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${advicePoints.length} helpful tips',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(Theme.of(context).colorScheme.surfaceVariant.red, Theme.of(context).colorScheme.surfaceVariant.green, Theme.of(context).colorScheme.surfaceVariant.blue, 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: advicePoints.asMap().entries.map((entry) {
                final index = entry.key;
                final point = entry.value;
                return Container(
                  margin: EdgeInsets.only(bottom: index < advicePoints.length - 1 ? 12.0 : 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12.0, top: 2.0),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(iconColor.red, iconColor.green, iconColor.blue, 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: iconColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          point, 
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoffeeDropdownSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final Map<String, Map<String, dynamic>> coffeeTypes = {
      'Espresso': {
        'caffeine': '64mg per shot',
        'benefits': ['Quick energy boost', 'High antioxidant concentration', 'Enhances focus and alertness'],
        'bestTime': 'Morning or early afternoon',
        'description': 'Pure coffee shot with intense flavor and highest caffeine concentration.'
      },
      'Americano': {
        'caffeine': '95-200mg per 8oz',
        'benefits': ['Bold coffee flavor', 'Lower calorie option', 'Good for hydration'],
        'bestTime': 'Morning',
        'description': 'Espresso diluted with hot water, similar to drip coffee but more robust.'
      },
      'Latte': {
        'caffeine': '173mg per 16oz',
        'benefits': ['Calcium from milk', 'Protein content', 'Smoother taste'],
        'bestTime': 'Morning or mid-morning',
        'description': 'Espresso with steamed milk, perfect balance of coffee and dairy.'
      },
      'Cappuccino': {
        'caffeine': '173mg per 16oz',
        'benefits': ['Rich foam texture', 'Balanced flavor', 'Satisfying portion'],
        'bestTime': 'Morning',
        'description': 'Equal parts espresso, steamed milk, and foam for a classic Italian experience.'
      },
      'Cold Brew': {
        'caffeine': '150-300mg per 8oz',
        'benefits': ['Lower acidity', 'Smooth taste', 'Less bitter'],
        'bestTime': 'Any time, especially hot weather',
        'description': 'Coffee brewed with cold water over 12-24 hours for smooth, refreshing taste.'
      },
      'Mocha': {
        'caffeine': '95-175mg per 8oz',
        'benefits': ['Antioxidants from cocoa', 'Mood boosting', 'Energy and satisfaction'],
        'bestTime': 'Morning or as afternoon treat',
        'description': 'Espresso with chocolate and steamed milk, perfect for sweet coffee lovers.'
      },
    };

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(colorScheme.tertiary.red, colorScheme.tertiary.green, colorScheme.tertiary.blue, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.coffee_outlined, color: colorScheme.tertiary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coffee Types & Benefits',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Select a coffee type to learn about its benefits',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCoffeeType,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Choose a coffee type'),
                  ),
                  isExpanded: true,
                  items: coffeeTypes.keys.map((String coffeeType) {
                    return DropdownMenuItem<String>(
                      value: coffeeType,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(coffeeType),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCoffeeType = newValue;
                    });
                  },
                ),
              ),
            ),
            if (selectedCoffeeType != null) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(colorScheme.surfaceVariant.red, colorScheme.surfaceVariant.green, colorScheme.surfaceVariant.blue, 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedCoffeeType!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      coffeeTypes[selectedCoffeeType!]!['description'],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Caffeine Content',
                      coffeeTypes[selectedCoffeeType!]!['caffeine'],
                      Icons.energy_savings_leaf,
                      colorScheme,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Best Time',
                      coffeeTypes[selectedCoffeeType!]!['bestTime'],
                      Icons.access_time,
                      colorScheme,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Health Benefits:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...coffeeTypes[selectedCoffeeType!]!['benefits'].map<Widget>((benefit) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8, top: 6),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: colorScheme.tertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                benefit,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeaDropdownSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final Map<String, Map<String, dynamic>> teaTypes = {
      'Green Tea': {
        'caffeine': '25-50mg per 8oz',
        'benefits': ['Rich in catechins', 'Antioxidant properties', 'May boost metabolism', 'Supports heart health'],
        'bestTime': 'Morning or between meals',
        'description': 'Unoxidized tea leaves with delicate flavor and powerful antioxidants.'
      },
      'Black Tea': {
        'caffeine': '60-90mg per 8oz',
        'benefits': ['Highest caffeine content', 'Contains theaflavins', 'Heart health support', 'Mental alertness'],
        'bestTime': 'Morning or early afternoon',
        'description': 'Fully oxidized tea with robust flavor and highest caffeine among teas.'
      },
      'Oolong Tea': {
        'caffeine': '35-60mg per 8oz',
        'benefits': ['Partially oxidized', 'May support weight management', 'Rich flavor profile', 'Heart health benefits'],
        'bestTime': 'Afternoon',
        'description': 'Traditional Chinese tea with complex flavor between green and black tea.'
      },
      'White Tea': {
        'caffeine': '15-30mg per 8oz',
        'benefits': ['Highest antioxidant content', 'Delicate flavor', 'Anti-aging properties', 'Gentle on stomach'],
        'bestTime': 'Any time, especially evening',
        'description': 'Minimally processed tea with subtle, naturally sweet flavor.'
      },
      'Matcha': {
        'caffeine': '70mg per serving',
        'benefits': ['L-theanine for calm energy', 'Chlorophyll content', 'Sustained energy release', 'Ceremony mindfulness'],
        'bestTime': 'Morning or pre-workout',
        'description': 'Powdered whole green tea leaves for maximum nutrient absorption.'
      },
      'Chamomile Tea': {
        'caffeine': 'Caffeine-free',
        'benefits': ['Promotes relaxation', 'Sleep support', 'Anti-inflammatory', 'Digestive comfort'],
        'bestTime': 'Evening or before bed',
        'description': 'Herbal tea made from dried chamomile flowers, perfect for winding down.'
      },
      'Earl Grey': {
        'caffeine': '60-90mg per 8oz',
        'benefits': ['Bergamot oil benefits', 'Mood enhancement', 'Citrus aroma therapy', 'Classic comfort'],
        'bestTime': 'Afternoon or evening',
        'description': 'Black tea infused with bergamot oil for distinctive citrusy flavor.'
      },
      'Peppermint Tea': {
        'caffeine': 'Caffeine-free',
        'benefits': ['Digestive support', 'Refreshing taste', 'Natural breath freshener', 'Mental clarity'],
        'bestTime': 'After meals or evening',
        'description': 'Refreshing herbal tea that aids digestion and provides cooling sensation.'
      },
    };

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(colorScheme.tertiary.red, colorScheme.tertiary.green, colorScheme.tertiary.blue, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.local_cafe_outlined, color: colorScheme.tertiary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tea Varieties & Benefits',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Select a tea type to discover its health benefits',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedTeaType,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Choose a tea type'),
                  ),
                  isExpanded: true,
                  items: teaTypes.keys.map((String teaType) {
                    return DropdownMenuItem<String>(
                      value: teaType,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(teaType),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedTeaType = newValue;
                    });
                  },
                ),
              ),
            ),
            if (selectedTeaType != null) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(colorScheme.surfaceVariant.red, colorScheme.surfaceVariant.green, colorScheme.surfaceVariant.blue, 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedTeaType!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      teaTypes[selectedTeaType!]!['description'],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Caffeine Content',
                      teaTypes[selectedTeaType!]!['caffeine'],
                      Icons.energy_savings_leaf,
                      colorScheme,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Best Time',
                      teaTypes[selectedTeaType!]!['bestTime'],
                      Icons.access_time,
                      colorScheme,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Health Benefits:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...teaTypes[selectedTeaType!]!['benefits'].map<Widget>((benefit) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8, top: 6),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: colorScheme.tertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                benefit,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}
