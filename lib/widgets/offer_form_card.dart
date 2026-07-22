import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calcwise_core/calcwise_core.dart';
import '../core/data/state_tax_data.dart';
import '../core/data/city_col_data.dart';
import '../core/data/salary_benchmark_data.dart';
import '../core/models/job_offer.dart';
import '../core/services/deadline_notification_service.dart';
import '../core/theme/app_theme.dart';
import '../l10n/strings_en.dart';
import '../l10n/strings_es.dart';
import 'offer_parser_dialog.dart';

class OfferFormCard extends StatefulWidget {
  final bool isOfferA;

  /// When true, this card represents Offer C (emerald color scheme).
  final bool isOfferC;
  final JobOffer value;
  final bool isPremium;
  final bool isSpanish;
  final ValueChanged<JobOffer> onChanged;
  const OfferFormCard({
    super.key,
    required this.isOfferA,
    this.isOfferC = false,
    required this.value,
    required this.isPremium,
    required this.isSpanish,
    required this.onChanged,
  });
  @override
  State<OfferFormCard> createState() => _OfferFormCardState();
}

class _OfferFormCardState extends State<OfferFormCard>
    with CalcwiseAutoCalcMixin {
  bool _expanded = true;
  bool _showBenefits = false;
  late final TextEditingController _salary,
      _label,
      _company,
      _bonus,
      _signing,
      _match,
      _upTo,
      _health,
      _dental,
      _pto,
      _rsu,
      _commute,
      _raise,
      _hoursPerWeek;

  @override
  void initState() {
    super.initState();
    final o = widget.value;
    _salary = _c(_salaryDisplayValue(o));
    _label = _c(o.label);
    _company = _c(o.company);
    _bonus = _c(o.bonusPct > 0 ? o.bonusPct.toStringAsFixed(0) : '');
    _signing = _c(o.signingBonus > 0 ? o.signingBonus.toStringAsFixed(0) : '');
    _match = _c(o.k401kMatchPct > 0 ? o.k401kMatchPct.toStringAsFixed(0) : '');
    _upTo = _c(o.k401kUpToPct > 0 ? o.k401kUpToPct.toStringAsFixed(0) : '');
    _health = _c(o.healthInsuranceSavings > 0
        ? o.healthInsuranceSavings.toStringAsFixed(0)
        : '');
    _dental = _c(o.dentalVisionSavings > 0
        ? o.dentalVisionSavings.toStringAsFixed(0)
        : '');
    _pto = _c(o.ptoDays > 0 ? o.ptoDays.toString() : '');
    _rsu = _c(o.annualRsuValue > 0 ? o.annualRsuValue.toStringAsFixed(0) : '');
    _commute = _c(o.commuteMilesPerDay > 0
        ? o.commuteMilesPerDay.toStringAsFixed(0)
        : '');
    _raise = _c(o.annualRaisePct.toStringAsFixed(1));
    _hoursPerWeek = _c(o.hoursPerWeek.toStringAsFixed(0));
  }

  String _salaryDisplayValue(JobOffer o) {
    if (o.isHourly && o.hoursPerWeek > 0) {
      final hourly = o.baseSalary / o.hoursPerWeek / 52;
      return hourly > 0 ? hourly.toStringAsFixed(2) : '';
    }
    return o.baseSalary > 0 ? o.baseSalary.toStringAsFixed(0) : '';
  }

  TextEditingController _c(String v) => TextEditingController(text: v);

  @override
  void dispose() {
    for (final c in [
      _salary,
      _label,
      _company,
      _bonus,
      _signing,
      _match,
      _upTo,
      _health,
      _dental,
      _pto,
      _rsu,
      _commute,
      _raise,
      _hoursPerWeek,
    ]) c.dispose();
    super.dispose();
  }

  Color get _c1 {
    if (widget.isOfferC) return AppTheme.offerC;
    return AppTheme.offerColor(widget.isOfferA);
  }

  LinearGradient get _grad {
    if (widget.isOfferC) return AppTheme.offerCGradient;
    return AppTheme.offerGradient(widget.isOfferA);
  }

  String get _offerLabel {
    final s = widget.isSpanish ? const AppStringsEs() : const AppStringsEn();
    if (widget.isOfferC) return s.offerC;
    return widget.isOfferA ? s.offerA : s.offerB;
  }

  String get _letterBadge {
    if (widget.isOfferC) return 'C';
    return widget.isOfferA ? 'A' : 'B';
  }

  void _emit() {
    final isHourly = widget.value.isHourly;
    final hpw = double.tryParse(_hoursPerWeek.text) ?? 40.0;
    final rawSalary = double.tryParse(_salary.text.replaceAll(',', '')) ?? 0;
    final annual = isHourly ? rawSalary * hpw * 52 : rawSalary;

    widget.onChanged(widget.value.copyWith(
      label: _label.text.isEmpty ? _offerLabel : _label.text,
      company: _company.text,
      baseSalary: annual,
      hoursPerWeek: hpw,
      bonusPct: double.tryParse(_bonus.text) ?? 0,
      signingBonus: double.tryParse(_signing.text) ?? 0,
      k401kMatchPct: double.tryParse(_match.text) ?? 0,
      k401kUpToPct: double.tryParse(_upTo.text) ?? 0,
      healthInsuranceSavings: double.tryParse(_health.text) ?? 0,
      dentalVisionSavings: double.tryParse(_dental.text) ?? 0,
      ptoDays: int.tryParse(_pto.text) ?? 0,
      annualRsuValue: double.tryParse(_rsu.text) ?? 0,
      commuteMilesPerDay: double.tryParse(_commute.text) ?? 0,
      annualRaisePct: double.tryParse(_raise.text) ?? 3,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ct = CalcwiseTheme.of(context);
    final s = widget.isSpanish ? const AppStringsEs() : const AppStringsEn();
    final shadow = widget.isOfferC
        ? AppTheme.offerCCardShadow
        : (widget.isOfferA
            ? AppTheme.offerACardShadow
            : AppTheme.offerBCardShadow);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: _expanded ? _c1.withValues(alpha: 0.35) : ct.cardBorder,
          width: _expanded ? 1.5 : 1,
        ),
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Column(children: [
          // ── gradient header ──────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                  AppSpacing.mdPlus, AppSpacing.mdPlus, AppSpacing.mdPlus),
              decoration: BoxDecoration(gradient: _grad),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.5),
                  ),
                  child: Center(
                      child: Text(
                    _letterBadge,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: AppTextSize.bodyLg),
                  )),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.value.label.isEmpty
                          ? _offerLabel
                          : widget.value.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: AppTextSize.bodyLg),
                    ),
                    if (widget.value.company.isNotEmpty)
                      Text(widget.value.company,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: AppTextSize.sm)),
                    if (widget.value.baseSalary > 0)
                      Text(
                        '\$${widget.value.baseSalary.toStringAsFixed(0)}${s.perYear}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: AppTextSize.md,
                            fontWeight: FontWeight.w600),
                      ),
                    if (widget.value.deadline != null) ...[
                      const SizedBox(height: 4),
                      _DeadlineHeaderBadge(deadline: widget.value.deadline!, isSpanish: widget.isSpanish),
                    ],
                  ],
                )),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ]),
            ),
          ),
          // ── body ─────────────────────────────────────────────────
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Paste offer letter (AI-style parser)
                  _pasteOfferButton(),
                  const SizedBox(height: AppSpacing.md),
                  // Name + Company
                  Row(children: [
                    Expanded(
                        child: _tf(
                            ctrl: _label,
                            label: s.offerName,
                            hint: _offerLabel,
                            icon: Icons.label_outline_rounded)),
                    const SizedBox(width: AppSpacing.smPlus),
                    Expanded(
                        child: _tf(
                            ctrl: _company,
                            label: s.company,
                            hint: 'Google, Meta…',
                            icon: Icons.business_rounded)),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  // Offer deadline (Feature 2)
                  _DeadlineRow(
                    deadline: widget.value.deadline,
                    isSpanish: widget.isSpanish,
                    color: _c1,
                    onDeadlineChanged: (d) {
                      final updated = d == null
                          ? widget.value.copyWith(clearDeadline: true)
                          : widget.value.copyWith(deadline: d);
                      widget.onChanged(updated);
                      if (d != null) {
                        DeadlineNotificationService.instance
                            .scheduleDeadlineAlert(
                          widget.value.label.isEmpty
                              ? _offerLabel
                              : widget.value.label,
                          d,
                          _letterBadge,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Hourly toggle (Feature 1)
                  _HourlyToggle(
                    isHourly: widget.value.isHourly,
                    isSpanish: widget.isSpanish,
                    color: _c1,
                    onToggle: (isHourly) {
                      // When switching modes, convert the salary display value
                      final current = widget.value;
                      if (isHourly && !current.isHourly) {
                        // Switching to hourly — show hourly equivalent
                        final hpw = current.hoursPerWeek > 0
                            ? current.hoursPerWeek
                            : 40.0;
                        final hourly = current.baseSalary / hpw / 52;
                        _salary.text =
                            hourly > 0 ? hourly.toStringAsFixed(2) : '';
                      } else if (!isHourly && current.isHourly) {
                        // Switching to annual — show annual equivalent
                        _salary.text = current.baseSalary > 0
                            ? current.baseSalary.toStringAsFixed(0)
                            : '';
                      }
                      widget.onChanged(current.copyWith(isHourly: isHourly));
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Salary field (Feature 1: changes label/formatter based on isHourly)
                  _salaryField(),
                  // Hrs/week field when hourly mode (Feature 1)
                  if (widget.value.isHourly) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _tf(
                      ctrl: _hoursPerWeek,
                      label: s.hrsWeek,
                      hint: '40',
                      num: true,
                      icon: Icons.schedule_rounded,
                      onCh: (_) => scheduleCalc(_emit),
                    ),
                  ],
                  // Salary benchmark chip (Feature 3)
                  _BenchmarkChip(
                    baseSalary: widget.value.baseSalary,
                    stateCode: widget.value.stateCode,
                    isSpanish: widget.isSpanish,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _stateDropdown(),
                  const SizedBox(height: AppSpacing.md),
                  // Bonus + PTO
                  Row(children: [
                    Expanded(
                        child: _tf(
                            ctrl: _bonus,
                            label: s.bonusPct,
                            hint: '10',
                            suffix: '%',
                            num: true,
                            icon: Icons.card_giftcard_rounded,
                            onCh: (_) => scheduleCalc(_emit))),
                    const SizedBox(width: AppSpacing.smPlus),
                    Expanded(
                        child: _tf(
                            ctrl: _pto,
                            label: s.ptoDays,
                            hint: '15',
                            num: true,
                            icon: Icons.beach_access_rounded,
                            onCh: (_) => scheduleCalc(_emit))),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  // Signing bonus
                  _tf(
                    ctrl: _signing,
                    label: s.signingBonus,
                    hint: '10000',
                    prefix: '\$',
                    num: true,
                    icon: Icons.monetization_on_rounded,
                    onCh: (_) => scheduleCalc(_emit),
                  ),
                  const SizedBox(height: AppSpacing.mdPlus),
                  // Benefits toggle
                  _BenefitsToggle(
                    expanded: _showBenefits,
                    isSp: widget.isSpanish,
                    color: _c1,
                    onTap: () => setState(() => _showBenefits = !_showBenefits),
                  ),
                  if (_showBenefits) ...[
                    const SizedBox(height: AppSpacing.mdPlus),
                    Row(children: [
                      Expanded(
                          child: _tf(
                              ctrl: _match,
                              label: widget.isSpanish ? 'Match 401k (%)' : '401k match (%)',
                              hint: '100',
                              suffix: '%',
                              num: true,
                              icon: Icons.savings_rounded,
                              helperText: widget.isSpanish
                                  ? 'Aporte del empleador'
                                  : 'Employer contribution rate',
                              onCh: (_) => scheduleCalc(_emit))),
                      const SizedBox(width: AppSpacing.smPlus),
                      Expanded(
                          child: _tf(
                              ctrl: _upTo,
                              label: s.upTo,
                              hint: '4',
                              suffix: '%',
                              num: true,
                              helperText: widget.isSpanish
                                  ? 'Tope del match, % del salario'
                                  : 'Match cap, as % of salary',
                              onCh: (_) => scheduleCalc(_emit))),
                    ]),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(
                          child: _tf(
                              ctrl: _health,
                              label: s.healthPerYr,
                              hint: '3000',
                              prefix: '\$',
                              num: true,
                              isCurrency: true,
                              icon: Icons.health_and_safety_rounded,
                              onCh: (_) => scheduleCalc(_emit))),
                      const SizedBox(width: AppSpacing.smPlus),
                      Expanded(
                          child: _tf(
                              ctrl: _dental,
                              label: s.dentalPerYr,
                              hint: '500',
                              prefix: '\$',
                              num: true,
                              isCurrency: true,
                              onCh: (_) => scheduleCalc(_emit))),
                    ]),
                    const SizedBox(height: AppSpacing.md),
                    _tf(
                        ctrl: _rsu,
                        label: s.annualRsuStock,
                        hint: '20000',
                        prefix: '\$',
                        num: true,
                        isCurrency: true,
                        icon: Icons.trending_up_rounded,
                        helperText: widget.isSpanish
                            ? 'RSU = unidades de acciones restringidas'
                            : 'RSU = Restricted Stock Units (stock grant)',
                        onCh: (_) => scheduleCalc(_emit)),
                    const SizedBox(height: AppSpacing.md),
                    _remoteToggle(),
                    if (!widget.value.isRemote) ...[
                      const SizedBox(height: AppSpacing.md),
                      _tf(
                          ctrl: _commute,
                          label: s.milesOneWayCommute,
                          hint: '15',
                          suffix: ' mi',
                          num: true,
                          icon: Icons.directions_car_rounded,
                          onCh: (_) => scheduleCalc(_emit)),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _cityDropdown(),
                    const SizedBox(height: AppSpacing.md),
                    _tf(
                        ctrl: _raise,
                        label: s.annualRaisePct,
                        hint: '3',
                        suffix: '%',
                        num: true,
                        icon: Icons.show_chart_rounded,
                        onCh: (_) => scheduleCalc(_emit)),
                  ],
                ],
              ),
            ),
        ]),
      ),
    );
  }

  // ── Paste offer letter button (AI-style regex parser) ─────────────────────

  Widget _pasteOfferButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: _openParser,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _c1.withValues(alpha: 0.16),
                _c1.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: _c1.withValues(alpha: 0.32)),
          ),
          child: Row(children: [
            Icon(Icons.auto_awesome_rounded, color: _c1, size: 18),
            const SizedBox(width: AppSpacing.smPlus),
            Expanded(
              child: Text(
                widget.isSpanish ? const AppStringsEs().pasteOfferLetter : const AppStringsEn().pasteOfferLetter,
                style: TextStyle(
                    color: _c1,
                    fontSize: AppTextSize.md,
                    fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _c1.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                widget.isSpanish ? const AppStringsEs().newBadge : const AppStringsEn().newBadge,
                style: TextStyle(
                  color: _c1,
                  fontSize: AppTextSize.xxs,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _openParser() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => OfferParserDialog(
        current: widget.value,
        isSpanish: widget.isSpanish,
        onApply: (filled) {
          widget.onChanged(filled);
          // Refresh local controllers so the UI reflects parsed values.
          _salary.text = _salaryDisplayValue(filled);
          _label.text = filled.label;
          _company.text = filled.company;
          _bonus.text =
              filled.bonusPct > 0 ? filled.bonusPct.toStringAsFixed(0) : '';
          _signing.text = filled.signingBonus > 0
              ? filled.signingBonus.toStringAsFixed(0)
              : '';
          _match.text = filled.k401kMatchPct > 0
              ? filled.k401kMatchPct.toStringAsFixed(0)
              : '';
          _pto.text = filled.ptoDays > 0 ? filled.ptoDays.toString() : '';
          _rsu.text = filled.annualRsuValue > 0
              ? filled.annualRsuValue.toStringAsFixed(0)
              : '';
          setState(() {});
        },
      ),
    ));
  }

  // ── Validator for numeric fields ──────────────────────────────────────────

  String? _numValidator(String? v, {bool allowEmpty = true}) {
    final s = widget.isSpanish ? const AppStringsEs() : const AppStringsEn();
    if (v == null || v.trim().isEmpty) return allowEmpty ? null : s.required;
    final n = double.tryParse(v.replaceAll(',', ''));
    if (n == null) return s.invalidNumber;
    if (n < 0) return s.mustBeGte0;
    return null;
  }

  // ── Salary field (Feature 1: label changes based on isHourly) ────────────

  Widget _salaryField() => TextFormField(
        controller: _salary,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: widget.value.isHourly
            ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
            : [CurrencyInputFormatter(locale: 'en_US')],
        validator: _numValidator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: (_) => scheduleCalc(_emit),
        style: TextStyle(
          fontSize: AppTextSize.titleMd,
          fontWeight: FontWeight.w700,
          color: _c1,
          letterSpacing: -0.5,
        ),
        decoration: InputDecoration(
          labelText: widget.value.isHourly
              ? (widget.isSpanish ? const AppStringsEs().hourlySalaryLabel : const AppStringsEn().hourlySalaryLabel)
              : (widget.isSpanish ? const AppStringsEs().annualSalaryLabel : const AppStringsEn().annualSalaryLabel),
          hintText: widget.value.isHourly ? '25.00' : '85,000',
          prefixText: '\$  ',
          suffixText: widget.value.isHourly ? '/hr' : '/yr',
          prefixStyle: TextStyle(
            fontSize: AppTextSize.subtitle,
            fontWeight: FontWeight.w700,
            color: _c1.withValues(alpha: 0.6),
          ),
          labelStyle: TextStyle(
              color: _c1.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
          floatingLabelStyle:
              TextStyle(color: _c1, fontWeight: FontWeight.w600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: BorderSide(color: _c1.withValues(alpha: 0.25)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: BorderSide(color: _c1.withValues(alpha: 0.22)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: BorderSide(color: _c1, width: 2),
          ),
          fillColor: _c1.withValues(alpha: 0.08),
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );

  // ── Generic field ─────────────────────────────────────────────────────────

  Widget _tf({
    required TextEditingController ctrl,
    required String label,
    String? hint,
    String? prefix,
    String? suffix,
    IconData? icon,
    bool num = false,
    bool isCurrency = false,
    String? helperText,
    ValueChanged<String>? onCh,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: num ? TextInputType.number : TextInputType.text,
        inputFormatters: isCurrency
            ? [CurrencyInputFormatter(locale: 'en_US')]
            : (num
                ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
                : null),
        validator: num ? _numValidator : null,
        autovalidateMode: num ? AutovalidateMode.onUserInteraction : null,
        onChanged: onCh ?? (_) => scheduleCalc(_emit),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefix,
          suffixText: suffix,
          prefixIcon: icon != null ? Icon(icon, size: 17) : null,
          helperText: helperText,
          helperMaxLines: 2,
          floatingLabelStyle:
              TextStyle(color: _c1, fontWeight: FontWeight.w600),
        ),
      );

  // ── State dropdown ────────────────────────────────────────────────────────

  Widget _stateDropdown() => DropdownButtonFormField<String>(
        initialValue: widget.value.stateCode,
        decoration: InputDecoration(
          labelText: widget.isSpanish ? const AppStringsEs().state : const AppStringsEn().state,
          floatingLabelStyle:
              TextStyle(color: _c1, fontWeight: FontWeight.w600),
          prefixIcon: const Icon(Icons.location_on_rounded, size: 17),
        ),
        items: StateTaxData.allStateCodes
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text('$s — ${StateTaxData.stateNames[s] ?? s}',
                      style: const TextStyle(fontSize: AppTextSize.md)),
                ))
            .toList(),
        onChanged: (s) {
          if (s != null) widget.onChanged(widget.value.copyWith(stateCode: s));
        },
      );

  // ── City dropdown ─────────────────────────────────────────────────────────

  Widget _cityDropdown() {
    final cities = CityColData.allCities;
    final cur = cities.contains(widget.value.city)
        ? widget.value.city
        : 'National Average';
    return DropdownButtonFormField<String>(
      initialValue: cur,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: widget.isSpanish ? const AppStringsEs().cityColLabel : const AppStringsEn().cityColLabel,
        floatingLabelStyle: TextStyle(color: _c1, fontWeight: FontWeight.w600),
        prefixIcon: const Icon(Icons.location_city_rounded, size: 17),
        suffixIcon:
            widget.isPremium ? null : const Icon(Icons.lock_outline, size: 16),
      ),
      items: cities
          .map((c) => DropdownMenuItem(
                value: c,
                child:
                    Text(c, style: const TextStyle(fontSize: AppTextSize.md)),
              ))
          .toList(),
      onChanged: widget.isPremium
          ? (c) {
              if (c != null) widget.onChanged(widget.value.copyWith(city: c));
            }
          : null,
    );
  }

  // ── Remote toggle ─────────────────────────────────────────────────────────

  Widget _remoteToggle() {
    final active = widget.value.isRemote;
    final ct = CalcwiseTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active ? ct.successGreen.withValues(alpha: 0.1) : ct.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color:
              active ? ct.successGreen.withValues(alpha: 0.35) : ct.cardBorder,
        ),
      ),
      child: Row(children: [
        Icon(
          active ? Icons.home_work_rounded : Icons.directions_car_rounded,
          size: 18,
          color: active ? ct.successGreen : ct.textSecondary,
        ),
        const SizedBox(width: AppSpacing.smPlus),
        Expanded(
            child: Text(
          widget.isSpanish ? const AppStringsEs().remoteWork : const AppStringsEn().remoteWork,
          style: TextStyle(
            fontSize: AppTextSize.body,
            color: active ? ct.successGreen : ct.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        )),
        Switch(
          value: active,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            widget.onChanged(widget.value.copyWith(isRemote: v));
          },
        ),
      ]),
    );
  }
}

