import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calcwise_core/calcwise_core.dart' hide PaywallHard;
import '../core/engines/offer_engine.dart';
import '../core/freemium/freemium_service.dart';
import '../core/language/language_notifier.dart';
import '../core/freemium/iap_service.dart';
import '../core/services/analytics_service.dart';
import '../core/models/job_offer.dart';
import '../core/models/comparison_result.dart';
import '../core/theme/app_theme.dart';
import '../widgets/offer_form_card.dart';
import '../widgets/paywall_hard.dart';
import '../widgets/paywall_soft.dart';
import '../main.dart'
    show adService, paywallSession, isSpanishNotifier, smartHistoryService;
import '../widgets/save_scenario_button.dart';
import 'comparison_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import '../l10n/strings_en.dart';
import '../l10n/strings_es.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  final _formKey = GlobalKey<FormState>();

  JobOffer _offerA = const JobOffer(
      label: 'Offer A',
      baseSalary: 85000,
      stateCode: 'CA',
      city: 'San Francisco, CA');
  JobOffer _offerB = const JobOffer(
      label: 'Offer B', baseSalary: 90000, stateCode: 'TX', city: 'Austin, TX');
  JobOffer _offerC = const JobOffer(
      label: 'Offer C', baseSalary: 0, stateCode: 'NY', city: 'New York, NY');
  bool _showOfferC = false;

  Timer? _debounce;
  bool _wasPremium = false;

  static const _appKey = 'jobofferus';
  static const _screenId = 'home';

  bool get _canCompare =>
      _offerA.baseSalary > 0 &&
      _offerB.baseSalary > 0 &&
      (!_showOfferC || _offerC.baseSalary > 0);

  /// Deterministic hash of the current offer inputs (rounded to ±5000).
  String _inputHash() {
    final map = <String, dynamic>{
      'base_a': ResultHasher.roundTo(_offerA.baseSalary, 5000),
      'state_a': _offerA.stateCode,
      'base_b': ResultHasher.roundTo(_offerB.baseSalary, 5000),
      'state_b': _offerB.stateCode,
    };
    if (_showOfferC && _offerC.baseSalary > 0) {
      map['base_c'] = ResultHasher.roundTo(_offerC.baseSalary, 5000);
      map['state_c'] = _offerC.stateCode;
    }
    return ResultHasher.hashMixed(map);
  }

  Map<String, dynamic> _l1Snapshot() {
    final result = OfferEngine.compare(
      _offerA,
      _offerB,
      _showOfferC && _offerC.baseSalary > 0 ? _offerC : null,
    );
    return {
      'offer_a_salary': _offerA.baseSalary,
      'offer_b_salary': _offerB.baseSalary,
      'offer_a_total': result.resultA.totalCompensation,
      'offer_b_total': result.resultB.totalCompensation,
      if (_showOfferC && _offerC.baseSalary > 0) ...{
        'offer_c_salary': _offerC.baseSalary,
        'offer_c_total': result.resultC?.totalCompensation ?? 0.0,
      },
    };
  }

  Map<String, dynamic> _l2Snapshot() {
    final offerCActive = _showOfferC && _offerC.baseSalary > 0;
    Map<String, dynamic> offerInputs(JobOffer o) => {
          'label': o.label,
          'company': o.company,
          'base_salary': o.baseSalary,
          'state': o.stateCode,
          'city': o.city,
          'bonus_pct': o.bonusPct,
          'signing_bonus': o.signingBonus,
          'rsu': o.annualRsuValue,
        };
    final result = OfferEngine.compare(
      _offerA,
      _offerB,
      offerCActive ? _offerC : null,
    );
    final winner = result.winner;
    return {
      'inputs': {
        'offerA': offerInputs(_offerA),
        'offerB': offerInputs(_offerB),
        if (offerCActive) 'offerC': offerInputs(_offerC),
      },
      'results': {
        'winner': winner == Winner.offerA
            ? 'A'
            : winner == Winner.offerB
                ? 'B'
                : winner == Winner.offerC
                    ? 'C'
                    : 'tie',
        'difference': result.annualAdvantage,
        'offer_a_total': result.resultA.totalCompensation,
        'offer_b_total': result.resultB.totalCompensation,
        if (offerCActive)
          'offer_c_total': result.resultC?.totalCompensation ?? 0.0,
      },
    };
  }

  @override
  void initState() {
    super.initState();
    _wasPremium = freemiumService.hasFullAccess;
    AnalyticsService.instance.logScreenView('home');
    iapErrorNotifier.addListener(_onIapError);
    iapRestoreResultNotifier.addListener(_onRestoreResult);
    freemiumService.isPremiumNotifier.addListener(_onPremiumChange);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) async => await paywallSession.recordSession());
  }

  @override
  void dispose() {
    iapErrorNotifier.removeListener(_onIapError);
    iapRestoreResultNotifier.removeListener(_onRestoreResult);
    freemiumService.isPremiumNotifier.removeListener(_onPremiumChange);
    _debounce?.cancel();
    smartHistoryService.cancelPendingSave(_appKey, _screenId);
    super.dispose();
  }

  void _onPremiumChange() {
    final now = freemiumService.hasFullAccess;
    unawaited(AnalyticsService.instance.setUserPremium(now));
    if (now && !_wasPremium && mounted) {
      showPremiumWelcomeSnackBar(context, isSpanish: isSpanishNotifier.value);
    }
    _wasPremium = now;
  }

  void _onIapError() {
    final msg = iapErrorNotifier.value;
    if (msg == null || !mounted) return;
    showIapErrorSnackBar(context, msg);
    iapErrorNotifier.value = null;
  }

  void _onRestoreResult() {
    final result = iapRestoreResultNotifier.value;
    if (result == null || !mounted) return;
    final isEs = isSpanishNotifier.value;
    final msg = result == 'restored'
        ? (isEs ? '¡Premium restaurado!' : 'Premium restored!')
        : (isEs ? 'No hay compras para restaurar.' : 'No purchases to restore.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
    iapRestoreResultNotifier.value = null;
  }

  void _debouncedCompare() {
    HapticFeedback.mediumImpact();
    if (!(_formKey.currentState?.validate() ?? true)) {
      final s =
          isSpanishNotifier.value ? const AppStringsEs() : const AppStringsEn();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.pleaseFixErrors),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(AppDuration.page, _compare);
  }

  void _scheduleAutoSaveIfValid() {
    if (!_canCompare) return;
    smartHistoryService.scheduleAutoSave(
      appKey: _appKey,
      screenId: _screenId,
      inputHash: _inputHash(),
      l1: _l1Snapshot(),
      l2: _l2Snapshot(),
      onSaved: () {
        if (mounted) {
          setState(() {});
          HistoryScreen.refreshNotifier.value++;
        }
      },
    );
  }

  void _compare() async {
    if (!_canCompare) return;
    // 3-offer comparison is a premium-only feature (hard gate).
    // 2-offer comparison is always free — no session gating.
    if (_showOfferC && !freemiumService.hasFullAccess) {
      _showPaywall();
      return;
    }
    AnalyticsService.instance.maybeLogFirstCalculate();
    AnalyticsService.instance.logCalculationCompleted(params: {
      'salary_a': _offerA.baseSalary.round(),
      'salary_b': _offerB.baseSalary.round(),
    });
    AnalyticsService.instance.logOfferCompared();
    adService.onAction();
    final offerCForCompare = _showOfferC ? _offerC : null;
    final result = OfferEngine.compare(_offerA, _offerB, offerCForCompare);
    smartHistoryService.scheduleAutoSave(
      appKey: _appKey,
      screenId: _screenId,
      inputHash: _inputHash(),
      l1: _l1Snapshot(),
      l2: _l2Snapshot(),
      onSaved: () {
        if (mounted) setState(() {});
      },
    );
    if (!mounted) return;
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => ComparisonScreen(
          offerA: _offerA,
          offerB: _offerB,
          offerC: offerCForCompare,
          result: result),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: AppDuration.base,
    ));
  }

  void _showPaywall() {
    PaywallHard.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));
    return ListenableBuilder(
      listenable: Listenable.merge([
        isSpanishNotifier,
        freemiumService.isRewardedNotifier,
        freemiumService.hasFullAccessNotifier,
      ]),
      builder: (_, __) {
        final isSp = isSpanishNotifier.value;
        final canSave = _canCompare &&
            (freemiumService.hasFullAccess || freemiumService.isRewarded);
        final screens = [
          _ComparisonTab(
            formKey: _formKey,
            offerA: _offerA,
            offerB: _offerB,
            offerC: _offerC,
            showOfferC: _showOfferC,
            isSp: isSp,
            onOfferAChanged: (o) {
              setState(() => _offerA = o);
              _scheduleAutoSaveIfValid();
            },
            onOfferBChanged: (o) {
              setState(() => _offerB = o);
              _scheduleAutoSaveIfValid();
            },
            onOfferCChanged: (o) {
              setState(() => _offerC = o);
              _scheduleAutoSaveIfValid();
            },
            onToggleOfferC: () => setState(() => _showOfferC = !_showOfferC),
            appBar: _appBar(isSp),
            saveButton: canSave
                ? SaveScenarioButton(
                    isSpanish: isSp,
                    onSave: (label) async {
                      await smartHistoryService.saveScenario(
                        appKey: _appKey,
                        screenId: _screenId,
                        inputHash: _inputHash(),
                        l1: _l1Snapshot(),
                        l2: _l2Snapshot(),
                        label: label,
                      );
                      HistoryScreen.refreshNotifier.value++;
                      try { AnalyticsService.instance.logResultSaved(); } catch (_) {}
                      adService.onSave();
                      final trigger = await paywallSession.recordAction();
                      if (!mounted) return;
                      if (trigger == PaywallTrigger.soft) PaywallSoft.show(context);
                      if (trigger == PaywallTrigger.hard) PaywallHard.show(context);
                    },
                  )
                : null,
          ),
          HistoryScreen(onSwitchToCompare: () => setState(() => _tabIndex = 0)),
        ];

        final s = isSp ? const AppStringsEs() : const AppStringsEn();
        return Scaffold(
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
              fit: StackFit.expand,
              children: List.generate(
                screens.length,
                (i) => IgnorePointer(
                  ignoring: _tabIndex != i,
                  child: CalcwiseTabReveal(
                      active: _tabIndex == i, child: screens[i]),
                ),
              ),
            ),
          ),
          floatingActionButton: _tabIndex == 0 ? _compareFab(isSp, s) : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: const CalcwiseAdFooter(),
              ),
              NavigationBar(
                selectedIndex: _tabIndex,
                onDestinationSelected: (i) => setState(() => _tabIndex = i),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.swap_horiz_rounded),
                    selectedIcon: const Icon(Icons.compare_arrows_rounded),
                    label: s.compare,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.bookmark_border_rounded),
                    selectedIcon: const Icon(Icons.bookmark_rounded),
                    label: s.history,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _compareFab(bool isSp, AppStrings s) {
    final active = _canCompare;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FloatingActionButton.extended(
          onPressed: active ? _debouncedCompare : null,
          backgroundColor: active
              ? AppTheme.primary
              : AppTheme.primary.withValues(alpha: 0.45),
          elevation: active ? 6 : 1,
          icon: Icon(Icons.compare_arrows_rounded,
              color:
                  active ? Colors.white : Colors.white.withValues(alpha: 0.5),
              size: 22),
          label: Text(
            s.compareOffers,
            style: TextStyle(
              color:
                  active ? Colors.white : Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w700,
              fontSize: AppTextSize.md,
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _appBar(bool isSp) {
    final ct = CalcwiseTheme.of(context);
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: AppTheme.ctaGradient,
            borderRadius: BorderRadius.circular(AppRadius.mdPlus),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 3))
            ],
          ),
          child: const Icon(Icons.compare_arrows_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(children: [
              TextSpan(
                  text: 'Job Offer',
                  style: TextStyle(
                      color: ct.textPrimary,
                      fontSize: AppTextSize.subtitleSm,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4)),
              TextSpan(
                  text: ' US',
                  style: TextStyle(
                      color: ct.accent,
                      fontSize: AppTextSize.subtitleSm,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4)),
            ]),
          ),
        ),
      ]),
      actions: [
        CalcwiseAppBarActions(
          freemium: freemiumService,
          session: paywallSession,
          onSettings: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const SettingsScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: AppDuration.base,
            ),
          ),
          onPremium: () {
            PaywallHard.show(context);
          },
        ),
      ],
    );
  }
}

