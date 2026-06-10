import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:calcwise_core/calcwise_core.dart';
import '../core/db/database_helper.dart';
import '../core/freemium/freemium_service.dart';
import '../core/freemium/iap_service.dart';
import '../core/language/language_notifier.dart';
import '../core/theme/app_theme.dart';
import '../core/services/analytics_service.dart';
import '../l10n/strings_en.dart';
import '../l10n/strings_es.dart';
import '../main.dart' show smartHistoryService;
import 'history_detail_screen.dart';

enum _CardAction { unpin, rename, delete }

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onSwitchToCompare;
  const HistoryScreen({super.key, this.onSwitchToCompare});

  static final refreshNotifier = ValueNotifier<int>(0);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _firstLoad = true;

  final _fmtDate = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('history');
    _load();
    HistoryScreen.refreshNotifier.addListener(_silentRefresh);
  }

  @override
  void dispose() {
    HistoryScreen.refreshNotifier.removeListener(_silentRefresh);
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await DatabaseHelper.instance.getHistory();
    if (mounted) {
      setState(() {
        _history = rows;
        _firstLoad = false;
      });
    }
  }

  Future<void> _silentRefresh() async {
    final rows = await DatabaseHelper.instance.getHistory();
    if (mounted) setState(() => _history = rows);
  }

  // ── Sections ────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _pinned =>
      _history.where((r) => (r['is_pinned'] as int? ?? 0) == 1).toList();

  List<Map<String, dynamic>> get _autoSaves =>
      _history.where((r) => (r['is_pinned'] as int? ?? 0) == 0).toList();

  List<Map<String, dynamic>> get _visibleAutoSaves {
    if (freemiumService.hasFullAccess || freemiumService.isRewarded) {
      return _autoSaves;
    }
    return _autoSaves.take(MonetizationConfig.freeRingBufferSize).toList();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _delete(int id, BuildContext context, bool isEs) async {
    HapticFeedback.mediumImpact();
    final confirm = await _confirmDelete(context, isEs);
    if (confirm == true) {
      try {
        await DatabaseHelper.instance.deleteHistory(id);
        _load();
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((isEs ? const AppStringsEs() : const AppStringsEn()).failedToDelete),
            behavior: SnackBarBehavior.floating,
            backgroundColor: CalcwiseSemanticColors.errorDark,
          ),
        );
      }
    }
  }

  Future<void> _unpin(int id) async {
    HapticFeedback.selectionClick();
    await smartHistoryService.unpin(id);
    _load();
  }

  Future<void> _rename(Map<String, dynamic> row, bool isEs) async {
    final ctrl = TextEditingController(
      text: (row['pin_label'] as String?) ?? '',
    );
    final s = isEs ? const AppStringsEs() : const AppStringsEn();
    final label = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.renameScenario),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: s.scenarioName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: Text(s.saveScenario),
          ),
        ],
      ),
    );
    if (label == null) return;
    await smartHistoryService.rename(row['id'] as int, label.trim());
    _load();
  }

  Future<bool?> _confirmDelete(BuildContext context, bool isEs) {
    final s = isEs ? const AppStringsEs() : const AppStringsEn();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteOffer),
        content: Text(s.deleteOfferBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.delete,
              style: TextStyle(
                  color:
                      CalcwiseSemanticColors.error(Theme.of(ctx).brightness)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAll(BuildContext context, bool isEs) async {
    final s = isEs ? const AppStringsEs() : const AppStringsEn();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.clearAllTitle),
        content: Text(s.clearAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.clear,
              style: TextStyle(
                  color:
                      CalcwiseSemanticColors.error(Theme.of(ctx).brightness)),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await DatabaseHelper.instance.clearHistory();
        _load();
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((isEs ? const AppStringsEs() : const AppStringsEn()).failedToClear),
            behavior: SnackBarBehavior.floating,
            backgroundColor: CalcwiseSemanticColors.errorDark,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isSpanishNotifier,
      builder: (context, isEs, _) {
        final s = isEs ? const AppStringsEs() : const AppStringsEn();
        return Scaffold(
          appBar: AppBar(
            title: Text(s.savedOffers),
            actions: [
              ValueListenableBuilder<bool>(
                valueListenable: freemiumService.hasFullAccessNotifier,
                builder: (context, isPremium, _) {
                  if (isPremium && _history.isNotEmpty) {
                    return IconButton(
                      icon: Icon(Icons.delete_sweep,
                          color: CalcwiseSemanticColors.error(
                              Theme.of(context).brightness)),
                      tooltip: s.clearAll,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _clearAll(context, isEs);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _firstLoad
                    ? const _HistorySkeleton()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: CustomScrollView(
                          slivers: [
                            // ── Header with count ─────────────────────────
                            SliverToBoxAdapter(child: _buildHeader(context, isEs)),

                            // ── Empty state ───────────────────────────────
                            if (_history.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: CalcwiseEmptyState(
                                  icon: Icons.work_outline,
                                  title: s.noSavedOffers,
                                  body: s.noSavedOffersBody,
                                  actionLabel: widget.onSwitchToCompare != null
                                      ? s.compareNow
                                      : null,
                                  onAction: widget.onSwitchToCompare,
                                ),
                              )
                            else ...[
                              // ── Pinned scenarios ──────────────────────────
                              if (_pinned.isNotEmpty) ...[
                                SliverToBoxAdapter(
                                  child: _sectionHeader(
                                      context,
                                      s.savedScenarios,
                                      Icons.bookmark_rounded),
                                ),
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, i) => Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          AppSpacing.lg,
                                          0,
                                          AppSpacing.lg,
                                          AppSpacing.smPlus),
                                      child: _buildCard(
                                          context, _pinned[i], isEs,
                                          pinned: true),
                                    ),
                                    childCount: _pinned.length,
                                  ),
                                ),
                              ],

                              // ── Recent comparisons (auto-saves) ───────────
                              if (_visibleAutoSaves.isNotEmpty) ...[
                                SliverToBoxAdapter(
                                  child: _sectionHeader(
                                      context,
                                      s.recentComparisons,
                                      Icons.history_rounded),
                                ),
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, i) => Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          AppSpacing.lg,
                                          0,
                                          AppSpacing.lg,
                                          AppSpacing.smPlus),
                                      child: _buildCard(
                                          context, _visibleAutoSaves[i], isEs,
                                          pinned: false),
                                    ),
                                    childCount: _visibleAutoSaves.length,
                                  ),
                                ),
                              ],
                            ],

                            const SliverToBoxAdapter(
                                child: SizedBox(height: 80)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isEs) {
    final s = isEs ? const AppStringsEs() : const AppStringsEn();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: ValueListenableBuilder<bool>(
        valueListenable: freemiumService.hasFullAccessNotifier,
        builder: (context, isPremium, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPremium
                    ? '${_history.length} ${s.saved}'
                    : '${_autoSaves.length} / ${MonetizationConfig.freeRingBufferSize} ${s.saved}',
                style: TextStyle(
                  color: CalcwiseTheme.of(context).textSecondary,
                  fontSize: AppTextSize.md,
                ),
              ),
              if (!isPremium) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(children: [
                  const Icon(Icons.lock_outline,
                      size: 14, color: CalcwiseSemanticColors.warnIcon),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      isEs
                          ? 'Máx ${MonetizationConfig.freeRingBufferSize} recientes · ${MonetizationConfig.freePinnedLimit} guardados'
                          : 'Max ${MonetizationConfig.freeRingBufferSize} recent · ${MonetizationConfig.freePinnedLimit} pinned',
                      style: TextStyle(
                          fontSize: AppTextSize.sm,
                          color: CalcwiseTheme.of(context).textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => IAPService.instance.buy(),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(
                      s.unlock,
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: AppTextSize.sm),
                    ),
                  ),
                ]),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppTextSize.xs,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ── Card ────────────────────────────────────────────────────────────────────

  Widget _buildCard(BuildContext context, Map<String, dynamic> row, bool isEs,
      {required bool pinned}) {
    final id = row['id'] as int? ?? 0;
    final jobTitle = row['job_title'] as String? ?? '';
    final company = row['company'] as String? ?? '';
    final pinLabel = row['pin_label'] as String?;
    final netSalary = (row['net_salary'] as num?)?.toDouble() ?? 0.0;
    final monthlyNet = (row['monthly_net'] as num?)?.toDouble() ?? 0.0;
    final taxRate = (row['tax_rate'] as num?)?.toDouble() ?? 0.0;
    final createdAt =
        DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ??
            DateTime.now();

    final ct = CalcwiseTheme.of(context);
    final s = isEs ? const AppStringsEs() : const AppStringsEn();
    final title = pinned && pinLabel != null && pinLabel.isNotEmpty
        ? pinLabel
        : (jobTitle.isNotEmpty ? jobTitle : s.offerLabel);

    final card = InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistoryDetailScreen(row: row, isSpanish: isEs),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: pinned
                ? AppTheme.primary.withValues(alpha: 0.5)
                : ct.cardBorder,
            width: pinned ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.mdPlus, vertical: AppSpacing.md),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // ── Left: icon ──────────────────────────────────────────────
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(pinned ? Icons.bookmark_rounded : Icons.work_outline,
                  color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),

            // ── Center: job info ────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: AppTextSize.body,
                        fontWeight: FontWeight.w700,
                        color: ct.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (company.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(company,
                        style: TextStyle(
                            fontSize: AppTextSize.sm, color: ct.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: AppSpacing.xxs),
                  Row(children: [
                    Flexible(
                      child: Text(
                        '${AmountFormatter.ui(monthlyNet, 'USD')}${s.perMonth}',
                        style: TextStyle(
                            fontSize: AppTextSize.sm, color: ct.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '· ${s.tax} ${taxRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: AppTextSize.xs, color: ct.textSecondary),
                    ),
                  ]),
                  const SizedBox(height: 1),
                  Text(
                    _fmtDate.format(createdAt),
                    style: TextStyle(
                        fontSize: AppTextSize.xs, color: ct.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Right: hero net salary + (pinned) menu ──────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 100,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      AmountFormatter.ui(netSalary, 'USD'),
                      style: const TextStyle(
                        fontSize: AppTextSize.display,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                Text(
                  s.netPerYear,
                  style: TextStyle(
                      fontSize: AppTextSize.xs, color: ct.textSecondary),
                ),
              ],
            ),
            if (pinned)
              SizedBox(
                height: 32,
                width: 32,
                child: PopupMenuButton<_CardAction>(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 18, color: ct.textSecondary),
                  padding: EdgeInsets.zero,
                  onSelected: (action) {
                    switch (action) {
                      case _CardAction.unpin:
                        _unpin(id);
                      case _CardAction.rename:
                        _rename(row, isEs);
                      case _CardAction.delete:
                        _delete(id, context, isEs);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _CardAction.unpin,
                      child: Row(children: [
                        const Icon(Icons.bookmark_remove_outlined, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(s.unpin),
                      ]),
                    ),
                    PopupMenuItem(
                      value: _CardAction.rename,
                      child: Row(children: [
                        const Icon(Icons.edit_outlined, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(s.rename),
                      ]),
                    ),
                    PopupMenuItem(
                      value: _CardAction.delete,
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18,
                            color: CalcwiseSemanticColors.error(
                                Theme.of(context).brightness)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(s.delete,
                            style: TextStyle(
                                color: CalcwiseSemanticColors.error(
                                    Theme.of(context).brightness))),
                      ]),
                    ),
                  ],
                ),
              ),
          ]),
        ),
      ),
    );

    // Non-pinned auto-saves are swipe-to-delete; pinned use the menu.
    if (pinned) return card;
    return Dismissible(
      key: Key('offer-$id'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, isEs),
      onDismissed: (_) async {
        await DatabaseHelper.instance.deleteHistory(id);
        await _load();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: CalcwiseSemanticColors.errorDark.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: const Icon(Icons.delete_outline,
            color: CalcwiseSemanticColors.errorDark, size: 24),
      ),
      child: card,
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
          children: List.generate(
              4,
              (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CalcwiseSkeleton.box(height: 80),
                  ))),
    );
  }
}
