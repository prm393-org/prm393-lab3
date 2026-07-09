import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/presentation/cubit/pending_search_cubit.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.hintText = 'Search topics (e.g. fusion, machine learning)…',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  static const List<String> _sampleTopics = [
    'Machine Learning',
    'Deep Learning',
    'Artificial Intelligence',
    'Natural Language Processing',
    'Computer Vision',
    'Climate Change',
    'Renewable Energy',
    'Cancer Research',
    'Genomics',
    'Neuroscience',
    'Quantum Computing',
    'Blockchain',
    'Cybersecurity',
    'Robotics',
    'Bioinformatics',
    'Nanotechnology',
  ];

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  // vị trí & kích thước dropdown, tính khi focus
  double _dropdownTop = 0;
  double _dropdownLeft = 0;
  double _dropdownWidth = 300;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _insertOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onTextChanged() => _overlayEntry?.markNeedsBuild();

  List<String> _loadRecents() {
    if (!GetIt.I.isRegistered<SharedPreferences>()) return [];
    return GetIt.I<SharedPreferences>()
            .getStringList(AppConstants.prefRecentSearches) ??
        [];
  }

  List<String> _buildSuggestions(List<String> recents) {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) {
      final extra = _sampleTopics.where((t) => !recents.contains(t)).toList();
      return [...recents, ...extra];
    }
    final matchRecent =
        recents.where((t) => t.toLowerCase().contains(q)).toList();
    final matchSample = _sampleTopics
        .where((t) => t.toLowerCase().contains(q) && !recents.contains(t))
        .toList();
    return [...matchRecent, ...matchSample];
  }

  void _insertOverlay() {
    _removeOverlay();

    // Lấy vị trí tuyệt đối của widget trên màn hình
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    _dropdownTop = offset.dy + renderBox.size.height;
    _dropdownLeft = offset.dx;
    _dropdownWidth = renderBox.size.width;

    _overlayEntry = OverlayEntry(builder: _buildOverlayWidget);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlayWidget(BuildContext overlayCtx) {
    final recents = _loadRecents();
    final suggestions = _buildSuggestions(recents);
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: _dropdownTop,
      left: _dropdownLeft,
      width: _dropdownWidth,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.darkSurfaceElevated : cs.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            shrinkWrap: true,
            itemCount: suggestions.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: cs.outlineVariant),
            itemBuilder: (_, i) {
              final t = suggestions[i];
              final isRecent = recents.contains(t);
              return ListTile(
                dense: true,
                leading: Icon(
                  isRecent ? Icons.history : Icons.tag,
                  size: 18,
                  color: isRecent ? cs.onSurfaceVariant : cs.primary,
                ),
                title: Text(t, style: const TextStyle(fontSize: 14)),
                onTap: () {
                  _controller.text = t;
                  _focusNode.unfocus();
                  widget.onSearch(t);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _submit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _focusNode.unfocus();
    widget.onSearch(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor =
        isDark ? AppColors.darkSurfaceMuted : const Color(0xFFE2E8F0);
    final borderColor =
        isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1);

    return BlocListener<PendingSearchCubit, String?>(
      listenWhen: (_, current) => current != null,
      listener: (context, query) {
        if (query == null) return;
        // Yêu cầu tìm từ nơi khác (vd: lịch sử ở Profile): điền sẵn & tìm.
        _controller.text = query;
        _focusNode.unfocus();
        widget.onSearch(query);
        context.read<PendingSearchCubit>().clear();
      },
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onSubmitted: _submit,
        textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (_, v, _) => v.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearch('');
                  },
                ),
        ),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