// ── Comparison tab widget ─────────────────────────────────────────────────────

class _ComparisonTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final JobOffer offerA;
  final JobOffer offerB;
  final JobOffer offerC;
  final bool showOfferC;
  final bool isSp;
  final ValueChanged<JobOffer> onOfferAChanged;
  final ValueChanged<JobOffer> onOfferBChanged;
  final ValueChanged<JobOffer> onOfferCChanged;
  final VoidCallback onToggleOfferC;
  final PreferredSizeWidget appBar;
  final Widget? saveButton;

  const _ComparisonTab({
    required this.formKey,
    required this.offerA,
    required this.offerB,
    required this.offerC,
    required this.showOfferC,
    required this.isSp,
    required this.onOfferAChanged,
    required this.onOfferBChanged,
    required this.onOfferCChanged,
    required this.onToggleOfferC,
    required this.appBar,
    this.saveButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 180),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: formKey,
            child: CalcwisePageEntrance(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero ──────────────────────────────────────────────────────
                CalcwiseStaggerItem(
                    index: 0,
                    child: _HeroBanner(isSp: isSp, showOfferC: showOfferC)),
                const SizedBox(height: AppSpacing.lg),
                ValueListenableBuilder<bool>(
                  valueListenable: freemiumService.hasFullAccessNotifier,
                  builder: (_, isPremium, __) => Column(children: [
                    CalcwiseStaggerItem(
                        index: 1,
                        child: OfferFormCard(
                          isOfferA: true,
                          value: offerA,
                          isPremium: isPremium,
                          isSpanish: isSp,
                          onChanged: onOfferAChanged,
                        )),
                    const SizedBox(height: AppSpacing.lg),
                    _VsDivider(),
                    const SizedBox(height: AppSpacing.lg),
                    CalcwiseStaggerItem(
                        index: 2,
                        child: OfferFormCard(
                          isOfferA: false,
                          value: offerB,
                          isPremium: isPremium,
                          isSpanish: isSp,
                          onChanged: onOfferBChanged,
                        )),
                    const SizedBox(height: AppSpacing.lg),
                    // ── Offer C toggle / card ────────────────────────
                    if (showOfferC) ...[
                      _VsDivider(isSecond: true),
                      const SizedBox(height: AppSpacing.lg),
                      CalcwiseStaggerItem(
                          index: 3,
                          child: OfferFormCard(
                            isOfferA: false,
                            isOfferC: true,
                            value: offerC,
                            isPremium: isPremium,
                            isSpanish: isSp,
                            onChanged: onOfferCChanged,
                          )),
                      const SizedBox(height: AppSpacing.sm),
                      _RemoveOfferCChip(isSp: isSp, onTap: onToggleOfferC),
                    ] else
                      Center(
                          child: _AddOfferCChip(
                              isSp: isSp,
                              isPremium: isPremium,
                              onTap: onToggleOfferC)),
                  ]),
                ),
                if (saveButton != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  saveButton!,
                ],
              ],
            )), // CalcwisePageEntrance closes
          ), // Form closes
        ),
      ), // ConstrainedBox + Center closes
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