// ── Feature 1: Hourly toggle ──────────────────────────────────────────────────

class _HourlyToggle extends StatelessWidget {
  final bool isHourly, isSpanish;
  final Color color;
  final ValueChanged<bool> onToggle;
  const _HourlyToggle({
    required this.isHourly,
    required this.isSpanish,
    required this.color,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Chip(
        label: isSpanish ? const AppStringsEs().annual : const AppStringsEn().annual,
        selected: !isHourly,
        color: color,
        onTap: () => onToggle(false),
      ),
      const SizedBox(width: AppSpacing.sm),
      _Chip(
        label: isSpanish ? const AppStringsEs().hourly : const AppStringsEn().hourly,
        selected: isHourly,
        color: color,
        onTap: () => onToggle(true),
      ),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ct = CalcwiseTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : ct.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.55) : ct.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTextSize.sm,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? color : ct.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Feature 2: Deadline row ───────────────────────────────────────────────────

class _DeadlineRow extends StatelessWidget {
  final DateTime? deadline;
  final bool isSpanish;
  final Color color;
  final ValueChanged<DateTime?> onDeadlineChanged;
  const _DeadlineRow({
    required this.deadline,
    required this.isSpanish,
    required this.color,
    required this.onDeadlineChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ct = CalcwiseTheme.of(context);
    return Row(children: [
      Icon(Icons.event_rounded, size: 16, color: ct.textSecondary),
      const SizedBox(width: AppSpacing.smPlus),
      Text(
        isSpanish ? const AppStringsEs().offerDeadline : const AppStringsEn().offerDeadline,
        style: TextStyle(fontSize: AppTextSize.sm, color: ct.textSecondary),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  deadline ?? DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) onDeadlineChanged(picked);
          },
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          child: _DeadlineChip(
            deadline: deadline,
            isSpanish: isSpanish,
            color: color,
          ),
        ),
      ),
      if (deadline != null)
        Semantics(
          label: isSpanish ? 'Borrar fecha límite' : 'Clear deadline',
          button: true,
          child: InkWell(
            onTap: () => onDeadlineChanged(null),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Center(
                  child: Icon(Icons.close_rounded, size: 16, color: ct.textSecondary),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}

class _DeadlineChip extends StatelessWidget {
  final DateTime? deadline;
  final bool isSpanish;
  final Color color;
  const _DeadlineChip({
    required this.deadline,
    required this.isSpanish,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ct = CalcwiseTheme.of(context);
    if (deadline == null) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: ct.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: ct.cardBorder),
        ),
        child: Text(
          isSpanish ? const AppStringsEs().noDeadline : const AppStringsEn().noDeadline,
          style: TextStyle(fontSize: AppTextSize.sm, color: ct.textSecondary),
        ),
      );
    }

    final now = DateTime.now();
    final daysLeft = deadline!.difference(now).inDays;
    final expired = daysLeft < 0;
    final urgent = !expired && daysLeft <= 2;

    Color chipColor;
    String label;
    String? suffix;

    if (expired) {
      chipColor = AppTheme.errorRed;
      label = isSpanish ? const AppStringsEs().deadlineExpired : const AppStringsEn().deadlineExpired;
    } else if (urgent) {
      chipColor = AppTheme.warningOrange;
      final dayStr = isSpanish ? const AppStringsEs().daysLeft : const AppStringsEn().daysLeft;
      label = _fmtDate(deadline!);
      suffix = '$daysLeft $dayStr ⚠️';
    } else {
      chipColor = AppTheme.successGreen;
      final dayStr = isSpanish ? const AppStringsEs().daysLeft : const AppStringsEn().daysLeft;
      label = _fmtDate(deadline!);
      suffix = '$daysLeft $dayStr';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: chipColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        suffix != null ? '$label · $suffix' : label,
        style: TextStyle(
          fontSize: AppTextSize.sm,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const monthsEn = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const monthsEs = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final months = isSpanish ? monthsEs : monthsEn;
    return '${months[d.month]} ${d.day}';
  }
}

// ── Feature 3: Salary benchmark chip ─────────────────────────────────────────

class _BenchmarkChip extends StatelessWidget {
  final double baseSalary;
  final String stateCode;
  final bool isSpanish;
  const _BenchmarkChip({
    required this.baseSalary,
    required this.stateCode,
    required this.isSpanish,
  });

  @override
  Widget build(BuildContext context) {
    if (baseSalary <= 0) return const SizedBox.shrink();

    final median = SalaryBenchmarkData.median(stateCode);
    final pctDiff = ((baseSalary - median) / median) * 100;
    final absDiff = pctDiff.abs().round();

    Color chipColor;
    String label;

    final sB = isSpanish ? const AppStringsEs() : const AppStringsEn();
    final medianK = (median / 1000).round();
    if (pctDiff > 10) {
      chipColor = AppTheme.successGreen;
      label = sB.benchmarkChipAbove(stateCode, medianK, absDiff);
    } else if (pctDiff < -10) {
      chipColor = AppTheme.warningOrange;
      label = sB.benchmarkChipBelow(stateCode, medianK, absDiff);
    } else {
      chipColor = AppTheme.textSecondary;
      label = sB.benchmarkChipAt(stateCode, medianK);
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs + 1),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(color: chipColor.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTextSize.xs,
            color: chipColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Deadline header badge (shown in collapsed card header) ───────────────────

class _DeadlineHeaderBadge extends StatelessWidget {
  final DateTime deadline;
  final bool isSpanish;
  const _DeadlineHeaderBadge({required this.deadline, required this.isSpanish});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysLeft = deadline.difference(now).inDays;
    if (daysLeft < 0) return const SizedBox.shrink();

    final Color badgeColor;
    final String label;

    final dayStr = isSpanish ? const AppStringsEs().daysLeft : const AppStringsEn().daysLeft;
    if (daysLeft <= 3) {
      badgeColor = AppTheme.errorRed;
      label = '$daysLeft $dayStr';
    } else if (daysLeft <= 14) {
      badgeColor = AppTheme.warningOrange;
      label = '$daysLeft $dayStr';
    } else {
      badgeColor = Theme.of(context).colorScheme.onSurface;
      label = _fmtDate(deadline);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smPlus, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.event_rounded,
            size: 11, color: badgeColor.withValues(alpha: 0.9)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTextSize.xxs,
            fontWeight: FontWeight.w700,
            color: badgeColor.withValues(alpha: 0.95),
          ),
        ),
      ]),
    );
  }

  String _fmtDate(DateTime d) {
    const monthsEn = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const monthsEs = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final months = isSpanish ? monthsEs : monthsEn;
    return '${months[d.month]} ${d.day}';
  }
}

// ── Benefits toggle ───────────────────────────────────────────────────────────

class _BenefitsToggle extends StatelessWidget {
  final bool expanded, isSp;
  final Color color;
  final VoidCallback onTap;
  const _BenefitsToggle({
    required this.expanded,
    required this.isSp,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(children: [
          Icon(
            expanded ? Icons.expand_less_rounded : Icons.add_circle_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              expanded
                  ? (isSp ? const AppStringsEs().hidebenefits : const AppStringsEn().hidebenefits)
                  : (isSp ? const AppStringsEs().benefitsAndCommute : const AppStringsEn().benefitsAndCommute),
              style: TextStyle(
                  color: color,
                  fontSize: AppTextSize.md,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!expanded) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.mdPlus),
              ),
              child: Text(
                isSp ? const AppStringsEs().benefits401kRsuHealth : const AppStringsEn().benefits401kRsuHealth,
                style: TextStyle(
                    fontSize: AppTextSize.xs, color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
