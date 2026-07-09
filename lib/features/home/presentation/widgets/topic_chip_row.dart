import 'package:flutter/material.dart';

class TopicChipRow extends StatefulWidget {
  final void Function(String topic) onTopicSelected;

  const TopicChipRow({super.key, required this.onTopicSelected});

  @override
  State<TopicChipRow> createState() => _TopicChipRowState();
}

class _TopicChipRowState extends State<TopicChipRow> {
  static const _topics = [
    ('Artificial Intelligence', Icons.smart_toy_outlined),
    ('Machine Learning', Icons.memory_outlined),
    ('Climate Change', Icons.eco_outlined),
    ('COVID-19', Icons.coronavirus_outlined),
    ('Quantum Computing', Icons.computer_outlined),
    ('Genomics', Icons.biotech_outlined),
    ('Neural Networks', Icons.hub_outlined),
    ('Renewable Energy', Icons.bolt_outlined),
  ];

  String? _selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _topics.map((t) {
          final isSelected = _selected == t.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                t.$2,
                size: 16,
                color: isSelected ? cs.onSecondaryContainer : cs.onSurface,
              ),
              label: Text(t.$1),
              selected: isSelected,
              selectedColor: cs.secondaryContainer,
              checkmarkColor: cs.onSecondaryContainer,
              onSelected: (_) {
                setState(() => _selected = isSelected ? null : t.$1);
                if (!isSelected) widget.onTopicSelected(t.$1);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
