import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/widget_keys.dart';
import '../../../../core/router/work_detail_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../publication/domain/entities/keyword.dart';
import '../../../publication/presentation/widgets/trend_chart.dart';
import '../../../publication/presentation/widgets/work_card.dart';
import '../../domain/entities/keyword_detail_summary.dart';
import '../viewmodels/keyword_detail_state.dart';
import '../viewmodels/keyword_detail_viewmodel.dart';
import '../widgets/research_dashboard_impact_scatter.dart';
import '../widgets/research_dashboard_ranking_card.dart';

/// FR 4.7 — Keyword Detail: xu hướng công bố, journal & bài báo liên quan,
/// tác giả hàng đầu của một keyword.
class KeywordDetailScreen extends ConsumerStatefulWidget {
  /// Slug trên URL (`/keywords/detail/:keyword`).
  final String keywordSlug;

  /// Keyword truyền qua `extra` khi điều hướng trong app. Null khi deep link —
  /// khi đó tên hiển thị được dựng lại từ slug.
  final Keyword? preview;

  const KeywordDetailScreen({
    super.key,
    required this.keywordSlug,
    this.preview,
  });

  @override
  ConsumerState<KeywordDetailScreen> createState() =>
      _KeywordDetailScreenState();
}

class _KeywordDetailScreenState extends ConsumerState<KeywordDetailScreen> {
  late final Keyword _keyword;

  @override
  void initState() {
    super.initState();
    _keyword = widget.preview ?? _fromSlug(widget.keywordSlug);
    Future.microtask(
      () => ref.read(keywordDetailViewModelProvider.notifier).load(_keyword),
    );
  }

  /// `machine-learning` → `Machine learning`. Chỉ dùng khi mở bằng deep link,
  /// vì slug đã mất dấu và phần trong ngoặc của display name gốc.
  static Keyword _fromSlug(String slug) {
    final words = slug.replaceAll('-', ' ').trim();
    final label = words.isEmpty
        ? 'Keyword'
        : words[0].toUpperCase() + words.substring(1);
    return Keyword(id: 'https://openalex.org/keywords/$slug', displayName: label);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(keywordDetailViewModelProvider);
    final retry = ref.read(keywordDetailViewModelProvider.notifier).retry;

    return Scaffold(
      key: WidgetKeys.keywordDetailScreen,
      appBar: AppBar(
        title: Text(_keyword.displayName),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          if (state is KeywordDetailLoaded || state is KeywordDetailError)
            IconButton(
              onPressed: retry,
              tooltip: 'Refresh keyword',
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(top: false, child: _buildBody(context, state, retry)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    KeywordDetailState state,
    Future<void> Function() retry,
  ) {
    if (state is KeywordDetailLoading || state is KeywordDetailInitial) {
      return LoadingWidget(
        key: WidgetKeys.keywordDetailLoading,
        message: 'Analyzing ${_keyword.displayName}…',
      );
    }

    if (state is KeywordDetailError) {
      return ErrorStateWidget(
        key: WidgetKeys.keywordDetailError,
        message: state.message,
        onRetry: retry,
      );
    }

    if (state is KeywordDetailEmpty) {
      return EmptyStateWidget(
        key: WidgetKeys.keywordDetailEmpty,
        icon: Icons.sell_outlined,
        message:
            'OpenAlex returned no publications tagged "${state.keyword.displayName}".',
      );
    }

    final loaded = state as KeywordDetailLoaded;
    final summary = loaded.summary;

    return RefreshIndicator(
      onRefresh: retry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _KeywordHeader(
              key: WidgetKeys.keywordDetailHeader,
              summary: summary,
            ),
          ),
          // ── Publication trend ───────────────────────────────────
          if (summary.yearlyTrend.length >= 2) ...[
            const _SectionHeader(label: 'Publication trend'),
            SizedBox(
              width: double.infinity,
              child: TrendChart(
                key: WidgetKeys.keywordDetailTrendChart,
                trend: summary.yearlyTrend,
              ),
            ),
            if (loaded.trendWarning != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  loaded.trendWarning!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ),
          ],
          // ── Related journals ────────────────────────────────────
          const _SectionHeader(label: 'Related journals'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ResearchDashboardRankingCard(
              key: WidgetKeys.keywordDetailJournals,
              title: 'Journals publishing this keyword',
              subtitle: 'By publication frequency in the sample',
              icon: Icons.library_books_outlined,
              items: summary.topJournals,
              accent: AppColors.primary,
            ),
          ),
          // ── Top authors + ranking chart ─────────────────────────
          const _SectionHeader(label: 'Top authors'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ResearchDashboardRankingCard(
              key: WidgetKeys.keywordDetailAuthors,
              title: 'Author Ranking',
              subtitle: 'By contributing papers in the sample',
              icon: Icons.groups_outlined,
              items: summary.topAuthors,
              accent: AppColors.tertiary,
            ),
          ),
          if (summary.authorStats.length >= 4)
            ResearchDashboardImpactScatter(
              key: WidgetKeys.keywordDetailAuthorChart,
              items: summary.authorStats,
              title: 'Author Productivity vs Impact',
              subjectNoun: 'author',
              accent: AppColors.tertiary,
            ),
          // ── Related publications ────────────────────────────────
          const _SectionHeader(
            key: WidgetKeys.keywordDetailPublications,
            label: 'Related publications',
          ),
          for (final (index, work) in summary.publications.indexed)
            WorkCard(
              key: WidgetKeys.keywordDetailPublication(index),
              work: work,
              onTap: () => openWorkDetail(context, work),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _KeywordHeader extends StatelessWidget {
  final KeywordDetailSummary summary;

  const _KeywordHeader({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface(AppColors.secondary),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.sell_outlined,
                    size: 19,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    summary.keyword.displayName,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                _Metric(
                  label: 'Publications',
                  value: NumberFormatter.compact(summary.totalPublications),
                ),
                _Metric(
                  label: 'Citations',
                  value: NumberFormatter.compact(summary.totalCitations),
                ),
                _Metric(
                  label: 'Avg. citations',
                  value: summary.averageCitations.toStringAsFixed(1),
                ),
                _Metric(
                  label: 'Most active',
                  value: summary.mostActiveYear?.toString() ?? 'N/A',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Rankings computed from the ${summary.sampleSize} most-cited papers.',
              style: tt.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: tt.titleLarge?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: cs.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
