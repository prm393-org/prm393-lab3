import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class KeywordsPage extends StatelessWidget {
  const KeywordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keywords'),
        backgroundColor: cs.surface,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accentTealBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tag,
                size: 48,
                color: AppColors.accentTealDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Keywords & Trends',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
