import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calcwise_core/calcwise_core.dart' hide PaywallHard;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/data/salary_benchmark_data.dart';
import '../core/db/database_helper.dart';
import '../core/engines/insight_engine.dart';
import '../core/freemium/iap_service.dart';
import '../core/freemium/freemium_service.dart';
import '../core/services/analytics_service.dart';
import '../core/language/language_notifier.dart';
import '../core/models/comparison_result.dart';
import '../core/models/job_offer.dart';
import '../core/theme/app_theme.dart';
import '../widgets/comparison_bar.dart';
import '../widgets/insight_card.dart';
import '../widgets/paywall_hard.dart';
import '../widgets/paywall_soft.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import '../main.dart' show adService, paywallSession, smartHistoryService;
import 'history_screen.dart';
import '../core/engines/offer_engine.dart' show OfferEngine;
import '../widgets/save_scenario_button.dart';
import '../l10n/strings_en.dart';
import '../l10n/strings_es.dart';

// ── PDF Isolate support ───────────────────────────────────────────────────────

class _ComparisonPdfParams {
  final String pdfTitle;
  final String generated;
  final String dateLabel;
  final String winnerLabel;
  final bool isTie;
  final String advantage;
  final String advantageText;
  final String metric;
  final String offerALabel;
  final String offerBLabel;
  final String? offerCLabel;
  final bool hasC;
  // Row labels
  final String grossSalary;
  final String netAnnualTakeHome;
  final String netMonthly;
  final String effectiveTaxRate;
  final String annualBonusAfterTax;
  final String signingBonusAfterTax;
  final String match401k;
  final String healthBenefits;
  final String annualRsu;
  final String commuteCost;
  final String totalNetCompensation;
  final String ptoValue;
  final String colAdjustedTakeHome;
  final String total5Years;
  final String pdfDisclaimer;
  // Values A
  final double grossA, netA, monthlyA, taxRateA, bonusAfterTaxA,
      signingAfterTaxA, k401kA, healthA, rsuA, commuteA, totalCompA, ptoA;
  // Values B
  final double grossB, netB, monthlyB, taxRateB, bonusAfterTaxB,
      signingAfterTaxB, k401kB, healthB, rsuB, commuteB, totalCompB, ptoB;
  // Values C (nullable)
  final double? grossC, netC, monthlyC, taxRateC, bonusAfterTaxC,
      signingAfterTaxC, k401kC, healthC, rsuC, commuteC, totalCompC, ptoC;
  // Premium: CoL-adjusted take-home and 5-year total comp (nullable — premium only)
  final double? colAdjA, colAdjB, colAdjC;
  final double? fiveYrTotalA, fiveYrTotalB, fiveYrTotalC;
  final bool showSigning;
  final bool isPremium;

  const _ComparisonPdfParams({
    required this.pdfTitle,
    required this.generated,
    required this.dateLabel,
    required this.winnerLabel,
    required this.isTie,
    required this.advantage,
    required this.advantageText,
    required this.metric,
    required this.offerALabel,
    required this.offerBLabel,
    this.offerCLabel,
    required this.hasC,
    required this.grossSalary,
    required this.netAnnualTakeHome,
    required this.netMonthly,
    required this.effectiveTaxRate,
    required this.annualBonusAfterTax,
    required this.signingBonusAfterTax,
    required this.match401k,
    required this.healthBenefits,
    required this.annualRsu,
    required this.commuteCost,
    required this.totalNetCompensation,
    required this.ptoValue,
    required this.colAdjustedTakeHome,
    required this.total5Years,
    required this.pdfDisclaimer,
    required this.grossA,
    required this.netA,
    required this.monthlyA,
    required this.taxRateA,
    required this.bonusAfterTaxA,
    required this.signingAfterTaxA,
    required this.k401kA,
    required this.healthA,
    required this.rsuA,
    required this.commuteA,
    required this.totalCompA,
    required this.ptoA,
    required this.grossB,
    required this.netB,
    required this.monthlyB,
    required this.taxRateB,
    required this.bonusAfterTaxB,
    required this.signingAfterTaxB,
    required this.k401kB,
    required this.healthB,
    required this.rsuB,
    required this.commuteB,
    required this.totalCompB,
    required this.ptoB,
    this.grossC,
    this.netC,
    this.monthlyC,
    this.taxRateC,
    this.bonusAfterTaxC,
    this.signingAfterTaxC,
    this.k401kC,
    this.healthC,
    this.rsuC,
    this.commuteC,
    this.totalCompC,
    this.ptoC,
    this.colAdjA,
    this.colAdjB,
    this.colAdjC,
    this.fiveYrTotalA,
    this.fiveYrTotalB,
    this.fiveYrTotalC,
    required this.showSigning,
    required this.isPremium,
  });
}

Future<Uint8List> _buildComparisonPdf(_ComparisonPdfParams p) async {
  final pctFmt = NumberFormat('0.0#', 'en_US');
  final primary = PdfColor.fromHex('1565C0');
  final grey = PdfColors.grey700;

  pw.TableRow row(String label, String valA, String valB,
          {bool bold = false, String? valC}) =>
      pw.TableRow(children: [
        pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(label,
                style: pw.TextStyle(fontSize: 10, color: grey))),
        pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(valA,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal))),
        pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(valB,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal))),
        if (p.hasC)
          pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(valC ?? '',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight:
                          bold ? pw.FontWeight.bold : pw.FontWeight.normal))),
      ]);

  String fmt(double v) => AmountFormatter.ui(v, 'USD');
  String pct(double v) => '${pctFmt.format(v)}%';

  final pdf = pw.Document();
  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(AppSpacing.xxxl),
    build: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
            p.pdfTitle,
            style: pw.TextStyle(
                fontSize: AppTextSize.titleMd,
                fontWeight: pw.FontWeight.bold,
                color: primary)),
        pw.SizedBox(height: 4),
        pw.Text(
            '${p.generated}: ${p.dateLabel}',
            style: pw.TextStyle(fontSize: 9, color: grey)),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('E3F2FD'),
            borderRadius: pw.BorderRadius.circular(AppRadius.sm),
          ),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('★ ${p.winnerLabel}',
                    style: pw.TextStyle(
                        fontSize: AppTextSize.md,
                        fontWeight: pw.FontWeight.bold,
                        color: primary)),
                if (!p.isTie)
                  pw.Text(
                      '+${p.advantage} ${p.advantageText}',
                      style: pw.TextStyle(
                          fontSize: AppTextSize.xs, color: primary)),
              ]),
        ),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: p.hasC
              ? {
                  0: const pw.FlexColumnWidth(2.5),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.2),
                }
              : {
                  0: const pw.FlexColumnWidth(2.5),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: primary),
              children: [
                pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(p.metric,
                        style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold))),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(p.offerALabel,
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold))),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(p.offerBLabel,
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold))),
                if (p.hasC)
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(p.offerCLabel ?? '',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold))),
              ],
            ),
            row(p.grossSalary, fmt(p.grossA), fmt(p.grossB),
                bold: true, valC: p.hasC ? fmt(p.grossC!) : null),
            row(p.netAnnualTakeHome, fmt(p.netA), fmt(p.netB),
                bold: true, valC: p.hasC ? fmt(p.netC!) : null),
            row(p.netMonthly, fmt(p.monthlyA), fmt(p.monthlyB),
                valC: p.hasC ? fmt(p.monthlyC!) : null),
            row(p.effectiveTaxRate, pct(p.taxRateA), pct(p.taxRateB),
                valC: p.hasC ? pct(p.taxRateC!) : null),
            row(p.annualBonusAfterTax, fmt(p.bonusAfterTaxA),
                fmt(p.bonusAfterTaxB),
                valC: p.hasC ? fmt(p.bonusAfterTaxC!) : null),
            if (p.showSigning)
              row(p.signingBonusAfterTax, fmt(p.signingAfterTaxA),
                  fmt(p.signingAfterTaxB),
                  valC: p.hasC ? fmt(p.signingAfterTaxC!) : null),
            row(p.match401k, fmt(p.k401kA), fmt(p.k401kB),
                valC: p.hasC ? fmt(p.k401kC!) : null),
            row(p.healthBenefits, fmt(p.healthA), fmt(p.healthB),
                valC: p.hasC ? fmt(p.healthC!) : null),
            row(p.ptoValue, fmt(p.ptoA), fmt(p.ptoB),
                valC: p.hasC ? fmt(p.ptoC!) : null),
            row(p.annualRsu, fmt(p.rsuA), fmt(p.rsuB),
                valC: p.hasC ? fmt(p.rsuC!) : null),
            row(p.commuteCost, fmt(p.commuteA), fmt(p.commuteB),
                valC: p.hasC ? fmt(p.commuteC!) : null),
            row(p.totalNetCompensation, fmt(p.totalCompA), fmt(p.totalCompB),
                bold: true, valC: p.hasC ? fmt(p.totalCompC!) : null),
            if (p.isPremium && p.colAdjA != null && p.colAdjB != null)
              row(p.colAdjustedTakeHome, fmt(p.colAdjA!), fmt(p.colAdjB!),
                  valC: p.hasC && p.colAdjC != null ? fmt(p.colAdjC!) : null),
            if (p.isPremium && p.fiveYrTotalA != null && p.fiveYrTotalB != null)
              row(p.total5Years, fmt(p.fiveYrTotalA!), fmt(p.fiveYrTotalB!),
                  bold: true,
                  valC: p.hasC && p.fiveYrTotalC != null
                      ? fmt(p.fiveYrTotalC!)
                      : null),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          p.pdfDisclaimer,
          style: pw.TextStyle(
              fontSize: 8, color: grey, fontStyle: pw.FontStyle.italic),
        ),
      ],
    ),
  ));

  return pdf.save();
}