// on branded gradient — intentional
const _onHeroColor = Colors.white;

class _HeroBanner extends StatelessWidget {
  final bool isSp;
  final bool showOfferC;
  const _HeroBanner({required this.isSp, this.showOfferC = false});

  @override
  Widget build(BuildContext context) {
    final s = isSp ? const AppStringsEs() : const AppStringsEn();
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryDark.withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _LetterBadge('A', AppTheme.offerALight, AppTheme.offerADeep),
            const SizedBox(width: AppSpacing.sm),
            _LetterBadge('B', AppTheme.offerBLight, AppTheme.offerBDeep),
            if (showOfferC) ...[
              const SizedBox(width: AppSpacing.sm),
              _LetterBadge('C', AppTheme.offerCLight, AppTheme.offerCDeep),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.smPlus, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.verified_rounded, color: AppTheme.accent, size: 13),
                SizedBox(width: AppSpacing.xs),
                Text('2026',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: AppTextSize.sm,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          Text(
            s.heroTitle,
            style: const TextStyle(
              color: _onHeroColor,
              fontSize: AppTextSize.titleMd,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            s.heroSubtitle,
            style: TextStyle(
                color: _onHeroColor.withValues(alpha: 0.72),
                fontSize: AppTextSize.body,
                height: 1.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            _HChip(s.heroChip51States),
            const SizedBox(width: AppSpacing.sm),
            _HChip('FICA · IRS 2025'),
            const SizedBox(width: AppSpacing.sm),
            _HChip(s.heroChip3Offers,
                color: AppTheme.offerC.withValues(alpha: 0.22)),
          ]),
        ],
      ),
    );
  }
}

