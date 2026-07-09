import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../publication/domain/entities/topic.dart';
import '../../../shared/presentation/cubit/selected_topic_cubit.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/topic_card.dart';
import '../widgets/topic_charts.dart';
import '../widgets/topic_filter_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>(
      create: (_) => getIt<HomeCubit>()..initialize(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  void _selectTopic(BuildContext context, Topic topic) {
    context.read<SelectedTopicCubit>().select(topic);
    context.go('/journal');
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCubit>();
    final selectedId = context.watch<SelectedTopicCubit>().state?.id;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SearchBarWidget(onSearch: cubit.search),
              ),
            ),
            SliverToBoxAdapter(
              child: TopicFilterBar(
                selected: state.filter,
                onChanged: cubit.changeFilter,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ..._buildContent(context, state, cubit, selectedId),
          ],
        );
      },
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
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    HomeState state,
    HomeCubit cubit,
    String? selectedId,
  ) {
    if (state is HomeLoading) {
      return [
        const SliverFillRemaining(
          child: LoadingWidget(message: 'Loading topics…'),
        ),
      ];
    }

    if (state is HomeError) {
      return [
        SliverFillRemaining(
          child: ErrorStateWidget(message: state.message, onRetry: cubit.retry),
        ),
      ];
    }

    if (state is HomeLoaded) {
      if (state.topics.isEmpty) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
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
        ];
      }

      final byField = state.filter == TopicSortFilter.byField;
      return [
        SliverToBoxAdapter(
          child: TopicChartsSection(
            topics: state.topics,
            onSelect: (t) => _selectTopic(context, t),
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
            itemCount: state.topics.length,
            itemBuilder: (context, i) {
              final t = state.topics[i];
              return TopicCard(
                topic: t,
                isSelected: t.id == selectedId,
                onTap: () => _selectTopic(context, t),
              );
            },
          ),
        _buildFooter(context, state, cubit),
      ];
    }

    return [const SliverToBoxAdapter(child: SizedBox.shrink())];
  }

  Widget _buildFooter(BuildContext context, HomeLoaded state, HomeCubit cubit) {
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
              onPressed: cubit.loadMore,
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
                  onTap: () => _selectTopic(context, t),
                );
              },
            ),
          ],
        ),
    ];
  }
}