// ─────────────────────────────────────────────────────────────────────────────

class ComparisonScreen extends StatefulWidget {
  final JobOffer offerA;
  final JobOffer offerB;
  final JobOffer? offerC;
  final ComparisonResult result;

  const ComparisonScreen({
    super.key,
    required this.offerA,
    required this.offerB,
    this.offerC,
    required this.result,
  });

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  bool _saved = false;

  static const _appKey = 'jobofferus';
  static const _screenId = 'comparison';

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('comparison');
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Deterministic hash of the key inputs across all offers in this comparison.
  String _inputHash() {
    final o = <JobOffer>[
      widget.offerA,
      widget.offerB,
      if (widget.offerC != null) widget.offerC!,
    ];
    final map = <String, dynamic>{};
    for (var i = 0; i < o.length; i++) {
      map['base_$i'] = ResultHasher.roundTo(o[i].baseSalary, 1000);
      map['state_$i'] = o[i].stateCode;
      map['city_$i'] = o[i].city;
      map['bonus_$i'] = ResultHasher.roundTo(o[i].bonusPct, 0.5);
      map['signing_$i'] = ResultHasher.roundTo(o[i].signingBonus, 1000);
      map['rsu_$i'] = ResultHasher.roundTo(o[i].annualRsuValue, 1000);
    }
    map['count'] = o.length;
    return ResultHasher.hashMixed(map);
  }

  /// Builds the full SmartHistory snapshot (hash + l1 list summary + l2 full
  /// comparison snapshot) for the current comparison.
  ({String hash, Map<String, dynamic> l1, Map<String, dynamic> l2})
      _buildSnapshot() {
    final a = widget.result.resultA;
    final b = widget.result.resultB;
    final c = widget.result.resultC;
    final winner = widget.result.winner;
    final winnerResult = widget.result.winnerResult;
    final winnerOffer = winner == Winner.offerA
        ? widget.offerA
        : winner == Winner.offerC
            ? (widget.offerC ?? widget.offerA)
            : widget.offerB;

    Map<String, dynamic> offerJson(JobOffer o, OfferResult r) => {
          'label': o.label,
          'company': o.company,
          'city': o.city,
          'state': o.stateCode,
          'remote': o.isRemote,
          'base': o.baseSalary,
          'bonus_pct': o.bonusPct,
          'signing': o.signingBonus,
          'rsu': o.annualRsuValue,
          'pto': o.ptoDays,
          'k401k_match_pct': o.k401kMatchPct,
          'k401k_up_to_pct': o.k401kUpToPct,
          'commute_miles': o.commuteMilesPerDay,
          'health_savings': o.healthInsuranceSavings + o.dentalVisionSavings,
          'annual_raise_pct': o.annualRaisePct,
          'is_hourly': o.isHourly,
          'hours_per_week': o.hoursPerWeek,
          'deadline': o.deadline?.toIso8601String(),
          'gross': r.grossSalary,
          'federal': r.federalTax,
          'state_tax': r.stateTax,
          'local_tax': r.localTax,
          'fica': r.ficaTax,
          'total_tax': r.totalTax,
          'tax_rate': r.effectiveTaxRate,
          'net': r.netTakeHome,
          'monthly': r.monthlyTakeHome,
          'bonus_net': r.bonusAfterTax,
          'annual_bonus': r.annualBonus,
          'signing_net': r.signingBonusAfterTax,
          'k401k_match_usd': r.k401kMatch,
          'health': r.healthBenefits,
          'pto_value': r.ptoValue,
          'rsu_value': r.annualRsuValue,
          'commute_cost': r.commuteCost,
          'total_comp': r.totalCompensation,
          'col_adj': r.colAdjustedTakeHome,
          '5yr': r.fiveYearProjection,
          'cumulative_5yr': r.cumulativeComp5Yr,
          'k401k_wealth_65': r.k401kWealthAt65,
          'net_wealth_5yr': r.netWealthAfter5Yrs,
        };

    final compJson = jsonEncode({
      'v': 2,
      'winner': winner == Winner.offerA
          ? 'A'
          : winner == Winner.offerB
              ? 'B'
              : winner == Winner.offerC
                  ? 'C'
                  : 'tie',
      'advantage': widget.result.annualAdvantage,
      'break_even_months': widget.result.breakEvenMonths,
      'offers': [
        offerJson(widget.offerA, a),
        offerJson(widget.offerB, b),
        if (widget.offerC != null && c != null) offerJson(widget.offerC!, c),
      ],
      'categories':
          widget.result.categoryWinners.map((k, v) => MapEntry(k, v.name)),
    });

    final jobTitle = '${widget.offerA.label} vs ${widget.offerB.label}'
        '${widget.offerC != null ? ' vs ${widget.offerC!.label}' : ''}';

    final l1 = <String, dynamic>{
      'winner_salary': winnerOffer.baseSalary,
      'winner_net': winnerResult.netTakeHome,
      'winner_monthly': winnerResult.monthlyTakeHome,
      'winner_total_comp': winnerResult.totalCompensation,
      'annual_advantage': widget.result.annualAdvantage,
    };

    final l2 = <String, dynamic>{
      'inputs': {
        'offerA': offerJson(widget.offerA, a),
        'offerB': offerJson(widget.offerB, b),
        if (widget.offerC != null && c != null)
          'offerC': offerJson(widget.offerC!, c),
      },
      'results': {
        'winner': winner == Winner.offerA
            ? 'A'
            : winner == Winner.offerB
                ? 'B'
                : winner == Winner.offerC
                    ? 'C'
                    : 'tie',
        'advantage': widget.result.annualAdvantage,
        'break_even_months': widget.result.breakEvenMonths,
        'comparison_json': compJson,
      },
    };

    return (hash: _inputHash(), l1: l1, l2: l2);
  }