class _LetterBadge extends StatelessWidget {
  final String l;
  final Color bg, border;
  const _LetterBadge(this.l, this.bg, this.border);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: bg.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Center(
        child: Text(l,
            style: TextStyle(
                color: bg,
                fontSize: AppTextSize.bodyLg,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _HChip extends StatelessWidget {
  final String t;
  final Color? color;
  const _HChip(this.t, {this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smPlus, vertical: 5),
      decoration: BoxDecoration(
        color: color ?? _onHeroColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: _onHeroColor.withValues(alpha: 0.18)),
      ),
      child: Text(t,
          style: TextStyle(
              color: _onHeroColor.withValues(alpha: 0.88),
              fontSize: AppTextSize.sm,
              fontWeight: FontWeight.w500)),
    );
  }
}

// ── Add/Remove Offer C chips ──────────────────────────────────────────────────

class _AddOfferCChip extends StatelessWidget {
  final bool isSp;
  final bool isPremium;
  final VoidCallback onTap;
  const _AddOfferCChip(
      {required this.isSp, required this.onTap, this.isPremium = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.smPlus),
        decoration: BoxDecoration(
          color: AppTheme.offerC.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
              color: AppTheme.offerC.withValues(alpha: 0.35),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignOutside),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.add_circle_outline, color: AppTheme.offerC, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(
            (isSp ? const AppStringsEs() : const AppStringsEn()).add3rdOffer,
            style: const TextStyle(
              color: AppTheme.offerC,
              fontSize: AppTextSize.md,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!isPremium) ...[
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.star_rounded, color: AppTheme.offerC, size: 16),
          ],
        ]),
      ),
    );
  }
}

