import 'package:flutter/material.dart';

import '../cubit/home_state.dart';

/// Hàng chip lọc topic: Phổ biến / Ảnh hưởng / Chất lượng / Theo lĩnh vực.
class TopicFilterBar extends StatelessWidget {
  final TopicSortFilter selected;
  final ValueChanged<TopicSortFilter> onChanged;

  const TopicFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: TopicSortFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = TopicSortFilter.values[i];
          final isSel = f == selected;
          return ChoiceChip(
            label: Text(f.label),
            selected: isSel,
            onSelected: (_) => onChanged(f),
            backgroundColor: cs.surfaceContainerHighest,
            selectedColor: cs.primary,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
              color: isSel ? cs.onPrimary : cs.onSurface,
            ),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
          );
        },
      ),
    );
  }
}
