import 'package:flutter/material.dart';

import '../viewmodels/journal_state.dart';

class JournalFilterBar extends StatelessWidget {
  final JournalSort sort;
  final ValueChanged<JournalSort> onSortChanged;

  const JournalFilterBar({
    super.key,
    required this.sort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<JournalSort>(
      key: const Key('journal_sort'),
      tooltip: 'Sort journals by ${sort.label}',
      initialValue: sort,
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        for (final option in JournalSort.values)
          PopupMenuItem(value: option, child: Text(option.label)),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(sort.label),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
