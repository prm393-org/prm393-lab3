import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/work_detail_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../publication/domain/entities/topic.dart';
import '../../../publication/presentation/widgets/trend_chart.dart';
import '../../../shared/presentation/cubit/selected_topic_cubit.dart';
import '../cubit/research_dashboard_cubit.dart';
import '../cubit/research_dashboard_state.dart';
import '../widgets/research_dashboard_emerging_keywords.dart';
import '../widgets/research_dashboard_frontier.dart';
import '../widgets/research_dashboard_header.dart';
import '../widgets/research_dashboard_impact_scatter.dart';
import '../widgets/research_dashboard_kpi_grid.dart';
import '../widgets/research_dashboard_ranking_card.dart';
import '../widgets/research_dashboard_scatter.dart';

class ResearchDashboardPage extends StatelessWidget {
  const ResearchDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ResearchDashboardCubit>(
      create: (ctx) {
        final cubit = getIt<ResearchDashboardCubit>();
        final selected = ctx.read<SelectedTopicCubit>().state;
        if (selected != null) cubit.loadByTopic(selected);
        return cubit;
      },
      child: BlocListener<SelectedTopicCubit, Topic?>(
        listener: (context, topic) {
          if (topic == null) {
            context.read<ResearchDashboardCubit>().clear();
          } else {
            context.read<ResearchDashboardCubit>().loadByTopic(topic);
          }
        },
        child: const _ResearchDashboardView(),
      ),
    );
  }
}

class _ResearchDashboardView extends StatelessWidget {
  const _ResearchDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResearchDashboardCubit, ResearchDashboardState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Keywords'),
            backgroundColor: Theme.of(context).colorScheme.surface,
            actions: [
              if (state is ResearchDashboardLoaded ||
                  state is ResearchDashboardError)
                IconButton(
                  onPressed: context.read<ResearchDashboardCubit>().retry,
                  tooltip: 'Refresh dashboard',
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          body: SafeArea(top: false, child: _buildBody(context, state)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ResearchDashboardState state) {
    if (state is ResearchDashboardInitial) {
      return EmptyStateWidget(
        icon: Icons.tag_outlined,
        message:
            'No research topic is selected.\nChoose a topic from Home to explore keywords.',
        action: FilledButton.icon(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.search),
          label: const Text('Find a topic'),
        ),
      );
    }

    if (state is ResearchDashboardLoading) {
      return LoadingWidget(message: 'Analyzing ${state.topic.displayName}…');
    }

    if (state is ResearchDashboardError) {
      return ErrorStateWidget(
        message: state.message,
        onRetry: context.read<ResearchDashboardCubit>().retry,
      );
    }

    if (state is ResearchDashboardEmpty) {
      return EmptyStateWidget(
        icon: Icons.query_stats_outlined,
        message:
            'OpenAlex returned no publications for ${state.topic.displayName}.',
        action: FilledButton.icon(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.search),
          label: const Text('Choose another topic'),
        ),
      );
    }

    final summary = (state as ResearchDashboardLoaded).summary;

    return RefreshIndicator(
      onRefresh: context.read<ResearchDashboardCubit>().retry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ResearchDashboardHeader(summary: summary),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ResearchDashboardKpiGrid(summary: summary),
          ),
          // ── Trends ──────────────────────────────────────────────
          if (summary.yearlyTrend.length >= 2) ...[
            _SectionHeader(label: 'Trends'),
            SizedBox(
              width: double.infinity,
              child: TrendChart(trend: summary.yearlyTrend),
            ),
          ],
          if (summary.citationTrend.length >= 2)
            SizedBox(
              width: double.infinity,
              child: TrendChart(
                trend: summary.citationTrend,
                title: 'Citation trend',
                unit: 'citations',
              ),
            ),
          // ── Authors ─────────────────────────────────────────────
          _SectionHeader(label: 'Authors'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ResearchDashboardRankingCard(
              title: 'Author Impact',
              subtitle: 'By contributing papers in the sample',
              icon: Icons.groups_outlined,
              items: summary.topAuthors,
              accent: AppColors.tertiary,
            ),
          ),
          if (summary.authorStats.length >= 4)
            ResearchDashboardImpactScatter(
              items: summary.authorStats,
              title: 'Author Productivity vs Impact',
              subjectNoun: 'author',
              accent: AppColors.tertiary,
            ),
          // ── Journals ────────────────────────────────────────────
          _SectionHeader(label: 'Journals'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ResearchDashboardRankingCard(
              title: 'Journal Ranking',
              subtitle: 'By publication frequency in the sample',
              icon: Icons.library_books_outlined,
              items: summary.topJournals,
              accent: AppColors.primary,
            ),
          ),
          if (summary.journalStats.length >= 4)
            ResearchDashboardImpactScatter(
              items: summary.journalStats,
              title: 'Journal Impact',
              subjectNoun: 'journal',
              accent: AppColors.primary,
            ),
          // ── Keywords ────────────────────────────────────────────
          if (summary.topKeywords.isNotEmpty) ...[
            _SectionHeader(label: 'Keywords'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ResearchDashboardRankingCard(
                title: 'Top Keywords',
                subtitle: 'Most frequent keywords in the sample',
                icon: Icons.sell_outlined,
                items: summary.topKeywords,
                accent: AppColors.secondary,
              ),
            ),
            if (summary.emergingKeywords.length >= 2)
              ResearchDashboardEmergingKeywords(
                series: summary.emergingKeywords,
              ),
            if (summary.frontierKeywords.length >= 4)
              ResearchDashboardFrontier(keywords: summary.frontierKeywords),
          ],
          // ── Impact (papers) ─────────────────────────────────────
          if (summary.scatterPapers.length >= 4) ...[
            _SectionHeader(label: 'Impact'),
            ResearchDashboardScatter(
              papers: summary.scatterPapers,
              onPaperTap: (work) => openWorkDetail(context, work),
            ),
          ],
          // ── Institutions ────────────────────────────────────────
          if (summary.topInstitutions.isNotEmpty) ...[
            _SectionHeader(label: 'Institutions'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ResearchDashboardRankingCard(
                title: 'Institution Ranking',
                subtitle: 'By contributing papers in the sample',
                icon: Icons.account_balance_outlined,
                items: summary.topInstitutions,
                accent: AppColors.primary,
              ),
            ),
            if (summary.institutionStats.length >= 4)
              ResearchDashboardImpactScatter(
                items: summary.institutionStats,
                title: 'Institution Impact',
                subjectNoun: 'institution',
                accent: AppColors.primary,
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

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
