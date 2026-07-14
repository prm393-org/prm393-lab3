import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/widget_keys.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../publication/domain/entities/journal_summary.dart';
import '../../../publication/domain/entities/work.dart';
import '../viewmodels/journal_detail_state.dart';
import '../viewmodels/journal_detail_viewmodel.dart';

class JournalDetailScreen extends ConsumerStatefulWidget {
  final String journalId;
  final JournalSummary? preview;

  const JournalDetailScreen({super.key, required this.journalId, this.preview});

  @override
  ConsumerState<JournalDetailScreen> createState() =>
      _JournalDetailScreenState();
}

class _JournalDetailScreenState extends ConsumerState<JournalDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(journalDetailViewModelProvider.notifier)
          .load(journalId: widget.journalId, preview: widget.preview),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journalDetailViewModelProvider);
    return Scaffold(
      key: WidgetKeys.journalDetailScreen,
      appBar: AppBar(
        title: const Text('Journal Detail'),
        actions: [
          if (state is JournalDetailLoaded)
            IconButton(
              tooltip: 'Refresh journal',
              onPressed: state.isRefreshing
                  ? null
                  : ref.read(journalDetailViewModelProvider.notifier).retry,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _body(context, state),
    );
  }

  Widget _body(BuildContext context, JournalDetailState state) {
    return switch (state) {
      JournalDetailInitial() => const Center(
        child: CircularProgressIndicator(),
      ),
      JournalDetailLoading s => _LoadingBody(preview: s.preview),
      JournalDetailError s => _FullError(
        message: s.message,
        preview: s.preview,
        onRetry: ref.read(journalDetailViewModelProvider.notifier).retry,
      ),
      JournalDetailLoaded s => _LoadedBody(
        state: s,
        journalId: widget.journalId,
        onSort: ref.read(journalDetailViewModelProvider.notifier).setSort,
        onRetry: ref.read(journalDetailViewModelProvider.notifier).retry,
        onRetryPublications: ref
            .read(journalDetailViewModelProvider.notifier)
            .retryPublications,
        onLoadMore: ref.read(journalDetailViewModelProvider.notifier).loadMore,
        onRetryLoadMore: ref
            .read(journalDetailViewModelProvider.notifier)
            .retryLoadMore,
      ),
    };
  }
}

class _LoadedBody extends StatelessWidget {
  final JournalDetailLoaded state;
  final String journalId;
  final ValueChanged<RelatedPublicationSort> onSort;
  final VoidCallback onRetry;
  final VoidCallback onRetryPublications;
  final VoidCallback onLoadMore;
  final VoidCallback onRetryLoadMore;

  const _LoadedBody({
    required this.state,
    required this.journalId,
    required this.onSort,
    required this.onRetry,
    required this.onRetryPublications,
    required this.onLoadMore,
    required this.onRetryLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.sizeOf(context).width >= 600 ? 24.0 : 16.0;
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isTablet = constraints.maxWidth >= 600;
                        final identity = Column(
                          children: [
                            _IdentityCard(journal: state.journal),
                            if (state.metadataWarning != null) ...[
                              const SizedBox(height: 12),
                              _InlineError(
                                message: state.metadataWarning!,
                                buttonKey: const Key('journal_detail_retry'),
                                onRetry: onRetry,
                              ),
                            ],
                          ],
                        );
                        final publications = _PublicationsSection(
                          state: state,
                          journalId: journalId,
                          onSort: onSort,
                          onRetry: onRetryPublications,
                          onLoadMore: onLoadMore,
                          onRetryLoadMore: onRetryLoadMore,
                        );
                        if (!isTablet) {
                          return Column(
                            children: [
                              identity,
                              const SizedBox(height: 24),
                              publications,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: identity),
                            const SizedBox(width: 24),
                            Expanded(flex: 8, child: publications),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (state.isRefreshing)
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final JournalSummary journal;

  const _IdentityCard({required this.journal});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final metadata = [
      if (journal.issn != null) 'ISSN ${journal.issn}',
      if (journal.publisher != null) journal.publisher!,
    ];
    return Semantics(
      key: WidgetKeys.journalDetailIdentity,
      container: true,
      label:
          '${journal.displayName}. ${journal.publicationCount} publications. ${journal.citationCount} citations. Average ${journal.averageCitations.toStringAsFixed(1)} citations per publication.',
      child: Card(
        color: colors.primary,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACADEMIC JOURNAL',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                journal.displayName,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.onPrimary,
                  height: 1.3,
                ),
              ),
              if (metadata.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  metadata.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.82),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Metric(
                      key: WidgetKeys.journalTotalPublications,
                      label: 'Publications',
                      visual: NumberFormatter.compact(journal.publicationCount),
                      exact: journal.publicationCount.toString(),
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      key: WidgetKeys.journalTotalCitations,
                      label: 'Citations',
                      visual:
                          '${NumberFormatter.compact(journal.citationCount)}${journal.isCitationEstimate ? '*' : ''}',
                      exact: journal.citationCount.toString(),
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      key: WidgetKeys.journalAverageCitations,
                      label: 'Avg cites',
                      visual: journal.averageCitations.toStringAsFixed(1),
                      exact: journal.averageCitations.toStringAsFixed(1),
                    ),
                  ),
                ],
              ),
              if (journal.isCitationEstimate) ...[
                const SizedBox(height: 12),
                Text(
                  '* Estimated from a deterministic 200-work topic sample.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String visual;
  final String exact;

  const _Metric({
    super.key,
    required this.label,
    required this.visual,
    required this.exact,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimary;
    return Semantics(
      label: '$label, $exact',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              visual,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicationsSection extends StatelessWidget {
  final JournalDetailLoaded state;
  final String journalId;
  final ValueChanged<RelatedPublicationSort> onSort;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final VoidCallback onRetryLoadMore;

  const _PublicationsSection({
    required this.state,
    required this.journalId,
    required this.onSort,
    required this.onRetry,
    required this.onLoadMore,
    required this.onRetryLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Related publications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${state.totalWorks} results',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _SortMenu(sort: state.sort, onSort: onSort),
          ],
        ),
        const SizedBox(height: 12),
        if (state.publicationsError != null)
          _InlineError(message: state.publicationsError!, onRetry: onRetry)
        else if (state.works.isEmpty)
          const _EmptyPublications()
        else ...[
          for (var i = 0; i < state.works.length; i++) ...[
            _PublicationCard(
              key: Key('related_publication_${state.works[i].shortId}'),
              work: state.works[i],
              onTap: () => _openWork(context, state.works[i]),
            ),
            if (i < state.works.length - 1) const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          if (state.isLoadingMore)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state.loadMoreError != null)
            _InlineError(
              message: state.loadMoreError!,
              onRetry: onRetryLoadMore,
            )
          else if (state.hasMore)
            Center(
              child: OutlinedButton.icon(
                key: const Key('load_more_publications'),
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more),
                label: const Text('Load more publications'),
              ),
            ),
        ],
      ],
    );
  }

  void _openWork(BuildContext context, Work work) {
    final sourceId = Uri.encodeComponent(journalId.split('/').last);
    final workId = Uri.encodeComponent(work.shortId);
    context.push(
      '/journal/journal-detail/$sourceId/publication/$workId',
      extra: work,
    );
  }
}

class _SortMenu extends StatelessWidget {
  final RelatedPublicationSort sort;
  final ValueChanged<RelatedPublicationSort> onSort;

  const _SortMenu({required this.sort, required this.onSort});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RelatedPublicationSort>(
      key: const Key('journal_publication_sort'),
      tooltip: 'Sort publications by ${sort.label}',
      initialValue: sort,
      onSelected: onSort,
      itemBuilder: (_) => [
        for (final option in RelatedPublicationSort.values)
          PopupMenuItem(value: option, child: Text(option.label)),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text(sort.label), const Icon(Icons.arrow_drop_down)],
            ),
          ),
        ),
      ),
    );
  }
}