  Future<void> _onExportCsv(bool isSpanish) async {
    HapticFeedback.mediumImpact();
    if (!freemiumService.hasFullAccess) {
      _showPaywall(context, isSpanish);
      return;
    }
    try {
      final s = isSpanish ? const AppStringsEs() : const AppStringsEn();
      final pctFmt = NumberFormat('0.0#', 'en_US');
      final a = widget.result.resultA;
      final b = widget.result.resultB;
      final c = widget.result.resultC;
      final hasC = widget.offerC != null && c != null;
      final labelA =
          widget.offerA.label.isNotEmpty ? widget.offerA.label : s.offerA;
      final labelB =
          widget.offerB.label.isNotEmpty ? widget.offerB.label : s.offerB;
      final labelC = hasC
          ? (widget.offerC!.label.isNotEmpty ? widget.offerC!.label : s.offerC)
          : null;

      List<String> row3(String field, String vA, String vB, [String? vC]) =>
          hasC ? [field, vA, vB, vC ?? ''] : [field, vA, vB];

      final rows = [
        [s.field, labelA, labelB, if (hasC) labelC!],
        row3(
          s.company,
          widget.offerA.company,
          widget.offerB.company,
          hasC ? widget.offerC!.company : null,
        ),
        row3(
          s.city,
          widget.offerA.city,
          widget.offerB.city,
          hasC ? widget.offerC!.city : null,
        ),
        row3(
          s.stateLabel,
          widget.offerA.stateCode,
          widget.offerB.stateCode,
          hasC ? widget.offerC!.stateCode : null,
        ),
        row3(
          s.grossSalary,
          AmountFormatter.ui(a.grossSalary, 'USD'),
          AmountFormatter.ui(b.grossSalary, 'USD'),
          hasC ? AmountFormatter.ui(c!.grossSalary, 'USD') : null,
        ),
        row3(
          s.netAnnualTakeHome,
          AmountFormatter.ui(a.netTakeHome, 'USD'),
          AmountFormatter.ui(b.netTakeHome, 'USD'),
          hasC ? AmountFormatter.ui(c!.netTakeHome, 'USD') : null,
        ),
        row3(
          s.netMonthly,
          AmountFormatter.ui(a.monthlyTakeHome, 'USD'),
          AmountFormatter.ui(b.monthlyTakeHome, 'USD'),
          hasC ? AmountFormatter.ui(c!.monthlyTakeHome, 'USD') : null,
        ),
        row3(
          s.effectiveTaxRate,
          '${pctFmt.format(a.effectiveTaxRate)}%',
          '${pctFmt.format(b.effectiveTaxRate)}%',
          hasC ? '${pctFmt.format(c!.effectiveTaxRate)}%' : null,
        ),
        row3(
          s.federalTax,
          AmountFormatter.ui(a.federalTax, 'USD'),
          AmountFormatter.ui(b.federalTax, 'USD'),
          hasC ? AmountFormatter.ui(c!.federalTax, 'USD') : null,
        ),
        row3(
          s.stateTax,
          AmountFormatter.ui(a.stateTax, 'USD'),
          AmountFormatter.ui(b.stateTax, 'USD'),
          hasC ? AmountFormatter.ui(c!.stateTax, 'USD') : null,
        ),
        row3(
          'FICA',
          AmountFormatter.ui(a.ficaTax, 'USD'),
          AmountFormatter.ui(b.ficaTax, 'USD'),
          hasC ? AmountFormatter.ui(c!.ficaTax, 'USD') : null,
        ),
        row3(
          s.annualBonusAfterTax,
          AmountFormatter.ui(a.bonusAfterTax, 'USD'),
          AmountFormatter.ui(b.bonusAfterTax, 'USD'),
          hasC ? AmountFormatter.ui(c!.bonusAfterTax, 'USD') : null,
        ),
        if (a.signingBonusAfterTax > 0 ||
            b.signingBonusAfterTax > 0 ||
            (c?.signingBonusAfterTax ?? 0) > 0)
          row3(
            s.signingBonusAfterTax,
            AmountFormatter.ui(a.signingBonusAfterTax, 'USD'),
            AmountFormatter.ui(b.signingBonusAfterTax, 'USD'),
            hasC ? AmountFormatter.ui(c!.signingBonusAfterTax, 'USD') : null,
          ),
        row3(
          s.match401k,
          AmountFormatter.ui(a.k401kMatch, 'USD'),
          AmountFormatter.ui(b.k401kMatch, 'USD'),
          hasC ? AmountFormatter.ui(c!.k401kMatch, 'USD') : null,
        ),
        row3(
          s.healthBenefits,
          AmountFormatter.ui(a.healthBenefits, 'USD'),
          AmountFormatter.ui(b.healthBenefits, 'USD'),
          hasC ? AmountFormatter.ui(c!.healthBenefits, 'USD') : null,
        ),
        row3(
          s.ptoValue,
          AmountFormatter.ui(a.ptoValue, 'USD'),
          AmountFormatter.ui(b.ptoValue, 'USD'),
          hasC ? AmountFormatter.ui(c!.ptoValue, 'USD') : null,
        ),
        row3(
          s.annualRsu,
          AmountFormatter.ui(a.annualRsuValue, 'USD'),
          AmountFormatter.ui(b.annualRsuValue, 'USD'),
          hasC ? AmountFormatter.ui(c!.annualRsuValue, 'USD') : null,
        ),
        row3(
          s.commuteCost,
          AmountFormatter.ui(a.commuteCost, 'USD'),
          AmountFormatter.ui(b.commuteCost, 'USD'),
          hasC ? AmountFormatter.ui(c!.commuteCost, 'USD') : null,
        ),
        row3(
          s.totalNetCompensation,
          AmountFormatter.ui(a.totalCompensation, 'USD'),
          AmountFormatter.ui(b.totalCompensation, 'USD'),
          hasC ? AmountFormatter.ui(c!.totalCompensation, 'USD') : null,
        ),
      ];

      final csv =
          rows.map((r) => r.map((cell) => '"$cell"').join(',')).join('\n');
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final filename =
          'job_comparison_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';

      await Share.shareXFiles(
        [XFile.fromData(bytes, name: filename, mimeType: 'text/csv')],
        subject: filename,
      );
      AnalyticsService.instance.logResultShared();
    } catch (_) {
      if (mounted) {
        final s = isSpanish ? const AppStringsEs() : const AppStringsEn();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.failedExportCsv),
            behavior: SnackBarBehavior.floating,
            backgroundColor: CalcwiseSemanticColors.errorDark,
          ),
        );
      }
    }
  }

  Future<void> _exportPdf(bool isSpanish) async {
    HapticFeedback.mediumImpact();
    try {
      await _exportPdfImpl(isSpanish);
      if (mounted) {
        final s = isSpanish ? const AppStringsEs() : const AppStringsEn();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.pdfGenerated),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        final s = isSpanish ? const AppStringsEs() : const AppStringsEn();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.failedExportPdf),
            behavior: SnackBarBehavior.floating,
            backgroundColor: CalcwiseSemanticColors.errorDark,
          ),
        );
      }
    }
  }

  Future<void> _exportPdfImpl(bool isSpanish) async {
    final s = isSpanish ? const AppStringsEs() : const AppStringsEn();
    final a = widget.result.resultA;
    final b = widget.result.resultB;
    final c = widget.result.resultC;
    final hasC = widget.offerC != null && c != null;
    final winner = widget.result.winner;
    final winnerLabel = winner == Winner.offerA
        ? s.offerAWins
        : winner == Winner.offerB
            ? s.offerBWins
            : winner == Winner.offerC
                ? s.offerCWins
                : s.tie;

    final params = _ComparisonPdfParams(
      pdfTitle: s.pdfTitle,
      generated: s.generated,
      dateLabel: DateFormat('MMM d, yyyy', isSpanish ? 'es' : 'en').format(DateTime.now()),
      winnerLabel: winnerLabel,
      isTie: widget.result.isTie,
      advantage: AmountFormatter.ui(widget.result.annualAdvantage, 'USD'),
      advantageText: s.advantage,
      metric: s.metric,
      offerALabel: s.offerALabel,
      offerBLabel: s.offerBLabel,
      offerCLabel: hasC ? s.offerCLabel : null,
      hasC: hasC,
      grossSalary: s.grossSalary,
      netAnnualTakeHome: s.netAnnualTakeHome,
      netMonthly: s.netMonthly,
      effectiveTaxRate: s.effectiveTaxRate,
      annualBonusAfterTax: s.annualBonusAfterTax,
      signingBonusAfterTax: s.signingBonusAfterTax,
      match401k: s.match401k,
      healthBenefits: s.healthBenefits,
      annualRsu: s.annualRsu,
      commuteCost: s.commuteCost,
      totalNetCompensation: s.totalNetCompensation,
      ptoValue: s.ptoValue,
      colAdjustedTakeHome: s.colAdjustedTakeHome,
      total5Years: s.total5Years,
      pdfDisclaimer: s.pdfDisclaimer,
      grossA: a.grossSalary,
      netA: a.netTakeHome,
      monthlyA: a.monthlyTakeHome,
      taxRateA: a.effectiveTaxRate,
      bonusAfterTaxA: a.bonusAfterTax,
      signingAfterTaxA: a.signingBonusAfterTax,
      k401kA: a.k401kMatch,
      healthA: a.healthBenefits,
      rsuA: a.annualRsuValue,
      commuteA: a.commuteCost,
      totalCompA: a.totalCompensation,
      ptoA: a.ptoValue,
      grossB: b.grossSalary,
      netB: b.netTakeHome,
      monthlyB: b.monthlyTakeHome,
      taxRateB: b.effectiveTaxRate,
      bonusAfterTaxB: b.bonusAfterTax,
      signingAfterTaxB: b.signingBonusAfterTax,
      k401kB: b.k401kMatch,
      healthB: b.healthBenefits,
      rsuB: b.annualRsuValue,
      commuteB: b.commuteCost,
      totalCompB: b.totalCompensation,
      ptoB: b.ptoValue,
      grossC: c?.grossSalary,
      netC: c?.netTakeHome,
      monthlyC: c?.monthlyTakeHome,
      taxRateC: c?.effectiveTaxRate,
      bonusAfterTaxC: c?.bonusAfterTax,
      signingAfterTaxC: c?.signingBonusAfterTax,
      k401kC: c?.k401kMatch,
      healthC: c?.healthBenefits,
      rsuC: c?.annualRsuValue,
      commuteC: c?.commuteCost,
      totalCompC: c?.totalCompensation,
      ptoC: c?.ptoValue,
      colAdjA: a.colAdjustedTakeHome,
      colAdjB: b.colAdjustedTakeHome,
      colAdjC: c?.colAdjustedTakeHome,
      fiveYrTotalA: a.fiveYearProjection.isNotEmpty ? a.cumulativeComp5Yr : null,
      fiveYrTotalB: b.fiveYearProjection.isNotEmpty ? b.cumulativeComp5Yr : null,
      fiveYrTotalC: c != null && c.fiveYearProjection.isNotEmpty
          ? c.cumulativeComp5Yr
          : null,
      showSigning: a.signingBonusAfterTax > 0 ||
          b.signingBonusAfterTax > 0 ||
          (c?.signingBonusAfterTax ?? 0) > 0,
      isPremium: freemiumService.hasFullAccess,
    );

    final pdfBytes = await Isolate.run(() => _buildComparisonPdf(params));
    final tmpDir = await getTemporaryDirectory();
    final pdfFile = File(
        '${tmpDir.path}/job_offer_comparison_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
    await pdfFile.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
        [XFile(pdfFile.path, mimeType: 'application/pdf')]);
    AnalyticsService.instance.logPdfExportedEvent();
    AnalyticsService.instance.logResultShared();
  }

  void _showExportSheet(BuildContext context, bool isSpanish, bool isPremium) {
    HapticFeedback.mediumImpact();
    final ct = CalcwiseTheme.of(context);
    final s = isSpanish ? const AppStringsEs() : const AppStringsEn();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            MediaQuery.of(context).padding.bottom + AppSpacing.lg),
        decoration: BoxDecoration(
          color: ct.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: ct.cardBorder,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: AppSpacing.lg),
          Text(s.export,
              style: TextStyle(
                  fontSize: AppTextSize.subtitle,
                  fontWeight: FontWeight.w700,
                  color: ct.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
          // CSV
          _ExportTile(
            icon: Icons.table_chart_outlined,
            label: s.exportCsv,
            subtitle: s.exportCsvSubtitle,
            onTap: () {
              Navigator.pop(context);
              _onExportCsv(isSpanish);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          // PDF
          _ExportTile(
            icon: Icons.picture_as_pdf_rounded,
            label: s.exportPdf,
            subtitle: isPremium ? s.exportPdfSubtitlePremium : s.exportPdfSubtitleLocked,
            isPremium: !isPremium,
            onTap: () {
              Navigator.pop(context);
              if (isPremium)
                _exportPdf(isSpanish);
              else
                _showPaywall(context, isSpanish);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel,
                style: TextStyle(color: ct.textSecondary)),
          ),
        ]),
      ),
    );
  }

  void _showPaywall(BuildContext context, bool isSpanish) {
    PaywallHard.show(context, isSpanish: isSpanishNotifier.value);
  }

  /// Save the current comparison as a pinned scenario via SmartHistory.
  ///
  /// [label] is null for free users (name dialog gated to premium by the
  /// SaveScenarioButton). Free users are capped at
  /// [MonetizationConfig.freePinnedLimit] pinned scenarios — once full a
  /// soft paywall is shown instead of evicting silently.
  Future<void> _saveScenario(String? label) async {
    final isSpanish = isSpanishNotifier.value;
    final isPremium = freemiumService.hasFullAccess;

    if (!isPremium) {
      final pinnedCount =
          await DatabaseHelper.instance.countHistory(isPinned: true);
      if (pinnedCount >= MonetizationConfig.freePinnedLimit) {
        if (!mounted) return;
        final ss = isSpanish ? const AppStringsEs() : const AppStringsEn();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => PaywallSoft(
            featureTitle: ss.unlimitedSavedScenarios,
            featureSubtitle: ss.unlimitedSavedScenariosSubtitle,
            isSpanish: isSpanish,
            onUnlock: () {
              Navigator.pop(context);
              _showPaywall(context, isSpanish);
            },
          ),
        );
        return;
      }
    }

    final snap = _buildSnapshot();
    try {
      await smartHistoryService.saveScenario(
        appKey: _appKey,
        screenId: _screenId,
        inputHash: snap.hash,
        l1: snap.l1,
        l2: snap.l2,
        label: label,
      );

      adService.onSave();
      AnalyticsService.instance.logResultSaved();
      HistoryScreen.refreshNotifier.value++;

      if (!mounted) return;
      setState(() => _saved = true);
      final trigger = await paywallSession.recordAction();
      if (!mounted) return;
      if (trigger == PaywallTrigger.soft) PaywallSoft.show(context, isSpanish: isSpanishNotifier.value);
      if (trigger == PaywallTrigger.hard) PaywallHard.show(context, isSpanish: isSpanishNotifier.value);
    } catch (_) {
      if (!mounted) return;
      final ss = isSpanish ? const AppStringsEs() : const AppStringsEn();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ss.failedSave),
          behavior: SnackBarBehavior.floating,
          backgroundColor: CalcwiseSemanticColors.errorDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isSpanishNotifier,
      builder: (_, isSpanish, __) => ValueListenableBuilder<bool>(
        valueListenable: freemiumService.hasFullAccessNotifier,
        builder: (_, isPremium, __) => Scaffold(
          appBar: AppBar(
            title: Text(
              '${widget.offerA.label} vs ${widget.offerB.label}${widget.offerC != null ? ' vs ${widget.offerC!.label}' : ''}',
              overflow: TextOverflow.ellipsis,
            ),
            leading: const BackButton(),
            actions: [
              IconButton(
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: (isSpanish ? const AppStringsEs() : const AppStringsEn()).export,
                onPressed: () =>
                    _showExportSheet(context, isSpanish, isPremium),
              ),
            ],
          ),
          body: Column(children: [
            Expanded(child: _buildBody(context, isSpanish, isPremium)),
            const CalcwiseAdFooter(),
          ]),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isSpanish, bool isPremium) {
    final s = isSpanish ? const AppStringsEs() : const AppStringsEn();
    final a = widget.result.resultA;
    final b = widget.result.resultB;
    final c = widget.result.resultC;
    final has3 = c != null;
    final insights =
        InsightEngine.generate(widget.result, isSpanish: isSpanish);

    // Helper: build a bar — 2-way or 3-way depending on offer C presence
    Widget bar({
      required String label,
      required double va,
      required double vb,
      double? vc,
      Winner? winner,
      String Function(double)? formatter,
    }) {
      if (has3) {
        return ThreeWayBar(
          label: label,
          valueA: va,
          valueB: vb,
          valueC: vc ?? 0,
          winner: winner,
          isSpanish: isSpanish,
          formatter: formatter,
        );
      }
      return ComparisonBar(
        label: label,
        valueA: va,
        valueB: vb,
        winner: winner,
        isSpanish: isSpanish,
        formatter: formatter,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: CalcwisePageEntrance(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Winner banner ──────────────────────────────────────────────
          CalcwiseStaggerItem(
            index: 0,
            child: WinnerBanner(result: widget.result, isSpanish: isSpanish),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Hero KPI card ──────────────────────────────────────────────
          CalcwiseStaggerItem(
            index: 1,
            child: _HeroKpiCard(
                result: widget.result,
                offerC: widget.offerC,
                isSpanish: isSpanish),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Salary benchmark callout ───────────────────────────────────
          Builder(builder: (_) {
            final winner = widget.result.winner;
            final winnerOffer = winner == Winner.offerA
                ? widget.offerA
                : winner == Winner.offerC
                    ? (widget.offerC ?? widget.offerA)
                    : widget.offerB;
            return _BenchmarkCallout(
              salary: winnerOffer.baseSalary,
              stateCode: winnerOffer.stateCode,
              isSpanish: isSpanish,
            );
          }),
          const SizedBox(height: AppSpacing.lg),

          // ── Offer labels header ────────────────────────────────────────
          CalcwiseStaggerItem(
            index: 2,
            child: _OfferHeader(
            labelA: widget.offerA.label.isNotEmpty
                ? widget.offerA.label
                : s.offerA,
            labelB: widget.offerB.label.isNotEmpty
                ? widget.offerB.label
                : s.offerB,
            companyA: widget.offerA.company,
            companyB: widget.offerB.company,
            labelC: has3
                ? (widget.offerC!.label.isNotEmpty
                    ? widget.offerC!.label
                    : s.offerC)
                : null,
            companyC: has3 ? widget.offerC!.company : null,
          ),        // closes _OfferHeader
          ),        // closes CalcwiseStaggerItem index 2
          const SizedBox(height: AppSpacing.lg),

          // ── Core comparison card ───────────────────────────────────────
          SectionCard(
            title: s.afterTaxIncome,
            children: [
              bar(
                label: s.annualTakeHome,
                va: a.netTakeHome,
                vb: b.netTakeHome,
                vc: c?.netTakeHome,
                winner: widget.result.categoryWinners['takeHome'],
              ),
              bar(
                label: s.monthly,
                va: a.monthlyTakeHome,
                vb: b.monthlyTakeHome,
                vc: c?.monthlyTakeHome,
                winner: widget.result.categoryWinners['takeHome'],
              ),
              bar(
                label: s.effectiveTaxRateLabel,
                va: a.effectiveTaxRate,
                vb: b.effectiveTaxRate,
                vc: c?.effectiveTaxRate,
                winner: widget.result.categoryWinners['takeHome'],
                formatter: (v) => '${v.toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Tax breakdown ──────────────────────────────────────────────
          SectionCard(
            title: s.taxBreakdown,
            children: [
              bar(
                label: s.federalTaxLabel,
                va: a.federalTax,
                vb: b.federalTax,
                vc: c?.federalTax,
              ),
              bar(
                label: s.stateTaxLabel,
                va: a.stateTax,
                vb: b.stateTax,
                vc: c?.stateTax,
              ),
              if (a.localTax > 0 || b.localTax > 0 || (c?.localTax ?? 0) > 0)
                bar(
                  label: s.cityLocalTax,
                  va: a.localTax,
                  vb: b.localTax,
                  vc: c?.localTax,
                ),
              bar(
                label: 'FICA (SS + Medicare)',
                va: a.ficaTax,
                vb: b.ficaTax,
                vc: c?.ficaTax,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Benefits & extras ──────────────────────────────────────────
          SectionCard(
            title: s.benefitsAndExtras,
            children: [
              if (a.annualBonus > 0 ||
                  b.annualBonus > 0 ||
                  (c?.annualBonus ?? 0) > 0)
                bar(
                  label: s.annualBonusAfterTaxLabel,
                  va: a.bonusAfterTax,
                  vb: b.bonusAfterTax,
                  vc: c?.bonusAfterTax,
                  winner: widget.result.categoryWinners['bonus'],
                ),
              if (a.signingBonusAfterTax > 0 ||
                  b.signingBonusAfterTax > 0 ||
                  (c?.signingBonusAfterTax ?? 0) > 0)
                bar(
                  label: s.signingBonusAfterTaxLabel,
                  va: a.signingBonusAfterTax,
                  vb: b.signingBonusAfterTax,
                  vc: c?.signingBonusAfterTax,
                ),
              if (a.k401kMatch > 0 ||
                  b.k401kMatch > 0 ||
                  (c?.k401kMatch ?? 0) > 0)
                bar(
                  label: s.k401kEmployerMatch,
                  va: a.k401kMatch,
                  vb: b.k401kMatch,
                  vc: c?.k401kMatch,
                  winner: widget.result.categoryWinners['benefits'],
                ),
              if (a.healthBenefits > 0 ||
                  b.healthBenefits > 0 ||
                  (c?.healthBenefits ?? 0) > 0)
                bar(
                  label: s.healthPlusDental,
                  va: a.healthBenefits,
                  vb: b.healthBenefits,
                  vc: c?.healthBenefits,
                  winner: widget.result.categoryWinners['benefits'],
                ),
              if (a.ptoValue > 0 || b.ptoValue > 0 || (c?.ptoValue ?? 0) > 0)
                bar(
                  label: s.ptoValueLabel,
                  va: a.ptoValue,
                  vb: b.ptoValue,
                  vc: c?.ptoValue,
                  winner: widget.result.categoryWinners['pto'],
                ),
              if (a.annualRsuValue > 0 ||
                  b.annualRsuValue > 0 ||
                  (c?.annualRsuValue ?? 0) > 0)
                bar(
                  label: s.annualRsuStock2,
                  va: a.annualRsuValue,
                  vb: b.annualRsuValue,
                  vc: c?.annualRsuValue,
                  winner: widget.result.categoryWinners['rsu'],
                ),
              if (a.commuteCost > 0 ||
                  b.commuteCost > 0 ||
                  (c?.commuteCost ?? 0) > 0)
                bar(
                  label: s.commuteCosMinus,
                  va: a.commuteCost,
                  vb: b.commuteCost,
                  vc: c?.commuteCost,
                  winner: widget.result.categoryWinners['commute'],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── RSU Vesting Schedule ───────────────────────────────────────
          if (a.annualRsuValue > 0 ||
              b.annualRsuValue > 0 ||
              (c?.annualRsuValue ?? 0) > 0) ...[
            _RsuVestingCard(
              offerA: widget.offerA,
              offerB: widget.offerB,
              offerC: widget.offerC,
              resultA: a,
              resultB: b,
              isSpanish: isSpanish,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Total compensation ─────────────────────────────────────────
          SectionCard(
            title: s.netTotalCompensation,
            children: [
              bar(
                label: s.totalAnnualNet,
                va: a.totalCompensation,
                vb: b.totalCompensation,
                vc: c?.totalCompensation,
                winner: widget.result.categoryWinners['total'],
              ),
              bar(
                label: s.totalMonthlyNet,
                va: a.monthlyTotalComp,
                vb: b.monthlyTotalComp,
                vc: c?.monthlyTotalComp,
                winner: widget.result.categoryWinners['total'],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── CoL-adjusted (Premium) ─────────────────────────────────────
          if (isPremium) ...[
            SectionCard(
              title: s.realPurchasingPower,
              children: [
                bar(
                  label: s.colAdjustedTakeHome,
                  va: a.colAdjustedTakeHome,
                  vb: b.colAdjustedTakeHome,
                  vc: c?.colAdjustedTakeHome,
                  winner: widget.result.categoryWinners['col'],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            PaywallSoft(
              featureTitle: s.realPurchasingPowerByCity,
              featureSubtitle: s.nyc100kNeqDallas,
              isSpanish: isSpanish,
              onUnlock: () => _showPaywall(context, isSpanish),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Premium wealth analysis ────────────────────────────────────
          if (isPremium) ...[
            // 5-year projection
            if (a.fiveYearProjection.isNotEmpty) ...[
              _ProjectionCard(
                resultA: a,
                resultB: b,
                labelA: widget.offerA.label,
                labelB: widget.offerB.label,
                isSpanish: isSpanish,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            // Break-even
            if (widget.result.breakEvenMonths != null) ...[
              _BreakEvenCard(
                result: widget.result,
                offerA: widget.offerA,
                offerB: widget.offerB,
                isSpanish: isSpanish,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            // Wealth building
            _WealthBuildingCard(
              resultA: a,
              resultB: b,
              labelA: widget.offerA.label,
              labelB: widget.offerB.label,
              isSpanish: isSpanish,
            ),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            PaywallSoft(
              featureTitle: s.longTermWealthAnalysis,
              featureSubtitle: s.longTermWealthSubtitle,
              isSpanish: isSpanish,
              onUnlock: () => _showPaywall(context, isSpanish),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Smart insights ─────────────────────────────────────────────
          InsightCard(insights: insights, isSpanish: isSpanish),
          const SizedBox(height: AppSpacing.md),

          // ── Negotiation Tips (only for 2-way) ──────────────────────────
          if (!widget.result.isTie && !has3)
            _NegotiationTipsCard(result: widget.result, isSpanish: isSpanish),
          if (!widget.result.isTie && !has3)
            const SizedBox(height: AppSpacing.md),

          // ── Save scenario ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: _saved
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: Icon(Icons.bookmark_rounded,
                        size: 18, color: AppTheme.primary),
                    label: Text(s.scenarioSaved),
                  )
                : SaveScenarioButton(
                    onSave: _saveScenario, isSpanish: isSpanish),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Share / PDF CTA ────────────────────────────────────────────
          if (isPremium)
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _exportPdf(isSpanish);
              },
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(s.exportPdfReport),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
        ),        // closes Column
      ),          // closes CalcwisePageEntrance
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _HeroKpiCard extends StatelessWidget {
  final ComparisonResult result;
  final JobOffer? offerC;
  final bool isSpanish;

  const _HeroKpiCard(
      {required this.result, this.offerC, required this.isSpanish});

  @override
  Widget build(BuildContext context) {
    final a = result.resultA;
    final b = result.resultB;
    final s = isSpanish ? const AppStringsEs() : const AppStringsEn();

    final String heroLabel;
    final String heroValue;
    final String heroSecondary;
    final String statLabelA;
    final String statLabelB;

    if (result.isTie) {
      heroLabel = s.totalCompensation;
      heroValue = AmountFormatter.ui(a.totalCompensation, 'USD');
      heroSecondary = s.bothOffersEquivalent;
      statLabelA = s.annualNetA;
      statLabelB = s.annualNetB;
    } else {
      final isAWinner = result.winner == Winner.offerA;
      final isCWinner = result.winner == Winner.offerC;
      final winnerResult = result.winnerResult;
      final String winnerLabel;
      if (isCWinner) {
        winnerLabel = s.offerC;
      } else {
        winnerLabel = isAWinner ? s.offerA : s.offerB;
      }
      final bgColor = isCWinner
          ? AppTheme.offerCDeep
          : (isAWinner ? AppTheme.offerADeep : AppTheme.offerBDeep);
      heroLabel = s.winnerAnnualNetLabel(winnerLabel);
      heroValue = AmountFormatter.ui(winnerResult.netTakeHome, 'USD');
      heroSecondary = s.winnerAdvantage(AmountFormatter.ui(result.annualAdvantage, 'USD'));
      statLabelA = s.effectiveRate;
      statLabelB = s.totalComp;

      return Semantics(
        label: s.semanticsWinnerKpi(winnerLabel, AmountFormatter.ui(winnerResult.netTakeHome, 'USD'), AmountFormatter.ui(result.annualAdvantage, 'USD')),
        child: CalcwiseHeroCard(
          label: heroLabel,
          value: heroValue,
          secondary: heroSecondary,
          backgroundColor: bgColor,
          rawValue: winnerResult.netTakeHome,
          valueFormatter: (v) => AmountFormatter.ui(v, 'USD'),
          rawStats: [
            (label: statLabelA, value: winnerResult.effectiveTaxRate, formatter: (v) => '${v.toStringAsFixed(1)}%'),
            (label: statLabelB, value: winnerResult.totalCompensation, formatter: (v) => AmountFormatter.ui(v, 'USD')),
          ],
          stats: [
            (
              label: statLabelA,
              value: '${winnerResult.effectiveTaxRate.toStringAsFixed(1)}%',
            ),
            (
              label: statLabelB,
              value: AmountFormatter.ui(winnerResult.totalCompensation, 'USD'),
            ),
          ],
        ),
      );
    }

    return Semantics(
      label: s.semanticsEquivalent(AmountFormatter.ui(a.totalCompensation, 'USD')),
      child: CalcwiseHeroCard(
        label: heroLabel,
        value: heroValue,
        secondary: heroSecondary,
        backgroundColor: AppTheme.primary,
        rawValue: a.totalCompensation,
        valueFormatter: (v) => AmountFormatter.ui(v, 'USD'),
        rawStats: [
          (label: statLabelA, value: a.netTakeHome, formatter: (v) => AmountFormatter.ui(v, 'USD')),
          (label: statLabelB, value: b.netTakeHome, formatter: (v) => AmountFormatter.ui(v, 'USD')),
        ],
        stats: [
          (
            label: statLabelA,
            value: AmountFormatter.ui(a.netTakeHome, 'USD'),
          ),
          (
            label: statLabelB,
            value: AmountFormatter.ui(b.netTakeHome, 'USD'),
          ),
        ],
      ),
    );
  }
}

class _OfferHeader extends StatelessWidget {
  final String labelA, labelB, companyA, companyB;
  final String? labelC, companyC;
  const _OfferHeader({
    required this.labelA,
    required this.labelB,
    required this.companyA,
    required this.companyB,
    this.labelC,
    this.companyC,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _OfferChip(label: labelA, company: companyA, isA: true)),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: _OfferChip(label: labelB, company: companyB, isA: false)),
      if (labelC != null) ...[
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _OfferChip(
                label: labelC!,
                company: companyC ?? '',
                isA: false,
                isC: true)),
      ],
    ]);
  }
}

class _OfferChip extends StatelessWidget {
  final String label, company;
  final bool isA;
  final bool isC;
  const _OfferChip(
      {required this.label,
      required this.company,
      required this.isA,
      this.isC = false});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Color bgColor;
    final String letter;
    if (isC) {
      color = AppTheme.offerC;
      bgColor = AppTheme.offerCDeep.withValues(alpha: 0.15);
      letter = 'C';
    } else {
      color = AppTheme.offerColor(isA);
      bgColor = AppTheme.offerColorLight(isA);
      letter = isA ? 'A' : 'B';
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.smPlus),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
              child: Text(letter,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: AppTextSize.xs,
                      fontWeight: FontWeight.w800))),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: AppTextSize.md,
                    fontWeight: FontWeight.w700,
                    color: color)),
            if (company.isNotEmpty)
              Text(company,
                  style: TextStyle(
                      fontSize: AppTextSize.xs,
                      color: CalcwiseTheme.of(context).textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        )),
      ]),
    );
  }
}


class _ProjectionCard extends StatelessWidget {
  final dynamic resultA, resultB;
  final String labelA, labelB;
  final bool isSpanish;
  const _ProjectionCard({
    required this.resultA,
    required this.resultB,
    required this.labelA,
    required this.labelB,
    required this.isSpanish,
  });

  @override
  Widget build(BuildContext context) {
    final projA = (resultA.fiveYearProjection as List<double>);
    final projB = (resultB.fiveYearProjection as List<double>);
    final totalA = projA.fold(0.0, (s, v) => s + v);
    final totalB = projB.fold(0.0, (s, v) => s + v);

    final ct = CalcwiseTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: ct.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.mdPlus, AppSpacing.lg, AppSpacing.sm),
            child: Text(
              (isSpanish ? const AppStringsEs() : const AppStringsEn()).projection5Year,
              style: const TextStyle(
                  fontSize: AppTextSize.md, fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: <Widget>[
                ...List.generate(
                    5,
                    (i) {
                      final s = isSpanish ? const AppStringsEs() : const AppStringsEn();
                      return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xxs),
                          child: ComparisonBar(
                            label: s.yearN(i + 1),
                            valueA: i < projA.length ? projA[i] : 0,
                            valueB: i < projB.length ? projB[i] : 0,
                            winner: (i < projA.length && i < projB.length)
                                ? (projA[i] >= projB[i]
                                    ? Winner.offerA
                                    : Winner.offerB)
                                : null,
                            isSpanish: isSpanish,
                          ),
                        );
                    }),
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.xs),
                ComparisonBar(
                  label: (isSpanish ? const AppStringsEs() : const AppStringsEn()).total5Years,
                  valueA: totalA,
                  valueB: totalB,
                  winner: totalA >= totalB ? Winner.offerA : Winner.offerB,
                  isSpanish: isSpanish,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── RSU Vesting Schedule card ─────────────────────────────────────────────────

class _RsuVestingCard extends StatefulWidget {
  final JobOffer offerA;
  final JobOffer offerB;
  final JobOffer? offerC;
  final dynamic resultA;
  final dynamic resultB;
  final bool isSpanish;

  const _RsuVestingCard({
    required this.offerA,
    required this.offerB,
    this.offerC,
    required this.resultA,
    required this.resultB,
    required this.isSpanish,
  });

  @override
  State<_RsuVestingCard> createState() => _RsuVestingCardState();
}

class _RsuVestingCardState extends State<_RsuVestingCard> {
  bool _expanded = false;

  /// Build 4-year cliff+monthly vesting schedule.
  /// Year 1: 25% cliff. Years 2–4: remaining 75% monthly (1/36 per month per year).
  static List<_VestYear> _schedule(double totalGrant) {
    if (totalGrant <= 0) return [];
    final cliff = totalGrant * 0.25;
    final remainder = totalGrant * 0.75;
    final monthlyVest = remainder / 36;
    return [
      _VestYear(year: 1, vested: cliff, cumulative: cliff),
      _VestYear(
          year: 2,
          vested: monthlyVest * 12,
          cumulative: cliff + monthlyVest * 12),
      _VestYear(
          year: 3,
          vested: monthlyVest * 12,
          cumulative: cliff + monthlyVest * 24),
      _VestYear(year: 4, vested: monthlyVest * 12, cumulative: totalGrant),
    ];
  }

  /// Estimate tax on RSU vesting (taxed as ordinary income on top of salary).
  /// Includes marginal FICA on the RSU income (SS + Medicare on the incremental slice).
  static double _rsuTaxRate(double salary, double rsuIncome, String stateCode) {
    if (salary <= 0 && rsuIncome <= 0) return 0;
    final total = salary + rsuIncome;
    final taxTotal =
        OfferEngine.federalTax(total) + OfferEngine.stateTax(total, stateCode);
    final taxSalary = OfferEngine.federalTax(salary) +
        OfferEngine.stateTax(salary, stateCode);
    final ficaOnRsu =
        OfferEngine.ficaTax(salary + rsuIncome) - OfferEngine.ficaTax(salary);
    final taxOnRsu = (taxTotal - taxSalary) + ficaOnRsu;
    return rsuIncome > 0 ? (taxOnRsu / rsuIncome) : 0;
  }

  @override
  Widget build(BuildContext context) {
    final ct = CalcwiseTheme.of(context);
    final isSp = widget.isSpanish;

    final grantA = widget.offerA.annualRsuValue * 4; // total 4-yr grant
    final grantB = widget.offerB.annualRsuValue * 4;
    final grantC = (widget.offerC?.annualRsuValue ?? 0) * 4;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — tappable
          Material(
            color: Colors.transparent,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl)),
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                    AppSpacing.mdPlus, AppSpacing.mdPlus, AppSpacing.mdPlus),
                child: Row(children: [
                  Icon(Icons.trending_up_rounded,
                      color: AppTheme.accent, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      (isSp ? const AppStringsEs() : const AppStringsEn()).rsuVestingSchedule,
                      style: const TextStyle(
                          fontSize: AppTextSize.md,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppTheme.accent,
                    size: 20,
                  ),
                ]),
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: ct.cardBorder),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grant summary row
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    Expanded(
                        child: _GrantChip(
                      label: (isSp ? const AppStringsEs() : const AppStringsEn()).totalGrantA,
                      value: AmountFormatter.ui(grantA, 'USD'),
                      color: AppTheme.offerADeep,
                    )),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: _GrantChip(
                      label: (isSp ? const AppStringsEs() : const AppStringsEn()).totalGrantB,
                      value: AmountFormatter.ui(grantB, 'USD'),
                      color: AppTheme.offerBDeep,
                    )),
                    if (widget.offerC != null && grantC > 0) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                          child: _GrantChip(
                        label: (isSp ? const AppStringsEs() : const AppStringsEn()).totalGrantC,
                        value: AmountFormatter.ui(grantC, 'USD'),
                        color: AppTheme.offerCDeep,
                      )),
                    ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.mdPlus),
                  // Vesting table header
                  _VestHeader(isSp: isSp),
                  const Divider(height: 12),
                  // Year rows for Offer A
                  if (grantA > 0) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        (isSp ? const AppStringsEs() : const AppStringsEn()).offerA,
                        style: TextStyle(
                            fontSize: AppTextSize.xs,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.offerADeep),
                      ),
                    ),
                    ..._schedule(grantA).map((y) {
                      final rate = _rsuTaxRate(widget.offerA.baseSalary,
                          y.vested, widget.offerA.stateCode);
                      final netVested = y.vested * (1 - rate);
                      return _VestRow(
                        year: y.year,
                        vested: y.vested,
                        cumulative: y.cumulative,
                        netVested: netVested,
                        taxRate: rate,
                        total: grantA,
                        color: AppTheme.offerADeep,
                        isSp: isSp,
                      );
                    }),
                  ],
                  // Year rows for Offer B
                  if (grantB > 0) ...[
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        (isSp ? const AppStringsEs() : const AppStringsEn()).offerB,
                        style: TextStyle(
                            fontSize: AppTextSize.xs,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.offerBDeep),
                      ),
                    ),
                    ..._schedule(grantB).map((y) {
                      final rate = _rsuTaxRate(widget.offerB.baseSalary,
                          y.vested, widget.offerB.stateCode);
                      final netVested = y.vested * (1 - rate);
                      return _VestRow(
                        year: y.year,
                        vested: y.vested,
                        cumulative: y.cumulative,
                        netVested: netVested,
                        taxRate: rate,
                        total: grantB,
                        color: AppTheme.offerBDeep,
                        isSp: isSp,
                      );
                    }),
                  ],
                  // Year rows for Offer C
                  if (widget.offerC != null && grantC > 0) ...[
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        (isSp ? const AppStringsEs() : const AppStringsEn()).offerC,
                        style: TextStyle(
                            fontSize: AppTextSize.xs,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.offerCDeep),
                      ),
                    ),
                    ..._schedule(grantC).map((y) {
                      final rate = _rsuTaxRate(widget.offerC!.baseSalary,
                          y.vested, widget.offerC!.stateCode);
                      final netVested = y.vested * (1 - rate);
                      return _VestRow(
                        year: y.year,
                        vested: y.vested,
                        cumulative: y.cumulative,
                        netVested: netVested,
                        taxRate: rate,
                        total: grantC,
                        color: AppTheme.offerCDeep,
                        isSp: isSp,
                      );
                    }),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: AppTheme.accent),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            (isSp ? const AppStringsEs() : const AppStringsEn()).rsuDisclaimer,
                            style: TextStyle(
                                fontSize: AppTextSize.xs,
                                color: ct.textSecondary,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VestYear {
  final int year;
  final double vested;
  final double cumulative;
  const _VestYear(
      {required this.year, required this.vested, required this.cumulative});
}

class _GrantChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _GrantChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.smPlus),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: AppTextSize.xs,
                color: color,
                fontWeight: FontWeight.w500)),
        Text(value,
            style: TextStyle(
                fontSize: AppTextSize.md,
                fontWeight: FontWeight.w800,
                color: color)),
      ]),
    );
  }
}

class _VestHeader extends StatelessWidget {
  final bool isSp;
  const _VestHeader({required this.isSp});

  @override
  Widget build(BuildContext context) {
    final ct = CalcwiseTheme.of(context);
    final s = isSp ? const AppStringsEs() : const AppStringsEn();
    return Row(children: [
      SizedBox(
          width: 48,
          child: Text(s.vestYear,
              style: TextStyle(
                  fontSize: AppTextSize.xs,
                  fontWeight: FontWeight.w700,
                  color: ct.textSecondary))),
      Expanded(
          child: Text(s.grossVest,
              style: TextStyle(
                  fontSize: AppTextSize.xs,
                  fontWeight: FontWeight.w700,
                  color: ct.textSecondary))),
      Expanded(
          child: Text(s.netEst,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: AppTextSize.xs,
                  fontWeight: FontWeight.w700,
                  color: ct.textSecondary))),
      SizedBox(
          width: 52,
          child: Text(s.progress,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: AppTextSize.xs,
                  fontWeight: FontWeight.w700,
                  color: ct.textSecondary))),
    ]);
  }
}

