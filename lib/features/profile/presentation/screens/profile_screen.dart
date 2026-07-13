import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/widget_keys.dart';
import '../../../../core/data/recent_searches_store.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../firebase/firebase_providers.dart';
import '../../../keywords/presentation/viewmodels/research_dashboard_state.dart';
import '../../../keywords/presentation/viewmodels/research_dashboard_viewmodel.dart';
import '../../../publication/domain/usecases/search_topics.dart';
import '../../../shared/presentation/viewmodels/pending_search_viewmodel.dart';
import '../../../shared/presentation/viewmodels/selected_topic_viewmodel.dart';
import '../../domain/entities/app_notification.dart';
import '../viewmodels/notification_center_viewmodel.dart';
import '../viewmodels/profile_state.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _mailtoCtrl;
  late final RecentSearchesStore _recentStore;
  bool _fieldsReady = false;
  int _savedTopicCount = 0;

  ProfileViewModel get _viewModel => ref.read(profileViewModelProvider.notifier);

  @override
  void initState() {
    super.initState();
    _apiKeyCtrl = TextEditingController();
    _mailtoCtrl = TextEditingController();
    _recentStore = ref.read(recentSearchesStoreProvider);
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
    final prefs = ref.read(sharedPreferencesProvider);
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
      await _viewModel.save(
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
      await _viewModel.save(
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
      await _viewModel.setDefaultHomeFilter(picked);
    }
  }

  /// Yêu cầu Home điền sẵn & tìm từ khoá, rồi chuyển sang tab Home.
  void _searchFromHistory(String query) {
    ref.read(pendingSearchProvider.notifier).request(query);
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

    final prefs = ref.read(sharedPreferencesProvider);
    _recentStore.clear();
    await prefs.remove(AppConstants.prefSavedTopics);
    await prefs.remove(AppConstants.prefLastSync);
    ref.read(selectedTopicProvider.notifier).clear();
    _loadLibraryCounts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared')),
      );
    }
  }

  /// Report Export (FR 4.8): lấy dashboard đang mở ở tab Keywords làm dữ liệu.
  /// Không có topic nào được phân tích thì không có gì để xuất.
  Future<void> _exportReport() async {
    final dashboard = ref.read(researchDashboardViewModelProvider);
    if (dashboard is! ResearchDashboardLoaded) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text(
              'Analyze a topic in Keywords first — the report is built from it.',
            ),
            action: SnackBarAction(
              label: 'Keywords',
              onPressed: () => context.go('/keywords'),
            ),
          ),
        );
      return;
    }
    await _viewModel.exportReport(dashboard.summary);
  }

  Future<void> _copyToClipboard(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label copied')));
  }

  Future<void> _confirmTestCrash() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Force a test crash?'),
        content: const Text(
          'The app will close immediately. Reopen it and the crash report '
          'will be uploaded to Crashlytics.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Crash'),
          ),
        ],
      ),
    );
    if (ok == true) _viewModel.testCrash();
  }

  Future<void> _showNotificationCenter() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final items = ref.watch(notificationCenterProvider);
          return SafeArea(
            key: WidgetKeys.notificationCenterSheet,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Notification Center',
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (items.isNotEmpty)
                        TextButton(
                          onPressed: ref
                              .read(notificationCenterProvider.notifier)
                              .clear,
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ),
                if (items.isEmpty)
                  const Padding(
                    key: WidgetKeys.notificationCenterEmpty,
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Text(
                      'No notifications yet.\n\nSend one from Firebase Console '
                      '(Messaging) using this device\'s FCM token.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) => _NotificationTile(item: items[i]),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _viewModel.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg =
        isDark ? AppColors.darkBackground : AppColors.surfaceMuted;

    ref.listen<ProfileState>(profileViewModelProvider, (_, state) {
      _syncFields(state);
      if (state.message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.message!)));
      }
      if (state.status == ProfileStatus.saved) {
        setState(() => _fieldsReady = true);
      }
    });

    final state = ref.watch(profileViewModelProvider);
    final authUser = ref.watch(authStateProvider).asData?.value;
    final notifications = ref.watch(notificationCenterProvider);
    _syncFields(state);
    final settings = state.settings;
    final isSaving = state.status == ProfileStatus.saving;
    final prefs = ref.read(sharedPreferencesProvider);
    final savedItems = prefs.getStringList(AppConstants.prefSavedTopics) ?? [];

    return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: pageBg,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: state.status == ProfileStatus.loading && !_fieldsReady
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    if (authUser != null) ...[
                      _UserHeader(
                        photoUrl: authUser.photoURL,
                        displayName: authUser.displayName ?? 'User',
                        email: authUser.email ?? '',
                        onSignOut: _confirmSignOut,
                      ),
                      const SizedBox(height: 24),
                    ],
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
                            onChanged: isSaving ? null : _viewModel.setDarkMode,
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
                    _SectionHeader(label: 'NOTIFICATIONS'),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          key: WidgetKeys.profileNotificationPermission,
                          icon: Icons.notifications_active_outlined,
                          title: 'Push notifications',
                          subtitle: state.notificationsGranted
                              ? 'Enabled'
                              : 'Tap to allow notifications',
                          showChevron: false,
                          trailing: state.notificationsGranted
                              ? const Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: AppColors.success,
                                )
                              : const Icon(Icons.chevron_right, size: 20),
                          onTap: state.notificationsGranted
                              ? null
                              : _viewModel.requestNotificationPermission,
                        ),
                        _SettingsRow(
                          key: WidgetKeys.profileNotificationCenter,
                          icon: Icons.inbox_outlined,
                          title: 'Notification Center',
                          badge: '${notifications.length}',
                          onTap: _showNotificationCenter,
                        ),
                        if (state.fcmToken != null)
                          _SettingsRow(
                            key: WidgetKeys.profileFcmToken,
                            icon: Icons.key_outlined,
                            title: 'FCM token',
                            subtitle: 'Tap to copy — paste in Firebase Console',
                            showChevron: false,
                            trailing: const Icon(Icons.copy, size: 18),
                            onTap: () =>
                                _copyToClipboard(state.fcmToken!, 'FCM token'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(label: 'REMOTE CONFIG'),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          key: WidgetKeys.profileMaxJournals,
                          icon: Icons.library_books_outlined,
                          title: 'max_journals_displayed',
                          subtitle: 'Journals listed per ranking',
                          showChevron: false,
                          badge: '${state.remoteConfig.maxJournalsDisplayed}',
                        ),
                        _SettingsRow(
                          key: WidgetKeys.profileMaxKeywords,
                          icon: Icons.sell_outlined,
                          title: 'max_keywords_displayed',
                          subtitle: 'Keywords listed per ranking',
                          showChevron: false,
                          badge: '${state.remoteConfig.maxKeywordsDisplayed}',
                        ),
                        _SettingsRow(
                          key: WidgetKeys.profileRemoteConfigRefresh,
                          icon: Icons.cloud_sync_outlined,
                          title: 'Fetch latest config',
                          showChevron: false,
                          trailing: const Icon(Icons.refresh, size: 18),
                          onTap: _viewModel.refreshRemoteConfig,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(label: 'REPORT EXPORT'),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          key: WidgetKeys.profileExportPdf,
                          icon: Icons.picture_as_pdf_outlined,
                          title: 'Export research report (PDF)',
                          subtitle: _exportSubtitle(state),
                          showChevron: false,
                          trailing: state.isExporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_outlined, size: 18),
                          onTap: state.isExporting ? null : _exportReport,
                        ),
                        if (state.reportUrl != null) ...[
                          _SettingsRow(
                            key: WidgetKeys.profileReportUrl,
                            icon: Icons.link_outlined,
                            title: 'Open uploaded report',
                            subtitle: state.reportUrl,
                            showChevron: false,
                            trailing: const Icon(Icons.open_in_new, size: 18),
                            onTap: () => _openUrl(state.reportUrl!),
                          ),
                          _SettingsRow(
                            key: WidgetKeys.profileCopyReportUrl,
                            icon: Icons.copy_outlined,
                            title: 'Copy report URL',
                            showChevron: false,
                            onTap: () => _copyToClipboard(
                              state.reportUrl!,
                              'Report URL',
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(label: 'CRASHLYTICS'),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          key: WidgetKeys.profileHandledException,
                          icon: Icons.bug_report_outlined,
                          title: 'Log handled exception',
                          subtitle: 'Non-fatal — app keeps running',
                          showChevron: false,
                          onTap: _viewModel.recordHandledException,
                        ),
                        _SettingsRow(
                          key: WidgetKeys.profileTestCrash,
                          icon: Icons.warning_amber_outlined,
                          title: 'Force test crash',
                          subtitle: 'Closes the app — report uploads on restart',
                          destructive: true,
                          showChevron: false,
                          onTap: _confirmTestCrash,
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
  }

  static String _maskApiKey(String key) {
    if (key.isEmpty) return 'Not configured';
    if (key.length <= 4) return '••••••••';
    return '${'•' * 8}${key.substring(key.length - 4)}';
  }

  static String _exportSubtitle(ProfileState state) => switch (state
      .exportStatus) {
    ReportExportStatus.generating => 'Building PDF…',
    ReportExportStatus.uploading => 'Uploading to Firebase Storage…',
    ReportExportStatus.done => 'Uploaded — link below',
    ReportExportStatus.error => 'Last export failed — tap to retry',
    ReportExportStatus.idle => 'Builds from the topic analyzed in Keywords',
  };
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final time = TimeOfDay.fromDateTime(item.receivedAt).format(context);

    return ListTile(
      leading: Icon(
        item.receivedInForeground
            ? Icons.notifications_active_outlined
            : Icons.open_in_new,
        size: 20,
        color: AppColors.secondary,
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: item.body.isEmpty ? null : Text(item.body),
      trailing: Text(
        time,
        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
      ),
      isThreeLine: item.body.length > 40,
    );
  }
}

class _UserHeader extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final String email;
  final VoidCallback onSignOut;

  const _UserHeader({
    required this.photoUrl,
    required this.displayName,
    required this.email,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? AppColors.darkSurfaceElevated : AppColors.white;
    final url = photoUrl;

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                  backgroundImage:
                      url != null && url.isNotEmpty ? NetworkImage(url) : null,
                  child: url == null || url.isEmpty
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    super.key,
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