class _PublicationCard extends StatelessWidget {
  final Work work;
  final VoidCallback onTap;

  const _PublicationCard({super.key, required this.work, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final authorNames = work.authors
        .map((author) => author.displayName)
        .toList();
    final authors = authorNames.isEmpty
        ? 'Unknown authors'
        : [
            ...authorNames.take(2),
            if (authorNames.length > 2) '+${authorNames.length - 2}',
          ].join(' · ');
    final metadata = [
      authors,
      if (work.publicationYear != null) work.publicationYear.toString(),
      if (work.type != null) work.type!,
    ].join(' · ');
    return Semantics(
      button: true,
      label: '${work.title}, $metadata, ${work.citedByCount} citations',
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        work.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        metadata,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          child: Text(
                            '${NumberFormatter.compact(work.citedByCount)} citations',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  final JournalSummary? preview;

  const _LoadingBody({this.preview});

  @override
  Widget build(BuildContext context) {
    final skeleton = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (preview != null)
          _IdentityCard(journal: preview!)
        else
          _Skeleton(height: 240, color: skeleton),
        const SizedBox(height: 24),
        for (var i = 0; i < 5; i++) ...[
          _Skeleton(height: 120, color: skeleton),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _FullError extends StatelessWidget {
  final String message;
  final JournalSummary? preview;
  final VoidCallback onRetry;

  const _FullError({
    required this.message,
    required this.preview,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (preview != null) ...[
          _IdentityCard(journal: preview!),
          const SizedBox(height: 16),
        ],
        _InlineError(
          message: message,
          buttonKey: const Key('journal_detail_retry'),
          onRetry: onRetry,
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Key? buttonKey;

  const _InlineError({
    required this.message,
    required this.onRetry,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(
              key: buttonKey,
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPublications extends StatelessWidget {
  const _EmptyPublications();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No related publications found for this journal and topic.',
          textAlign: TextAlign.center,
        ),
      ),
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