class _VestRow extends StatelessWidget {
  final int year;
  final double vested, cumulative, netVested, taxRate, total;
  final Color color;
  final bool isSp;

  const _VestRow({
    required this.year,
    required this.vested,
    required this.cumulative,
    required this.netVested,
    required this.taxRate,
    required this.total,
    required this.color,
    required this.isSp,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (cumulative / total) * 100 : 0.0;
    final s = isSp ? const AppStringsEs() : const AppStringsEn();
    final yearLabel = year == 1 ? s.yearNCliff(1) : s.yearN(year);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(children: [
        SizedBox(
          width: 48,
          child: Text(yearLabel,
              style: TextStyle(
                  fontSize: AppTextSize.xs,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AmountFormatter.ui(vested, 'USD'),
                style: const TextStyle(
                    fontSize: AppTextSize.sm, fontWeight: FontWeight.w600)),
            Text('${(taxRate * 100).toStringAsFixed(1)}% ${(isSp ? const AppStringsEs() : const AppStringsEn()).taxEst}',
                style: TextStyle(fontSize: AppTextSize.xs, color: CalcwiseTheme.of(context).textSecondary)),
          ]),
        ),
        Expanded(
          child: Text(AmountFormatter.ui(netVested, 'USD'),
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: AppTextSize.sm,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ),
        SizedBox(
          width: 52,
          child: Text('${pct.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: AppTextSize.sm,
                  fontWeight: FontWeight.w600,
                  color: CalcwiseTheme.of(context).textSecondary)),
        ),
      ]),
    );
  }
}

