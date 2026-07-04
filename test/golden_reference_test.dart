// Golden reference tests — JobOfferUS
// Focus: FICA 3-layer formula + netTakeHome by state + k401k/PTO valuation
// SS wage base $184,500 for 2026 (SSA Notice 2025 wage base projection)
// Sources: SSA wage base 2026, IRS Rev. Proc. 2024-40, state tax references.

import 'package:flutter_test/flutter_test.dart';
import 'package:jobofferus/core/engines/offer_engine.dart';

void main() {
  void approx(double actual, double expected, {double tol = 1.0}) {
    expect(actual, closeTo(expected, tol),
        reason: 'Expected ~$expected, got $actual');
  }

  // ── ficaTax — 2025 constants ──────────────────────────────────────────────

  group('OfferEngine.ficaTax — 2026 constants (SS wage base \$184,500)', () {
    test('JO-G1: \$80k → SS \$4,960 + Medicare \$1,160 = \$6,120', () {
      approx(OfferEngine.ficaTax(80000), 6120, tol: 0.01);
    });

    test('JO-G2: below SS wage base \$184,500 → SS + Medicare only', () {
      approx(OfferEngine.ficaTax(176100), 13471.65, tol: 0.01);
    });

    test('JO-G3: \$250k → SS capped at \$184,500 + Medicare + Additional Medicare = \$15,514.00', () {
      approx(OfferEngine.ficaTax(250000), 15514.00, tol: 0.01);
    });

    test('JO-G4: \$200k exactly → \$14,339.00 (Additional Medicare threshold is exclusive)', () {
      approx(OfferEngine.ficaTax(200000), 14339.00, tol: 0.01);
    });

    test('JO-G5: above SS base → each extra \$1 adds only Medicare + Additional', () {
      final at300k = OfferEngine.ficaTax(300000);
      final at200k = OfferEngine.ficaTax(200000);
      // Extra $100k: $1,450 Medicare + $900 Additional = $2,350
      approx(at300k - at200k, 2350, tol: 0.01);
    });
  });

  // ── netTakeHome by state ──────────────────────────────────────────────────

  group('OfferEngine.netTakeHome — state tax boundary', () {
    test('JO-G6: TX net > CA net at same salary (no TX state income tax)', () {
      // TX has no state income tax; CA top marginal > 9%
      final tx = OfferEngine.netTakeHome(100000, 'TX');
      final ca = OfferEngine.netTakeHome(100000, 'CA');
      expect(tx, greaterThan(ca));
    });

    test('JO-G7: WA net ≈ TX net (WA also no state income tax)', () {
      final tx = OfferEngine.netTakeHome(100000, 'TX');
      final wa = OfferEngine.netTakeHome(100000, 'WA');
      // Both have no state income tax → should be equal or near-equal
      expect((tx - wa).abs(), lessThan(500)); // within $500
    });

    test('JO-G8: net take-home is less than gross (taxes are deducted)', () {
      final net = OfferEngine.netTakeHome(100000, 'TX');
      expect(net, lessThan(100000));
      expect(net, greaterThan(0));
    });

    test('JO-G9: higher salary → higher net (monotonic)', () {
      final net80 = OfferEngine.netTakeHome(80000, 'TX');
      final net120 = OfferEngine.netTakeHome(120000, 'TX');
      expect(net120, greaterThan(net80));
    });
  });

  // ── k401kMatchValue ───────────────────────────────────────────────────────

  group('OfferEngine.k401kMatchValue', () {
    test('JO-G10: \$100k / 100% match / 4% → \$4,000', () {
      approx(OfferEngine.k401kMatchValue(100000, matchPct: 100, upToPct: 4), 4000, tol: 0.01);
    });

    test('JO-G11: \$80k / 50% match / 6% → \$2,400', () {
      approx(OfferEngine.k401kMatchValue(80000, matchPct: 50, upToPct: 6), 2400, tol: 0.01);
    });
  });

  // ── ptoValue ─────────────────────────────────────────────────────────────

  group('OfferEngine.ptoValue', () {
    test('JO-G12: \$100k / 15 PTO days → \$5,769.23', () {
      // 100,000 / 260 workdays × 15 = $5,769.23
      approx(OfferEngine.ptoValue(100000, 15), 5769.23, tol: 0.01);
    });
  });
}
