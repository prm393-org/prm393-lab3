import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/work_detail_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../publication/presentation/widgets/trend_chart.dart';
import '../../../publication/presentation/widgets/work_card.dart';
import '../../../shared/presentation/viewmodels/selected_topic_viewmodel.dart';
import '../viewmodels/journal_state.dart';
import '../viewmodels/journal_viewmodel.dart';
import '../widgets/journal_filter_bar.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  @override
  void initState() {
    super.initState();
    // Topic đã chọn từ trước khi tab này được dựng lần đầu.
    Future.microtask(() {
      final selected = ref.read(selectedTopicProvider);
      if (selected != null) {
        ref.read(journalViewModelProvider.notifier).loadByTopic(selected);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Topic đổi trong lúc tab đang sống (IndexedStack giữ tab mounted).
    ref.listen(selectedTopicProvider, (_, topic) {
      final viewModel = ref.read(journalViewModelProvider.notifier);
      if (topic != null) {
        viewModel.loadByTopic(topic);
      } else {
        viewModel.clear();
      }
    });

    final state = ref.watch(journalViewModelProvider);

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [_buildAppBar(context, state), _buildBody(context, state)],
    );
  }

  Widget _buildAppBar(BuildContext context, JournalState state) {
    final topic = switch (state) {
      JournalLoading s => s.topic,
      JournalLoaded s => s.topic,
      JournalError s => s.topic,
      _ => null,
    };
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SliverAppBar(
      pinned: true,
      stretch: false,
      floating: false,
      snap: false,
      toolbarHeight: topic != null && topic.fieldName != null ? 72 : 64,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: cs.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      titleSpacing: 16,
      centerTitle: false,
      actions: [
        if (state is JournalLoaded)
          IconButton(
            icon: Icon(Icons.refresh, color: cs.onSurface),
            tooltip: 'Reload',
            onPressed: () => ref
                .read(journalViewModelProvider.notifier)
                .loadByTopic(state.topic),
          ),
      ],
      title: topic != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  topic.displayName,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (topic.fieldName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    topic.fieldName!,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            )
          : Text(
              'Papers',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                height: 1.2,
              ),
            ),
    );
  }

  Widget _buildBody(BuildContext context, JournalState state) {
    final viewModel = ref.read(journalViewModelProvider.notifier);

    if (state is JournalInitial) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.touch_app_outlined,
                    size: 48,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No topic selected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Go to the Home tab and select a topic\nto browse papers.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.search),
                  label: const Text('Find topics'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state is JournalLoading) {
      return const SliverFillRemaining(
        child: LoadingWidget(message: 'Loading papers…'),
      );
    }

    if (state is JournalError) {
      return SliverFillRemaining(
        child: ErrorStateWidget(
          message: state.message,
          onRetry: () => viewModel.loadByTopic(state.topic),
        ),
      );
    }

    if (state is JournalLoaded) {
      final isRefreshing = state.works.isEmpty && state.isLoadingMore;
      return SliverMainAxisGroup(
        slivers: [
          if (state.trend.length >= 2)
            SliverToBoxAdapter(child: TrendChart(trend: state.trend)),
          SliverToBoxAdapter(
            child: JournalFilterBar(
              years: state.availableYears,
              selectedYear: state.year,
              sort: state.sort,
              onYearChanged: viewModel.setYear,
              onSortChanged: viewModel.setSort,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${state.works.length} / ${state.total} papers',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Sort: ${state.sort.label}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isRefreshing)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
            )
          else if (state.works.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text('No papers match the current filters.'),
                ),
              ),
            ),
          SliverList.builder(
            itemCount: state.works.length,
            itemBuilder: (context, i) => WorkCard(
              work: state.works[i],
              onTap: () => openWorkDetail(context, state.works[i]),
            ),
          ),
          if (state.isLoadingMore && state.works.isNotEmpty)
            const SliverToBoxAdapter(
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
            )
          else if (state.works.isNotEmpty && state.hasMore)
            SliverToBoxAdapter(
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
            )
          else if (state.works.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Center(
                  child: Text(
                    '— End of papers —',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
}