// ── Negotiation Tips card ────────────────────────────────────────────────────

class _NegotiationTipsCard extends StatelessWidget {
  final ComparisonResult result;
  final bool isSpanish;

  const _NegotiationTipsCard({
    required this.result,
    required this.isSpanish,
  });

  @override
  Widget build(BuildContext context) {
    final ct = CalcwiseTheme.of(context);
    final s = isSpanish ? const AppStringsEs() : const AppStringsEn();
    final a = result.resultA;
    final b = result.resultB;
    final isAWinner = result.winner == Winner.offerA;
    final loserNet = isAWinner ? b.netTakeHome : a.netTakeHome;
    final winnerNet = isAWinner ? a.netTakeHome : b.netTakeHome;
    final gap = winnerNet - loserNet;
    final counterTarget = loserNet + gap * 0.5;
    final loserLabel = isAWinner ? s.offerB : s.offerA;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.mdPlus, AppSpacing.lg, AppSpacing.sm),
            child: Row(children: [
              const Icon(Icons.handshake_outlined,
                  size: 18, color: AppTheme.accent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                s.negotiationTips,
                style: const TextStyle(
                    fontSize: AppTextSize.md,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accent),
              ),
            ]),
          ),
          Divider(height: 1, color: ct.cardBorder),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.offerGap,
                      style: TextStyle(
                          fontSize: AppTextSize.sm, color: ct.textSecondary),
                    ),
                    Text(
                      AmountFormatter.ui(gap, 'USD'),
                      style: const TextStyle(
                          fontSize: AppTextSize.md,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    s.counterOffer(loserLabel, AmountFormatter.ui(counterTarget, 'USD')),
                    style: TextStyle(
                        fontSize: AppTextSize.sm,
                        color: ct.textPrimary,
                        height: 1.5),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  s.alsoConsider,
                  style: TextStyle(
                      fontSize: AppTextSize.xs,
                      color: ct.textSecondary,
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Break-even card ───────────────────────────────────────────────────────────

class _BreakEvenCard extends StatelessWidget {
  final ComparisonResult result;
  final JobOffer offerA, offerB;
  final bool isSpanish;
  const _BreakEvenCard({
    required this.result,
    required this.offerA,
    required this.offerB,
    required this.isSpanish,
  });

  @override
  Widget build(BuildContext context) {
    final ct = CalcwiseTheme.of(context);
    final s = isSpanish ? const AppStringsEs() : const AppStringsEn();
    final months = result.breakEvenMonths!;
    final years = months ~/ 12;
    final rem = months % 12;

    final winnerLabel = result.winner == Winner.offerA ? offerA.label : offerB.label;
    final loserLabel = result.winner == Winner.offerA ? offerB.label : offerA.label;

    final String duration;
    if (years == 0) {
      duration = s.monthsDuration(months);
    } else if (rem == 0) {
      duration = s.yearsDuration(years);
    } else {
      duration = s.yearsMonthsDuration(years, rem);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.08),
            AppTheme.offerBDeep.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.swap_vert_rounded, color: AppTheme.primary, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            s.breakEvenAnalysis,
            style: const TextStyle(
                fontSize: AppTextSize.md,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        // Big number
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(duration,
              style: const TextStyle(
                  fontSize: AppTextSize.displayLg,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                  letterSpacing: -1)),
          const SizedBox(width: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              s.overtakes(winnerLabel, loserLabel),
              style: TextStyle(fontSize: AppTextSize.sm, color: ct.textSecondary),
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text(
          s.breakEvenBody(loserLabel, winnerLabel, duration),
          style: TextStyle(
              fontSize: AppTextSize.sm,
              color: ct.textSecondary,
              height: 1.5),
        ),
      ]),
    );
  }
}

// ── Wealth building card ──────────────────────────────────────────────────────

class _WealthBuildingCard extends StatelessWidget {
  final dynamic resultA, resultB;
  final String labelA, labelB;
  final bool isSpanish;
  const _WealthBuildingCard({
    required this.resultA,
    required this.resultB,
    required this.labelA,
    required this.labelB,
    required this.isSpanish,
  });

  @override
  Widget build(BuildContext context) {
    final ct = CalcwiseTheme.of(context);
    final isSp = isSpanish;
    final a = resultA;
    final b = resultB;

    final cum5A = a.cumulativeComp5Yr as double;
    final cum5B = b.cumulativeComp5Yr as double;
    final k401kA = a.k401kWealthAt65 as double;
    final k401kB = b.k401kWealthAt65 as double;
    final wealthA = a.netWealthAfter5Yrs as double;
    final wealthB = b.netWealthAfter5Yrs as double;

    final winA_cum = cum5A >= cum5B;
    final winA_k = k401kA >= k401kB;
    final winA_w = wealthA >= wealthB;

    Widget metricRow(String title, String sub, double vA, double vB, bool aWins) {
      final winColor = aWins ? AppTheme.offerADeep : AppTheme.offerBDeep;
      final winLabel = aWins ? labelA : labelB;
      final diff = (vA - vB).abs();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: AppTextSize.sm, fontWeight: FontWeight.w600)),
                Text(sub,
                    style: TextStyle(
                        fontSize: AppTextSize.xs, color: ct.textSecondary)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 3),
              decoration: BoxDecoration(
                color: winColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
              ),
              child: Text(
                '+${AmountFormatter.ui(diff, 'USD')} $winLabel',
                style: TextStyle(
                    fontSize: AppTextSize.xs,
                    color: winColor,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.xs),
          Row(children: [
            Expanded(
              child: _MiniBar(
                  label: labelA, value: vA, maxVal: vA > vB ? vA : vB, color: AppTheme.offerADeep),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MiniBar(
                  label: labelB, value: vB, maxVal: vA > vB ? vA : vB, color: AppTheme.offerBDeep),
            ),
          ]),
        ]),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: ct.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
          child: Row(children: [
            const Icon(Icons.account_balance_wallet_rounded,
                size: 16, color: AppTheme.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              (isSp ? const AppStringsEs() : const AppStringsEn()).wealthBuilding,
              style: const TextStyle(
                  fontSize: AppTextSize.md, fontWeight: FontWeight.w700),
            ),
          ]),
        ),
        Divider(height: 1, color: ct.cardBorder),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
          child: Column(children: [
            metricRow(
              (isSp ? const AppStringsEs() : const AppStringsEn()).totalEarnings5Years,
              (isSp ? const AppStringsEs() : const AppStringsEn()).cumulativeWithRaises,
              cum5A,
              cum5B,
              winA_cum,
            ),
            Divider(height: 20, color: ct.cardBorder),
            metricRow(
              (isSp ? const AppStringsEs() : const AppStringsEn()).k401kRetirement30yr,
              (isSp ? const AppStringsEs() : const AppStringsEn()).contrib6PctMatch7Pct,
              k401kA,
              k401kB,
              winA_k,
            ),
            Divider(height: 20, color: ct.cardBorder),
            metricRow(
              (isSp ? const AppStringsEs() : const AppStringsEn()).netInvestableWealth5Yr,
              (isSp ? const AppStringsEs() : const AppStringsEn()).savings20Pct6PctReturn,
              wealthA,
              wealthB,
              winA_w,
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
          decoration: BoxDecoration(
            color: ct.surfaceHigh,
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.xl)),
          ),
          child: Text(
            (isSp ? const AppStringsEs() : const AppStringsEn()).wealthDisclaimer,
            style: TextStyle(
                fontSize: AppTextSize.xs,
                color: ct.textSecondary,
                fontStyle: FontStyle.italic),
          ),
        ),
      ]),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxVal;
  final Color color;
  const _MiniBar(
      {required this.label,
      required this.value,
      required this.maxVal,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final ct = CalcwiseTheme.of(context);
    final ratio = maxVal > 0 ? (value / maxVal).clamp(0.0, 1.0) : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(fontSize: AppTextSize.xs, color: ct.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      LayoutBuilder(builder: (_, bc) {
        return Stack(children: [
          Container(
              height: 6,
              width: bc.maxWidth,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3))),
          Container(
              height: 6,
              width: bc.maxWidth * ratio,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
        ]);
      }),
      const SizedBox(height: 2),
      Text(AmountFormatter.ui(value, 'USD'),
          style: TextStyle(
              fontSize: AppTextSize.xs,
              color: color,
              fontWeight: FontWeight.w700)),
    ]);
  }
}

