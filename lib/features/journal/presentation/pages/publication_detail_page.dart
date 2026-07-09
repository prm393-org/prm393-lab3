import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../publication/domain/entities/author.dart';
import '../../../publication/domain/entities/work.dart';
import '../cubit/publication_detail_cubit.dart';
import '../cubit/publication_detail_state.dart';

class PublicationDetailPage extends StatelessWidget {
  final String workId;
  final Work? preview;

  const PublicationDetailPage({super.key, required this.workId, this.preview});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<PublicationDetailCubit>()
            ..load(workId: workId, preview: preview),
      child: const _PublicationDetailView(),
    );
  }
}

class _PublicationDetailView extends StatelessWidget {
  const _PublicationDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PublicationDetailCubit, PublicationDetailState>(
      builder: (context, state) {
        final work = switch (state) {
          PublicationDetailLoading s => s.preview,
          PublicationDetailLoaded s => s.work,
          PublicationDetailError s => s.preview,
          PublicationDetailInitial() => null,
        };

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text(
              'Publication Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            actions: [
              if (state is PublicationDetailLoaded ||
                  state is PublicationDetailError)
                IconButton(
                  onPressed: context.read<PublicationDetailCubit>().retry,
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          body: switch (state) {
            PublicationDetailInitial() => const LoadingWidget(
              message: 'Loading publication…',
            ),
            PublicationDetailLoading() when work == null => const LoadingWidget(
              message: 'Loading publication…',
            ),
            PublicationDetailLoading() => Stack(
              children: [
                if (work != null) _DetailBody(work: work, isRefreshing: true),
                const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              ],
            ),
            PublicationDetailLoaded s => _DetailBody(work: s.work),
            PublicationDetailError s => ErrorStateWidget(
              message: s.message,
              onRetry: context.read<PublicationDetailCubit>().retry,
            ),
          },
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Work work;
  final bool isRefreshing;

  const _DetailBody({required this.work, this.isRefreshing = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRefreshing) ...[
                  Text(
                    'Updating from OpenAlex…',
                    style: tt.labelSmall?.copyWith(color: cs.primary),
                  ),
                  const SizedBox(height: 8),
                ],
                SelectableText(
                  work.title,
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                if (work.authors.isNotEmpty) ...[
                  _SectionLabel(label: 'Authors', cs: cs),
                  const SizedBox(height: 8),
                  ...work.authors.map(
                    (a) => _AuthorTile(author: a, cs: cs, tt: tt),
                  ),
                  const SizedBox(height: 16),
                ],
                _MetaSection(work: work, cs: cs, tt: tt),
                const SizedBox(height: 16),
                _ActionButtons(work: work),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Abstract', cs: cs),
                const SizedBox(height: 8),
                if (work.abstract_ != null && work.abstract_!.isNotEmpty)
                  SelectableText(
                    work.abstract_!,
                    style: tt.bodyMedium?.copyWith(height: 1.6),
                  )
                else
                  Text(
                    'No abstract available for this publication.',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.45),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (work.keywords.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'Keywords', cs: cs),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: work.keywords
                        .map(
                          (k) => Chip(
                            label: Text(k),
                            labelStyle: tt.labelSmall,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: cs.surfaceContainerHighest,
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (work.primaryTopicName != null) ...[
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'Primary Topic', cs: cs),
                  const SizedBox(height: 8),
                  _tagChip(Icons.label_outline, work.primaryTopicName!, cs, tt),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _CitationSection(count: work.citedByCount, cs: cs, tt: tt),
                if (work.doi != null) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  _DoiSection(doi: work.doi!, cs: cs, tt: tt),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tagChip(IconData icon, String label, ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorTile extends StatelessWidget {
  final Author author;
  final ColorScheme cs;
  final TextTheme tt;

  const _AuthorTile({required this.author, required this.cs, required this.tt});

  Future<void> _openOrcid() async {
    final orcid = author.orcid;
    if (orcid == null) return;
    final uri = Uri.tryParse(orcid);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  author.displayName,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (author.orcid != null)
                TextButton.icon(
                  onPressed: _openOrcid,
                  icon: const Icon(Icons.badge_outlined, size: 14),
                  label: const Text('ORCID'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          if (author.affiliations.isNotEmpty)
            ...author.affiliations.map(
              (a) => Padding(
                padding: const EdgeInsets.only(top: 2, left: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.apartment,
                      size: 12,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        a,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaSection extends StatelessWidget {
  final Work work;
  final ColorScheme cs;
  final TextTheme tt;

  const _MetaSection({required this.work, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    final tags = <Widget>[];

    if (work.publicationYear != null) {
      tags.add(
        _MetaTag(
          icon: Icons.calendar_today_outlined,
          label: work.publicationYear.toString(),
          cs: cs,
          tt: tt,
        ),
      );
    }

    final formattedDate = _formatDate(work.publicationDate);
    if (formattedDate != null) {
      tags.add(
        _MetaTag(
          icon: Icons.event_outlined,
          label: formattedDate,
          cs: cs,
          tt: tt,
        ),
      );
    }

    if (work.type != null) {
      tags.add(
        _MetaTag(
          icon: Icons.article_outlined,
          label: _formatType(work.type!),
          cs: cs,
          tt: tt,
        ),
      );
    }

    if (work.sourceName != null) {
      tags.add(
        _MetaTag(
          icon: Icons.library_books_outlined,
          label: work.sourceName!,
          cs: cs,
          tt: tt,
        ),
      );
    }

    if (work.issn != null) {
      tags.add(
        _MetaTag(
          icon: Icons.numbers,
          label: 'ISSN ${work.issn}',
          cs: cs,
          tt: tt,
        ),
      );
    }

    if (work.biblioLabel != null) {
      tags.add(
        _MetaTag(
          icon: Icons.menu_book_outlined,
          label: work.biblioLabel!,
          cs: cs,
          tt: tt,
        ),
      );
    }

    if (work.isOpenAccess) {
      tags.add(_OaBadge(oaStatus: work.oaStatus, license: work.license));
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: tags);
  }

  String? _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat.yMMMd().format(parsed);
  }

  String _formatType(String type) => type
      .split('-')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

class _MetaTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  final TextTheme tt;

  const _MetaTag({
    required this.icon,
    required this.label,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              label,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _OaBadge extends StatelessWidget {
  final String? oaStatus;
  final String? license;

  const _OaBadge({this.oaStatus, this.license});

  @override
  Widget build(BuildContext context) {
    final statusLabel = oaStatus == null
        ? 'Open Access'
        : '${oaStatus![0].toUpperCase()}${oaStatus!.substring(1)} OA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accentTealBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.tertiary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_open, size: 12, color: AppColors.accentTealDark),
          const SizedBox(width: 4),
          Text(
            license != null ? '$statusLabel · $license' : statusLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accentTealDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Work work;

  const _ActionButtons({required this.work});

  Future<void> _open(String? url) async {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _sameUrl(String? a, String? b) =>
      a != null && b != null && a.trim() == b.trim();

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    if (work.landingPageUrl != null) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => _open(work.landingPageUrl),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Open paper'),
        ),
      );
    }

    if (work.oaUrl != null && !_sameUrl(work.oaUrl, work.landingPageUrl)) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _open(work.oaUrl),
          icon: const Icon(Icons.lock_open, size: 18),
          label: const Text('Open Access version'),
        ),
      );
    }

    if (work.id.startsWith('http')) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _open(work.id),
          icon: const Icon(Icons.hub_outlined, size: 18),
          label: const Text('View on OpenAlex'),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  const _SectionLabel({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: cs.onSurface.withValues(alpha: 0.45),
      ),
    );
  }
}

class _CitationSection extends StatelessWidget {
  final int count;
  final ColorScheme cs;
  final TextTheme tt;
  const _CitationSection({
    required this.count,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'Citations', cs: cs),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.format_quote, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  NumberFormatter.compact(count),
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                Text(
                  'times cited',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _DoiSection extends StatelessWidget {
  final String doi;
  final ColorScheme cs;
  final TextTheme tt;
  const _DoiSection({required this.doi, required this.cs, required this.tt});

  Future<void> _open() async {
    final uri = Uri.tryParse(doi);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'DOI', cs: cs),
        const SizedBox(height: 10),
        InkWell(
          onTap: _open,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.link, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    doi,
                    style: tt.bodySmall?.copyWith(color: cs.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.open_in_new, size: 14, color: cs.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
