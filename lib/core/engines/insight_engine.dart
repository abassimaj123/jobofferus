import 'package:calcwise_core/calcwise_core.dart' show Insight, InsightSeverity;
import '../models/comparison_result.dart';
import '../../l10n/strings_en.dart';
import '../../l10n/strings_es.dart';

/// Generates smart insights from a [ComparisonResult].
/// Fully pure — no Flutter imports.
class InsightEngine {
  InsightEngine._();

  static const _kMinCommuteSavings = 2000.0; // flag if >$2k/yr difference
  static const _kMinProjectionAdv = 5000.0; // flag 5-yr projection advantage

  static List<Insight> generate(ComparisonResult r, {bool isSpanish = false}) {
    final insights = <Insight>[];
    final a = r.resultA;
    final b = r.resultB;
    final s = isSpanish ? const AppStringsEs() : const AppStringsEn();

    // ── Tax burden ─────────────────────────────────────────────────────────
    if ((a.effectiveTaxRate - b.effectiveTaxRate).abs() >= 3) {
      final higher = a.effectiveTaxRate > b.effectiveTaxRate ? 'A' : 'B';
      final lower = higher == 'A' ? 'B' : 'A';
      final diff = (a.effectiveTaxRate - b.effectiveTaxRate).abs();
      insights.add(Insight(
        title: s.insightLowerTaxTitle(lower),
        body: s.insightLowerTaxBody(lower, diff.toStringAsFixed(1), higher),
        severity: InsightSeverity.warning,
      ));
    }

    // ── Commute cost ───────────────────────────────────────────────────────
    final commuteDiff = (a.commuteCost - b.commuteCost).abs();
    if (commuteDiff >= _kMinCommuteSavings) {
      final cheaper = a.commuteCost < b.commuteCost ? 'A' : 'B';
      insights.add(Insight(
        title: s.insightCommuteTitle(cheaper),
        body: s.insightCommuteBody(commuteDiff.toStringAsFixed(0)),
        severity: InsightSeverity.warning,
      ));
    }

    // ── Remote vs on-site ──────────────────────────────────────────────────
    if ((a.commuteCost > 0 && b.commuteCost == 0) ||
        (a.commuteCost == 0 && b.commuteCost > 0)) {
      final remote = a.commuteCost == 0 ? 'A' : 'B';
      insights.add(Insight(
        title: s.insightRemoteTitle(remote),
        body: s.insightRemoteBody(),
        severity: InsightSeverity.good,
      ));
    }

    // ── 401k match ─────────────────────────────────────────────────────────
    if ((a.k401kMatch - b.k401kMatch).abs() >= 500) {
      final better = a.k401kMatch > b.k401kMatch ? 'A' : 'B';
      final worse = better == 'A' ? 'B' : 'A';
      final diff = (a.k401kMatch - b.k401kMatch).abs();
      insights.add(Insight(
        title: s.insightBetter401kTitle(better),
        body: s.insightBetter401kBody(better, diff.toStringAsFixed(0), worse),
        severity: InsightSeverity.good,
      ));
    }

    // ── CoL adjustment ─────────────────────────────────────────────────────
    final colDiff = (a.colAdjustedTakeHome - b.colAdjustedTakeHome).abs();
    final rawDiff = (a.netTakeHome - b.netTakeHome).abs();
    if (colDiff > 0 && rawDiff > 0) {
      final rawWinner = a.netTakeHome > b.netTakeHome ? 'A' : 'B';
      final colWinner =
          a.colAdjustedTakeHome > b.colAdjustedTakeHome ? 'A' : 'B';
      if (rawWinner != colWinner) {
        insights.add(Insight(
          title: s.insightColFlipsTitle(),
          body: s.insightColFlipsBody(rawWinner, colWinner),
          severity: InsightSeverity.alert,
        ));
      }
    }

    // ── RSU / equity ───────────────────────────────────────────────────────
    if ((a.annualRsuValue - b.annualRsuValue).abs() >= 5000) {
      final better = a.annualRsuValue > b.annualRsuValue ? 'A' : 'B';
      final diff = (a.annualRsuValue - b.annualRsuValue).abs();
      insights.add(Insight(
        title: s.insightMoreEquityTitle(better),
        body: s.insightMoreEquityBody(diff.toStringAsFixed(0)),
        severity: InsightSeverity.good,
      ));
    }

    // ── 5-year trajectory ──────────────────────────────────────────────────
    if (a.fiveYearProjection.isNotEmpty && b.fiveYearProjection.isNotEmpty) {
      final totalA = a.fiveYearProjection.fold(0.0, (acc, v) => acc + v);
      final totalB = b.fiveYearProjection.fold(0.0, (acc, v) => acc + v);
      final diff5 = (totalA - totalB).abs();
      if (diff5 >= _kMinProjectionAdv) {
        final better = totalA > totalB ? 'A' : 'B';
        insights.add(Insight(
          title: s.insightBetter5yrTitle(better),
          body: s.insightBetter5yrBody((diff5 / 1000).toStringAsFixed(0)),
          severity: InsightSeverity.good,
        ));
      }
    }

    // ── Gross pay vs net reality check ────────────────────────────────────
    if (a.grossSalary > 0 && a.effectiveTaxRate > 35) {
      insights.add(Insight(
        title: s.insightHighTaxTitle('A'),
        body: s.insightHighTaxBody(a.effectiveTaxRate.toStringAsFixed(1)),
        severity: InsightSeverity.alert,
      ));
    }
    if (b.grossSalary > 0 && b.effectiveTaxRate > 35) {
      insights.add(Insight(
        title: s.insightHighTaxTitle('B'),
        body: s.insightHighTaxBody(b.effectiveTaxRate.toStringAsFixed(1)),
        severity: InsightSeverity.alert,
      ));
    }

    // ── PTO value ──────────────────────────────────────────────────────────
    if ((a.ptoValue - b.ptoValue).abs() >= 2000) {
      final better = a.ptoValue > b.ptoValue ? 'A' : 'B';
      final diff = (a.ptoValue - b.ptoValue).abs();
      insights.add(Insight(
        title: s.insightMorePtoTitle(better),
        body: s.insightMorePtoBody(diff.toStringAsFixed(0)),
        severity: InsightSeverity.good,
      ));
    }

    // ── Positive summary if everything close ──────────────────────────────
    if (insights.isEmpty) {
      insights.add(Insight(
        title: s.insightOffersCloseTitle(),
        body: s.insightOffersCloseBody(),
        severity: InsightSeverity.good,
      ));
    }

    return insights;
  }
}