// ── Salary benchmark callout ─────────────────────────────────────────────────

class _BenchmarkCallout extends StatelessWidget {
  final double salary;
  final String stateCode;
  final bool isSpanish;
  const _BenchmarkCallout({
    required this.salary,
    required this.stateCode,
    required this.isSpanish,
  });

  @override
  Widget build(BuildContext context) {
    if (salary <= 0) return const SizedBox.shrink();

    final median = SalaryBenchmarkData.median(stateCode);
    final pctDiff = ((salary - median) / median) * 100;
    final absDiff = pctDiff.abs().round();

    final Color chipColor;
    final IconData icon;
    final String label;

    final s = isSpanish ? const AppStringsEs() : const AppStringsEn();
    final medianK = (median / 1000).round();
    if (pctDiff >= 10) {
      chipColor = AppTheme.successGreen;
      icon = Icons.trending_up_rounded;
      label = s.aboveBenchmark(stateCode, medianK, absDiff);
    } else if (pctDiff <= -10) {
      chipColor = AppTheme.errorRed;
      icon = Icons.trending_down_rounded;
      label = s.belowBenchmark(stateCode, medianK, absDiff);
    } else {
      chipColor = AppTheme.warningOrange;
      icon = Icons.remove_rounded;
      label = s.nearBenchmark(stateCode, medianK, '${pctDiff >= 0 ? '+' : ''}${pctDiff.round()}');
    }

    return Semantics(
      label: label,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.smPlus),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: chipColor.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(Icons.bar_chart_rounded, size: 14, color: chipColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            s.bls2025Prefix,
            style: TextStyle(
                fontSize: AppTextSize.xs,
                color: chipColor.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600),
          ),
          Icon(icon, size: 13, color: chipColor),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTextSize.xs,
                color: chipColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Export sheet tile ────────────────────────────────────────────────────────

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isPremium;
  final VoidCallback onTap;

  const _ExportTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final ct = CalcwiseTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: ct.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: ct.cardBorder),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: AppTextSize.body,
                      fontWeight: FontWeight.w600,
                      color: ct.textPrimary)),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: AppTextSize.sm, color: ct.textSecondary)),
            ],
          )),
          if (isPremium)
            const Icon(Icons.lock_outline,
                size: 14, color: AppTheme.accent)
          else
            Icon(Icons.chevron_right_rounded, color: ct.textSecondary),
        ]),
      ),
    );
  }
}
