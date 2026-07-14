import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../../core/constants/widget_keys.dart';
import '../../../publication/domain/entities/journal_summary.dart';
import '../../../publication/domain/entities/topic.dart';
import '../../../shared/presentation/viewmodels/selected_topic_viewmodel.dart';
import '../viewmodels/journal_state.dart';
import '../viewmodels/journal_viewmodel.dart';
import '../widgets/journal_card.dart';
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
    Future.microtask(() {
      final topic = ref.read(selectedTopicProvider);
      if (topic != null) {
        ref.read(journalViewModelProvider.notifier).loadByTopic(topic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedTopicProvider, (_, topic) {
      final viewModel = ref.read(journalViewModelProvider.notifier);
      topic == null ? viewModel.clear() : viewModel.loadByTopic(topic);
    });
    final selected = ref.watch(selectedTopicProvider);
    final state = ref.watch(journalViewModelProvider);

    // Branch IndexedStack có thể mount sau khi topic đã chọn — listen bỏ lỡ
    // update đó. Bù bằng load khi còn Initial mà topic đã có.
    if (selected != null && state is JournalInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(journalViewModelProvider) is! JournalInitial) return;
        final topic = ref.read(selectedTopicProvider);
        if (topic != null) {
          ref.read(journalViewModelProvider.notifier).loadByTopic(topic);
        }
      });
    }

    return CustomScrollView(
      key: WidgetKeys.journalsScreen,
      slivers: [_appBar(context, state), ..._bodySlivers(context, state)],
    );
  }

  Topic? _topicFor(JournalState state) => switch (state) {
    JournalLoading s => s.topic,
    JournalLoaded s => s.topic,
    JournalEmpty s => s.topic,
    JournalError s => s.topic,
    JournalInitial() => null,
  };

  Widget _appBar(BuildContext context, JournalState state) {
    final topic = _topicFor(state);
    final colors = Theme.of(context).colorScheme;
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: topic == null ? 64 : 76,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Journals'),
          if (topic != null)
            Text(
              'Topic: ${topic.displayName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      actions: [
        if (topic != null)
          IconButton(
            tooltip: 'Refresh journals',
            onPressed:
                state is JournalLoading ||
                    (state is JournalLoaded && state.isRefreshing)
                ? null
                : ref.read(journalViewModelProvider.notifier).refresh,
            icon: const Icon(Icons.refresh),
          ),
      ],
    );
  }

  List<Widget> _bodySlivers(BuildContext context, JournalState state) {
    final viewModel = ref.read(journalViewModelProvider.notifier);
    return switch (state) {
      JournalInitial() => [
        _messageState(
          context,
          icon: Icons.topic_outlined,
          title: 'Choose a research topic',
          message: 'Select a topic to analyse its leading academic journals.',
          actionLabel: 'Explore topics',
          onAction: () => context.go('/home'),
        ),
      ],
      JournalLoading() => [_loadingState(context)],
      JournalError s => [
        _messageState(
          context,
          icon: Icons.cloud_off_outlined,
          title: 'Unable to load journals',
          message: s.message,
          actionLabel: 'Try again',
          onAction: () => viewModel.loadByTopic(s.topic),
        ),
      ],
      JournalEmpty() => [
        _messageState(
          context,
          icon: Icons.library_books_outlined,
          title: 'No journals found',
          message:
              'This topic may not have journal source metadata in OpenAlex.',
          actionLabel: 'Choose another topic',
          onAction: () => context.go('/home'),
        ),
      ],
      JournalLoaded s => _loadedSlivers(context, s),
    };
  }

  List<Widget> _loadedSlivers(BuildContext context, JournalLoaded state) {
    final padding = MediaQuery.sizeOf(context).width >= 600 ? 24.0 : 16.0;
    return [
      if (state.isRefreshing)
        const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2)),
      if (state.refreshError != null)
        SliverToBoxAdapter(
          child: _InlineWarning(
            message: state.refreshError!,
            onRetry: ref.read(journalViewModelProvider.notifier).refresh,
          ),
        ),
      SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: EdgeInsets.fromLTRB(padding, 8, padding, 24),
              child: _KpiStrip(key: WidgetKeys.journalsKpiStrip, state: state),
            ),
          ),
        ),
      ),
      SliverLayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.crossAxisExtent >= 600;
          final sorted = state.sortedJournals;
          final contributionJournals = [...state.journals]
            ..sort((a, b) {
              final count = b.publicationCount.compareTo(a.publicationCount);
              if (count != 0) return count;
              return a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              );
            });
          final content = isTablet
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _ContributionCard(journals: contributionJournals),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 7,
                      child: _RankingSection(
                        journals: sorted,
                        sort: state.sort,
                        onSortChanged: ref
                            .read(journalViewModelProvider.notifier)
                            .setSort,
                        onOpen: (journal) => _openJournal(context, journal),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _ContributionCard(journals: contributionJournals),
                    const SizedBox(height: 24),
                    _RankingSection(
                      journals: sorted,
                      sort: state.sort,
                      onSortChanged: ref
                          .read(journalViewModelProvider.notifier)
                          .setSort,
                      onOpen: (journal) => _openJournal(context, journal),
                    ),
                  ],
                );
          return SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, 32),
                  child: content,
                ),
              ),
            ),
          );
        },
      ),
      if (state.hasEstimatedCitations)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding, 0, padding, 28),
            child: Text(
              '* Citation totals for journals with more than 200 topic works are estimates from a deterministic 200-work sample.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ];
  }

  void _openJournal(BuildContext context, JournalSummary journal) {
    if (!journal.hasValidId) return;
    context.push(
      '/journal/journal-detail/${Uri.encodeComponent(journal.shortId)}',
      extra: journal,
    );
  }

  Widget _messageState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingState(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                for (var i = 0; i < 2; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: _Skeleton(height: 84, color: color)),
                ],
              ],
            ),
            const SizedBox(height: 24),
            _Skeleton(height: 240, color: color),
            const SizedBox(height: 24),
            for (var i = 0; i < 5; i++) ...[
              _Skeleton(height: 96, color: color),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _KpiStrip extends StatelessWidget {
  final JournalLoaded state;

  const _KpiStrip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Journals analysed',
        state.journals.length,
        Icons.library_books_outlined,
      ),
      ('Publications', state.totalPublications, Icons.article_outlined),
      ('Citations', state.totalCitations, Icons.format_quote_outlined),
      ('Average citations', state.averageCitations, Icons.analytics_outlined),
    ];
    if (MediaQuery.sizeOf(context).width >= 600) {
      return Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: _KpiCard(data: items[i])),
          ],
        ],
      );
    }
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (_, index) =>
            SizedBox(width: 132, child: _KpiCard(data: items[index])),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final (String, num, IconData) data;

  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final (label, value, icon) = data;
    final visualValue = value is double
        ? value.toStringAsFixed(1)
        : NumberFormatter.compact(value);
    return Semantics(
      label: '$label, $value',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visualValue,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  final List<JournalSummary> journals;

  const _ContributionCard({required this.journals});

  @override
  Widget build(BuildContext context) {
    final total = journals.fold<int>(
      0,
      (sum, journal) => sum + journal.publicationCount,
    );
    final top = journals.take(5).toList();
    final otherCount = journals
        .skip(5)
        .fold<int>(0, (sum, journal) => sum + journal.publicationCount);
    final topCount = top.fold<int>(
      0,
      (sum, item) => sum + item.publicationCount,
    );
    final rows = <(String, int)>[
      ...top.map((journal) => (journal.displayName, journal.publicationCount)),
      if (otherCount > 0) ('Other', otherCount),
    ];
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'JOURNAL CONTRIBUTION',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < rows.length; i++) ...[
              _ContributionRow(
                label: rows[i].$1,
                count: rows[i].$2,
                total: total,
                color: i == 0
                    ? colors.secondary
                    : (rows[i].$1 == 'Other'
                          ? colors.onSurfaceVariant
                          : colors.primary),
              ),
              if (i < rows.length - 1) const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            Text(
              'Top 5 journals contribute ${total == 0 ? 0 : topCount * 100 ~/ total}% of analysed publications.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributionRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _ContributionRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0.0 : count / total;
    return Semantics(
      label:
          '$label, $count publications, ${(percentage * 100).toStringAsFixed(1)} percent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('${(percentage * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 5),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 350),
            tween: Tween(begin: 0, end: percentage),
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: value,
                color: color,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$count publications',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _RankingSection extends StatelessWidget {
  final List<JournalSummary> journals;
  final JournalSort sort;
  final ValueChanged<JournalSort> onSortChanged;
  final ValueChanged<JournalSummary> onOpen;

  const _RankingSection({
    required this.journals,
    required this.sort,
    required this.onSortChanged,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: WidgetKeys.journalsList,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'TOP JOURNALS',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            JournalFilterBar(sort: sort, onSortChanged: onSortChanged),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < journals.length; i++) ...[
          JournalCard(
            key: WidgetKeys.journalCard(i),
            journal: journals[i],
            rank: i + 1,
            onTap: journals[i].hasValidId ? () => onOpen(journals[i]) : null,
          ),
          if (i < journals.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _InlineWarning extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineWarning({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(message),
      leading: const Icon(Icons.warning_amber_outlined),
      actions: [TextButton(onPressed: onRetry, child: const Text('Retry'))],
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  final Color color;

  const _Skeleton({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
