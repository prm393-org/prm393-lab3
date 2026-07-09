import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/research_dashboard_summary.dart';

class ResearchDashboardHeader extends StatelessWidget {
  final ResearchDashboardSummary summary;

  const ResearchDashboardHeader({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final topic = summary.topic;
    final tt = Theme.of(context).textTheme;
    final metadata = [
      if (topic.fieldName?.trim().isNotEmpty ?? false) topic.fieldName!,
      if (topic.domainName?.trim().isNotEmpty ?? false) topic.domainName!,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.navy,
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -6,
            bottom: -12,
            child: Icon(
              Icons.insights_outlined,
              size: 92,
              color: Colors.white12,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ANALYZING TOPIC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                topic.displayName,
                style: tt.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (metadata.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  metadata.join(' • '),
                  style: tt.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.science_outlined,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Insights use the ${summary.sampleSize} highest-cited '
                      'works currently loaded from OpenAlex.',
                      style: tt.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
