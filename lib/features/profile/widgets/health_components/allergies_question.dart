// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\features\profile\widgets\health_components\allergies_question.dart

// lib/features/profile/widgets/health_components/allergies_question.dart
import 'package:flutter/material.dart';

class AllergiesQuestion extends StatefulWidget {
  final List<String> allergies;
  final Function(List<String>) onAllergiesChanged;

  const AllergiesQuestion({
    super.key,
    required this.allergies,
    required this.onAllergiesChanged,
  });

  @override
  State<AllergiesQuestion> createState() => _AllergiesQuestionState();
}

class _AllergiesQuestionState extends State<AllergiesQuestion> {
  late List<String> _allergies;
  final TextEditingController _allergyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _allergies = List.from(widget.allergies);
  }

  @override
  void dispose() {
    _allergyController.dispose();
    super.dispose();
  }

  void _addAllergy() {
    if (_allergyController.text.trim().isNotEmpty) {
      if (mounted) {
        setState(() {
          if (!_allergies
              .map((a) => a.toLowerCase())
              .contains(_allergyController.text.trim().toLowerCase())) {
            _allergies.add(_allergyController.text.trim());
            widget.onAllergiesChanged(_allergies);
          }
          _allergyController.clear();
          FocusScope.of(context).unfocus();
        });
      }
    }
  }

  void _removeAllergy(int index) {
    if (mounted) {
      setState(() {
        _allergies.removeAt(index);
        widget.onAllergiesChanged(_allergies);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.no_food_outlined, color: colorScheme.primary, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Do you have any food allergies?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface
                )
              ),
            ),
          ]
        ),
        const SizedBox(height: 8),
        Text(
          'Listing allergies helps personalize content. (e.g., Peanuts, Dairy, Gluten)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant
          )
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _allergyController,
                decoration: const InputDecoration(
                  labelText: 'Type allergy here',
                  hintText: 'e.g., Peanuts'
                ),
                onSubmitted: (_) => _addAllergy(),
              )
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _addAllergy,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
              ),
            ),
          ]
        ),
        const SizedBox(height: 16),
        _allergies.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No allergies added yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant
                  )
                ),
              ),
            )
          : ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.25
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _allergies.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      leading: Icon(
                        Icons.warning_amber_rounded,
                        color: colorScheme.error
                      ),
                      title: Text(
                        _allergies[index],
                        style: TextStyle(color: colorScheme.onSurface)
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: colorScheme.error
                        ),
                        onPressed: () => _removeAllergy(index),
                      ),
                      dense: true,
                    ),
                  );
                },
              )
            ),
      ],
    );
  }
}