class _RemoveOfferCChip extends StatelessWidget {
  final bool isSp;
  final VoidCallback onTap;
  const _RemoveOfferCChip({required this.isSp, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ct = CalcwiseTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.smPlus),
        decoration: BoxDecoration(
          color: ct.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: ct.cardBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.remove_circle_outline, color: ct.textSecondary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(
            (isSp ? const AppStringsEs() : const AppStringsEn()).remove3rdOffer,
            style: TextStyle(
              color: ct.textSecondary,
              fontSize: AppTextSize.md,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── VS divider ────────────────────────────────────────────────────────────────

class _VsDivider extends StatelessWidget {
  final bool isSecond;
  const _VsDivider({this.isSecond = false});

  @override
  Widget build(BuildContext context) {
    final leftColor = isSecond ? AppTheme.offerBDeep : AppTheme.offerADeep;
    final rightColor = isSecond ? AppTheme.offerCDeep : AppTheme.offerBDeep;
    return Row(children: [
      Expanded(
          child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, leftColor],
                ),
              ))),
      const SizedBox(width: AppSpacing.sm),
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: isSecond ? AppTheme.offerCGradient : AppTheme.ctaGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isSecond ? AppTheme.offerCDeep : AppTheme.primary)
                  .withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Center(
          child: Text('VS',
              style: TextStyle(
                color: _onHeroColor,
                fontSize: AppTextSize.md,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              )),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
          child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [rightColor, Colors.transparent],
                ),
              ))),
    ]);
  }
}
