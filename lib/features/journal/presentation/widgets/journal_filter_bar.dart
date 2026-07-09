import 'package:flutter/material.dart';

import '../cubit/journal_state.dart';

/// Thanh bộ lọc: nút "Bộ lọc" (chọn năm), chip năm đang chọn (xoá được),
/// và menu sắp xếp — bố cục theo thiết kế.
class JournalFilterBar extends StatelessWidget {
  final List<int> years;
  final int? selectedYear;
  final WorkSortOption sort;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<WorkSortOption> onSortChanged;

  const JournalFilterBar({
    super.key,
    required this.years,
    required this.selectedYear,
    required this.sort,
    required this.onYearChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        children: [
          // Nút "Bộ lọc" — mở menu chọn năm.
          _FilterButton(
            years: years,
            selectedYear: selectedYear,
            onYearChanged: onYearChanged,
          ),
          if (selectedYear != null) ...[
            const SizedBox(width: 8),
            // Chip năm đang chọn, có nút xoá.
            InputChip(
              label: Text('Year: $selectedYear'),
              onDeleted: () => onYearChanged(null),
              deleteIcon: const Icon(Icons.close, size: 16),
              backgroundColor: primary.withValues(alpha: 0.08),
              side: BorderSide(color: primary.withValues(alpha: 0.4)),
              labelStyle: TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              deleteIconColor: primary,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
          const SizedBox(width: 8),
          // Menu sắp xếp.
          PopupMenuButton<WorkSortOption>(
            tooltip: 'Sort',
            splashRadius: 0,
            position: PopupMenuPosition.under,
            onSelected: onSortChanged,
            itemBuilder: (_) => [
              for (final option in WorkSortOption.all)
                PopupMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      Icon(
                        option == sort
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: option == sort ? primary : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Text(option.label),
                    ],
                  ),
                ),
            ],
            child: _Pill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sort: ${sort.label}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final List<int> years;
  final int? selectedYear;
  final ValueChanged<int?> onYearChanged;

  const _FilterButton({
    required this.years,
    required this.selectedYear,
    required this.onYearChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    // Trả về: -1 = "Tất cả các năm", >0 = năm cụ thể, null = đóng/không chọn.
    final result = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _YearPickerSheet(years: years, selectedYear: selectedYear),
    );
    if (result == null) return; // người dùng đóng sheet, giữ nguyên
    onYearChanged(result == -1 ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openPicker(context),
      child: _Pill(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.tune, size: 16),
            SizedBox(width: 6),
            Text(
              'Filters',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet chọn năm — cuộn mượt kể cả khi có rất nhiều năm.
class _YearPickerSheet extends StatelessWidget {
  final List<int> years;
  final int? selectedYear;

  const _YearPickerSheet({required this.years, required this.selectedYear});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.tune, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Filter by publication year',
                    style:
                        tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  _YearTile(
                    label: 'All years',
                    selected: selectedYear == null,
                    onTap: () => Navigator.pop(context, -1),
                  ),
                  for (final year in years)
                    _YearTile(
                      label: '$year',
                      selected: year == selectedYear,
                      onTap: () => Navigator.pop(context, year),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _YearTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        size: 20,
        color: selected ? cs.primary : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? cs.primary : null,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _Pill extends StatelessWidget {
  final Widget child;
  const _Pill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}
