import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/recent_searches_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../publication/domain/usecases/search_topics.dart';
import '../../../shared/presentation/cubit/pending_search_cubit.dart';
import '../../../shared/presentation/cubit/selected_topic_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _mailtoCtrl;
  final RecentSearchesStore _recentStore = GetIt.I<RecentSearchesStore>();
  bool _fieldsReady = false;
  int _savedTopicCount = 0;

  @override
  void initState() {
    super.initState();
    _apiKeyCtrl = TextEditingController();
    _mailtoCtrl = TextEditingController();
    _loadLibraryCounts();
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _mailtoCtrl.dispose();
    super.dispose();
  }

  void _syncFields(ProfileState state) {
    if (!_fieldsReady && state.status != ProfileStatus.loading) {
      _apiKeyCtrl.text = state.settings.apiKey;
      _mailtoCtrl.text = state.settings.mailto;
      _fieldsReady = true;
    }
  }

  void _loadLibraryCounts() {
    final prefs = GetIt.I<SharedPreferences>();
    final saved = prefs.getStringList(AppConstants.prefSavedTopics) ?? [];
    setState(() {
      _savedTopicCount = saved.length;
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _editApiKey(ProfileState state) async {
    _apiKeyCtrl.text = state.settings.apiKey;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _EditSheet(
        title: 'API Key',
        child: TextField(
          controller: _apiKeyCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Paste your OpenAlex API key',
            prefixIcon: Icon(Icons.vpn_key_outlined),
          ),
        ),
      ),
    );
    if (saved == true && mounted) {
      await context.read<ProfileCubit>().save(
            displayName: state.settings.displayName,
            apiKey: _apiKeyCtrl.text,
            mailto: state.settings.mailto,
          );
    }
  }

  Future<void> _editEmail(ProfileState state) async {
    _mailtoCtrl.text = state.settings.mailto;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _EditSheet(
        title: 'Email',
        child: TextField(
          controller: _mailtoCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'you@university.edu',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
      ),
    );
    if (saved == true && mounted) {
      await context.read<ProfileCubit>().save(
            displayName: state.settings.displayName,
            apiKey: state.settings.apiKey,
            mailto: _mailtoCtrl.text,
          );
    }
  }

  Future<void> _pickDefaultFilter(TopicSortFilter current) async {
    final picked = await showModalBottomSheet<TopicSortFilter>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Default Topic Filter',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            for (final f in TopicSortFilter.values)
              ListTile(
                leading: Icon(
                  f == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off_outlined,
                  color: f == current ? AppColors.secondary : null,
                ),
                title: Text(f.label),
                onTap: () => Navigator.pop(ctx, f),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      await context.read<ProfileCubit>().setDefaultHomeFilter(picked);
    }
  }

  /// Yêu cầu Home điền sẵn & tìm từ khoá, rồi chuyển sang tab Home.
  void _searchFromHistory(String query) {
    context.read<PendingSearchCubit>().request(query);
    context.go('/home');
  }

  Future<void> _showLibrarySheet({
    required String title,
    required List<String> items,
    ValueChanged<String>? onItemTap,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                title,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Nothing here yet',
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, i) => ListTile(
                    dense: true,
                    leading: onItemTap != null
                        ? const Icon(Icons.history, size: 18)
                        : null,
                    title: Text(items[i]),
                    trailing: onItemTap != null
                        ? const Icon(Icons.north_west, size: 16)
                        : null,
                    onTap: onItemTap == null
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            onItemTap(items[i]);
                          },
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCache() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear cache?'),
        content: const Text(
          'Remove recent searches, saved topics, and reset the selected topic.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final prefs = GetIt.I<SharedPreferences>();
    _recentStore.clear();
    await prefs.remove(AppConstants.prefSavedTopics);
    await prefs.remove(AppConstants.prefLastSync);
    context.read<SelectedTopicCubit>().clear();
    _loadLibraryCounts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg =
        isDark ? AppColors.darkBackground : AppColors.surfaceMuted;

    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        _syncFields(state);
        if (state.message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message!)));
        }
        if (state.status == ProfileStatus.saved) {
          setState(() => _fieldsReady = true);
        }
      },
      builder: (context, state) {
        _syncFields(state);
        final settings = state.settings;
        final isSaving = state.status == ProfileStatus.saving;
        final prefs = GetIt.I<SharedPreferences>();
        final savedItems =
            prefs.getStringList(AppConstants.prefSavedTopics) ?? [];

        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: pageBg,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: state.status == ProfileStatus.loading && !_fieldsReady
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    _SectionHeader(label: 'SETTINGS'),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.vpn_key_outlined,
                          title: 'API Key',
                          subtitle: _maskApiKey(settings.apiKey),
                          onTap: isSaving ? null : () => _editApiKey(state),
                        ),
                        _SettingsRow(
                          icon: Icons.email_outlined,
                          title: 'Email',
                          subtitle: settings.mailto.isNotEmpty
                              ? settings.mailto
                              : 'Not configured',
                          onTap: isSaving ? null : () => _editEmail(state),
                        ),
                        _SettingsRow(
                          icon: Icons.filter_list_outlined,
                          title: 'Default Topic Filter',
                          subtitle: settings.defaultHomeFilter.label,
                          onTap: () =>
                              _pickDefaultFilter(settings.defaultHomeFilter),
                        ),
                        _SettingsRow(
                          icon: Icons.dark_mode_outlined,
                          title: 'Dark Mode',
                          showChevron: false,
                          trailing: Switch.adaptive(
                            value: settings.themeMode == ThemeMode.dark,
                            onChanged: isSaving
                                ? null
                                : (v) => context
                                    .read<ProfileCubit>()
                                    .setDarkMode(v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(label: 'LIBRARY'),
                    _SettingsCard(
                      children: [
                        ListenableBuilder(
                          listenable: _recentStore,
                          builder: (context, _) => _SettingsRow(
                            icon: Icons.history_outlined,
                            title: 'Recent searches',
                            badge: '${_recentStore.count}',
                            onTap: () => _showLibrarySheet(
                              title: 'Recent searches',
                              items: _recentStore.items,
                              onItemTap: _searchFromHistory,
                            ),
                          ),
                        ),
                        _SettingsRow(
                          icon: Icons.bookmark_outline,
                          title: 'Saved topics',
                          badge: '$_savedTopicCount',
                          onTap: () => _showLibrarySheet(
                            title: 'Saved topics',
                            items: savedItems,
                          ),
                        ),
                        _SettingsRow(
                          icon: Icons.delete_outline,
                          title: 'Clear cache',
                          destructive: true,
                          showChevron: false,
                          onTap: _clearCache,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(label: 'ABOUT'),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          title: AppConstants.appName,
                          subtitle:
                              'Version ${AppConstants.appVersion}',
                          titleBold: true,
                          showChevron: false,
                        ),
                        _SettingsRow(
                          icon: Icons.storage_outlined,
                          title: 'Data provided by OpenAlex',
                          trailing: Icon(
                            Icons.open_in_new,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          showChevron: false,
                          onTap: () => _openUrl(AppConstants.openAlexBaseUrl),
                        ),
                        _SettingsRow(
                          icon: Icons.science_outlined,
                          title: 'Bibliometrics Lab',
                          subtitle: 'PRM393 · FPT University',
                          onTap: () => _openUrl('https://docs.openalex.org'),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  static String _maskApiKey(String key) {
    if (key.isEmpty) return 'Not configured';
    if (key.length <= 4) return '••••••••';
    return '${'•' * 8}${key.substring(key.length - 4)}';
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? AppColors.darkSurfaceElevated : AppColors.white;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 56,
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? badge;
  final bool destructive;
  final bool showChevron;
  final bool titleBold;
  final VoidCallback? onTap;

  const _SettingsRow({
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.badge,
    this.destructive = false,
    this.showChevron = true,
    this.titleBold = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = destructive ? AppColors.error : cs.onSurface;
    final muted = destructive
        ? AppColors.error.withValues(alpha: 0.85)
        : cs.onSurfaceVariant;

    Widget? trailingWidget = trailing;
    if (trailingWidget == null && badge != null) {
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (showChevron) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: muted),
          ],
        ],
      );
    } else if (trailingWidget == null && showChevron) {
      trailingWidget = Icon(Icons.chevron_right, size: 20, color: muted);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 22, color: accent),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            titleBold ? FontWeight.w700 : FontWeight.w500,
                        color: titleBold ? AppColors.primary : accent,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null) trailingWidget,
            ],
          ),
        ),
      ),
    );
  }
}

class _EditSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _EditSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          child,
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
