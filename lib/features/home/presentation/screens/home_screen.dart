import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/widget_keys.dart';
import '../../../../core/router/work_detail_navigation.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../publication/domain/entities/topic.dart';
import '../../../publication/domain/entities/work.dart';
import '../../../publication/presentation/widgets/trend_chart.dart';
import '../../../shared/presentation/viewmodels/selected_topic_viewmodel.dart';
import '../viewmodels/home_dashboard_state.dart';
import '../viewmodels/home_dashboard_viewmodel.dart';
import '../viewmodels/home_state.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/home_kpi_grid.dart';
import '../widgets/notification_bell_button.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/topic_card.dart';
import '../widgets/topic_charts.dart';
import '../widgets/topic_filter_bar.dart';
import '../widgets/work_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      // `initialize()` tự bỏ qua nếu state không còn là HomeInitial, nên quay lại
      // tab Home không nạp lại danh sách.
      ref.read(homeViewModelProvider.notifier).initialize();

      // Topic đã chọn từ phiên trước (hoặc từ tab khác) → dựng lại dashboard.
      final selected = ref.read(selectedTopicProvider);
      final dashboard = ref.read(homeDashboardViewModelProvider);
      if (selected != null && dashboard is HomeDashboardInitial) {
        ref.read(homeDashboardViewModelProvider.notifier).loadByTopic(selected);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Chọn topic → nạp dashboard ngay tại Home (FR 4.2). Journals/Keywords cũng
  /// lắng nghe [selectedTopicProvider] nên hai tab kia tự cập nhật theo.
  void _selectTopic(Topic topic) {
    ref.read(selectedTopicProvider.notifier).select(topic);
    ref.read(homeDashboardViewModelProvider.notifier).loadByTopic(topic);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _clearTopic() {
    ref.read(selectedTopicProvider.notifier).clear();
    ref.read(homeDashboardViewModelProvider.notifier).clear();
  }

  void _openPublication(Work work) => openWorkDetailFromHome(context, work);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final dashboard = ref.watch(homeDashboardViewModelProvider);
    final selectedId = ref.watch(selectedTopicProvider)?.id;

    return CustomScrollView(
      key: WidgetKeys.homeScreen,
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBarWidget(onSearch: viewModel.search),
          ),
        ),
        ..._buildDashboard(context, dashboard),
        SliverToBoxAdapter(
          child: TopicFilterBar(
            selected: state.filter,
            onChanged: viewModel.changeFilter,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ..._buildContent(context, state, viewModel, selectedId),
      ],
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SliverAppBar(
      pinned: true,
      stretch: false,
      floating: false,
      snap: false,
      toolbarHeight: 72,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: cs.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      titleSpacing: 16,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Explore Topics',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Explore research topics',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ],
      ),
      actions: const [
        NotificationBellButton(),
        SizedBox(width: 4),
      ],
    );
  }

  // ── Dashboard của topic đã chọn (FR 4.2) ────────────────────────────

  List<Widget> _buildDashboard(BuildContext context, HomeDashboardState state) {
    switch (state) {
      case HomeDashboardInitial():
        return const [];

      case HomeDashboardLoading(:final topic):
        return [
          SliverToBoxAdapter(
            child: _DashboardHeader(topic: topic, onClear: _clearTopic),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              key: WidgetKeys.homeDashboardLoading,
              height: 220,
              child: LoadingWidget(message: 'Building dashboard…'),
            ),
          ),
        ];

      case HomeDashboardError(:final topic, :final message):
        return [
          SliverToBoxAdapter(
            child: _DashboardHeader(topic: topic, onClear: _clearTopic),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              key: WidgetKeys.homeDashboardError,
              height: 220,
              child: ErrorStateWidget(
                message: message,
                onRetry: ref.read(homeDashboardViewModelProvider.notifier).retry,
              ),
            ),
          ),
        ];

      case HomeDashboardEmpty(:final topic):
        return [
          SliverToBoxAdapter(
            child: _DashboardHeader(topic: topic, onClear: _clearTopic),
          ),
          SliverToBoxAdapter(
            child: Padding(
              key: WidgetKeys.homeDashboardEmpty,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Text(
                'No publications found for "${topic.displayName}".',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ];

      case HomeDashboardLoaded(
        :final summary,
        :final trend,
        :final publications,
        :final trendWarning,
      ):
        final influential = summary.mostInfluentialPublication;
        return [
          SliverToBoxAdapter(
            child: _DashboardHeader(
              topic: summary.topic,
              onClear: _clearTopic,
              sampleSize: summary.sampleSize,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              key: WidgetKeys.homeDashboard,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: HomeKpiGrid(
                summary: summary,
                onOpenMostInfluential: influential == null
                    ? null
                    : () => _openPublication(influential),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: WidgetKeys.homeTrendChart,
              child: TrendChart(
                trend: trend,
                title: 'Publication trend · ${summary.topic.displayName}',
              ),
            ),
          ),
          if (trendWarning != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  trendWarning,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Publications',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SliverList.builder(
            key: WidgetKeys.homePublications,
            itemCount: publications.length,
            itemBuilder: (context, i) => KeyedSubtree(
              key: WidgetKeys.homePublication(i),
              child: WorkCard(
                work: publications[i],
                onTap: () => _openPublication(publications[i]),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 32)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                'Browse other topics',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ];
    }
  }

  // ── Danh sách topic (search / duyệt) ────────────────────────────────

  List<Widget> _buildContent(
    BuildContext context,
    HomeState state,
    HomeViewModel viewModel,
    String? selectedId,
  ) {
    if (state is HomeLoading) {
      return [
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 240,
            child: LoadingWidget(message: 'Loading topics…'),
          ),
        ),
      ];
    }

    if (state is HomeError) {
      return [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 240,
            child: ErrorStateWidget(
              message: state.message,
              onRetry: viewModel.retry,
            ),
          ),
        ),
      ];
    }

    if (state is HomeLoaded) {
      if (state.topics.isEmpty) {
        return [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 240,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off, size: 56, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      state.query != null
                          ? 'No topics found for "${state.query}"'
                          : 'No topics available.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ];
      }

      final byField = state.filter == TopicSortFilter.byField;
      return [
        SliverToBoxAdapter(
          child: TopicChartsSection(
            topics: state.topics,
            onSelect: _selectTopic,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text(
              byField
                  ? 'Topics by field'
                  : '${state.topics.length} / ${state.total} topics',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (byField)
          ..._buildGroupedByField(context, state.topics, selectedId)
        else
          SliverList.builder(
            key: WidgetKeys.homeTopicList,
            itemCount: state.topics.length,
            itemBuilder: (context, i) {
              final t = state.topics[i];
              return TopicCard(
                key: WidgetKeys.homeTopic(i),
                topic: t,
                isSelected: t.id == selectedId,
                onTap: () => _selectTopic(t),
              );
            },
          ),
        _buildFooter(context, state, viewModel),
      ];
    }

    return [const SliverToBoxAdapter(child: SizedBox.shrink())];
  }

  Widget _buildFooter(
    BuildContext context,
    HomeLoaded state,
    HomeViewModel viewModel,
  ) {
    if (state.isLoadingMore) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }
    if (state.hasMore) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Center(
            child: TextButton.icon(
              onPressed: viewModel.loadMore,
              icon: const Icon(Icons.expand_more),
              label: const Text('Load More Results'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      );
    }
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Center(
          child: Text(
            '— End of topics —',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedByField(
    BuildContext context,
    List<Topic> topics,
    String? selectedId,
  ) {
    final groups = <String, List<Topic>>{};
    for (final t in topics) {
      groups
          .putIfAbsent(t.fieldName ?? t.domainName ?? 'Other', () => [])
          .add(t);
    }
    final entries = groups.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return [
      for (final e in entries)
        SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                child: Text(
                  e.key,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            SliverList.builder(
              itemCount: e.value.length,
              itemBuilder: (context, i) {
                final t = e.value[i];
                return TopicCard(
                  topic: t,
                  isSelected: t.id == selectedId,
                  onTap: () => _selectTopic(t),
                );
              },
            ),
          ],
        ),
    ];
  }
}

/// Tiêu đề dashboard: topic đang xem + nút bỏ chọn để quay về danh sách.
class _DashboardHeader extends StatelessWidget {
  final Topic topic;
  final VoidCallback onClear;
  final int? sampleSize;

  const _DashboardHeader({
    required this.topic,
    required this.onClear,
    this.sampleSize,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  topic.displayName,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sampleSize == null
                      ? 'Topic dashboard'
                      : 'Topic dashboard · sample of $sampleSize papers',
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
