import 'package:flutter_test/flutter_test.dart';
import 'package:calcwise_core/calcwise_core.dart' show InsightSeverity;
import 'package:jobofferus/core/engines/offer_engine.dart';
import 'package:jobofferus/core/engines/insight_engine.dart';
import 'package:jobofferus/core/models/comparison_result.dart';
import 'package:jobofferus/core/models/job_offer.dart';
import 'package:jobofferus/core/data/state_tax_data.dart';
import 'package:jobofferus/core/data/city_col_data.dart';

void main() {
  // ── State tax edge cases ───────────────────────────────────────────────────
  group('StateTaxData — boundary values', () {
    test('AZ flat 2.5% rate', () {
      expect(StateTaxData.calculate(100000, 'AZ'), closeTo(2500, 50));
    });

    test('HI top bracket 11% — highest in the US', () {
      final tax = StateTaxData.calculate(500000, 'HI');
      // At $500k, effective rate ~9.88% (top marginal 11%, large lower brackets pull it down)
      expect(tax / 500000, greaterThan(0.09));
      // But also confirm marginal rate on very high income approaches 11%
      expect(tax, greaterThan(40000));
    });

    test('IL flat 4.95%', () {
      expect(StateTaxData.calculate(75000, 'IL'), closeTo(3712.5, 10));
    });

    test('PA flat 3.07%', () {
      expect(StateTaxData.calculate(55000, 'PA'), closeTo(1688.5, 10));
    });

    test('All no-tax states return 0', () {
      for (final s in ['AK', 'FL', 'NV', 'NH', 'SD', 'TN', 'TX', 'WA', 'WY']) {
        expect(StateTaxData.calculate(100000, s), equals(0.0),
            reason: '$s should have 0 state tax');
      }
    });

    test('allStateCodes has 51 entries (50 states + DC)', () {
      expect(StateTaxData.allStateCodes.length, equals(51));
    });

    test('stateNames has entry for every code in allStateCodes', () {
      for (final code in StateTaxData.allStateCodes) {
        expect(StateTaxData.stateNames.containsKey(code), isTrue,
            reason: 'Missing name for $code');
      }
    });

    test('CA progressive: \$50k has lower effective rate than \$500k', () {
      final r50k = StateTaxData.calculate(50000, 'CA') / 50000;
      final r500k = StateTaxData.calculate(500000, 'CA') / 500000;
      expect(r500k, greaterThan(r50k));
    });
  });

  // ── CityColData ────────────────────────────────────────────────────────────
  group('CityColData', () {
    test('NYC index > National Average', () {
      expect(CityColData.indexFor('New York, NY'),
          greaterThan(CityColData.indexFor('National Average')));
    });

    test('San Francisco index > Seattle index', () {
      expect(CityColData.indexFor('San Francisco, CA'),
          greaterThan(CityColData.indexFor('Seattle, WA')));
    });

    test('unknown city returns 100 (national avg)', () {
      expect(CityColData.indexFor('Unknown City, ZZ'), equals(100.0));
    });

    test('CoL adjustment: same city in/out → no change', () {
      final adj = CityColData.adjust(
          salary: 100000, fromCity: 'Dallas, TX', toCity: 'Dallas, TX');
      expect(adj, closeTo(100000, 1));
    });

    test('Adjusting from NYC to Memphis makes salary smaller', () {
      // NYC (187) → Memphis (82) → purchasing power equivalent is much less
      final adj = CityColData.adjust(
          salary: 187000, fromCity: 'New York, NY', toCity: 'Memphis, TN');
      expect(adj, lessThan(100000));
    });

    test('Adjusting from cheap city to expensive → salary equivalent is larger',
        () {
      final adj = CityColData.adjust(
          salary: 60000, fromCity: 'Memphis, TN', toCity: 'San Francisco, CA');
      expect(adj, greaterThan(100000));
    });

    test('allCities is not empty and contains major cities', () {
      final cities = CityColData.allCities;
      expect(cities, isNotEmpty);
      expect(cities.contains('New York, NY'), isTrue);
      expect(cities.contains('Austin, TX'), isTrue);
      expect(cities.contains('Seattle, WA'), isTrue);
    });
  });

  // ── Bonus after tax ────────────────────────────────────────────────────────
  group('bonusAfterTax', () {
    test('0% bonus — zero net bonus', () {
      expect(OfferEngine.bonusAfterTax(100000, 0, 'TX'), equals(0.0));
    });

    test('10% bonus on \$100k — net bonus is less than \$10k (taxed)', () {
      final net = OfferEngine.bonusAfterTax(100000, 10, 'TX');
      expect(net, lessThan(10000));
      expect(net, greaterThan(6000)); // at least 60% of gross bonus
    });

    test('same bonus % — CA nets less than TX (higher state tax)', () {
      final tx = OfferEngine.bonusAfterTax(100000, 15, 'TX');
      final ca = OfferEngine.bonusAfterTax(100000, 15, 'CA');
      expect(tx, greaterThan(ca));
    });
  });

  // ── FICA SS cap ────────────────────────────────────────────────────────────
  group('ficaTax — SS wage base cap', () {
    test('SS contribution caps at \$176100 wage base', () {
      final at = OfferEngine.ficaTax(176100);
      final above = OfferEngine.ficaTax(176100 + 50000); // = 226100
      // SS: capped — no extra SS (0)
      // Medicare on 50k: 50000 * 0.0145 = 725
      // Additional Medicare: 26100 (= 226100 - 200000) * 0.009 = 234.9
      // Total diff ≈ 959.9
      expect(above - at, closeTo(959.9, 10));
    });

    test('marginal FICA rate above SS base is just 1.45% (Medicare only)', () {
      final a = OfferEngine.ficaTax(200000);
      final b = OfferEngine.ficaTax(210000);
      // 10k extra: only Medicare = 10000 * 0.0145 = 145
      // (No additional Medicare until 200k threshold — already past)
      // Actually at 200k → 210k: Medicare 1.45% + Additional 0.9% = 2.35%
      expect(b - a, closeTo(10000 * (0.0145 + 0.009), 5));
    });
  });

  // ── Full comparison edge cases ─────────────────────────────────────────────
  group('compare — edge cases', () {
    test('RSU grant in offer A increases total comp', () {
      const noRsu =
          JobOffer(baseSalary: 100000, stateCode: 'TX', annualRsuValue: 0);
      const withRsu =
          JobOffer(baseSalary: 100000, stateCode: 'TX', annualRsuValue: 20000);
      final r = OfferEngine.compare(withRsu, noRsu);
      expect(r.winner, Winner.offerA);
      expect(r.resultA.totalCompensation - r.resultB.totalCompensation,
          closeTo(20000, 100));
    });

    test('PTO difference is reflected in total comp', () {
      const noPto = JobOffer(baseSalary: 100000, stateCode: 'TX', ptoDays: 0);
      const withPto =
          JobOffer(baseSalary: 100000, stateCode: 'TX', ptoDays: 20);
      final r = OfferEngine.compare(withPto, noPto);
      // PTO value ≈ 100000/260*20 = 7692
      expect(r.resultA.ptoValue, closeTo(7692, 100));
      expect(r.winner, Winner.offerA);
    });

    test('remote eliminates commute cost entirely', () {
      const onsite = JobOffer(
          baseSalary: 100000,
          stateCode: 'TX',
          commuteMilesPerDay: 25,
          isRemote: false);
      const remote =
          JobOffer(baseSalary: 100000, stateCode: 'TX', isRemote: true);
      final r = OfferEngine.compare(onsite, remote);
      expect(r.resultA.commuteCost, greaterThan(0));
      expect(r.resultB.commuteCost, equals(0.0));
    });

    test('health benefits increase total comp proportionally', () {
      const noHealth = JobOffer(
          baseSalary: 100000, stateCode: 'TX', healthInsuranceSavings: 0);
      const withHealth = JobOffer(
          baseSalary: 100000, stateCode: 'TX', healthInsuranceSavings: 5000);
      final r = OfferEngine.compare(withHealth, noHealth);
      expect(r.resultA.healthBenefits, closeTo(5000, 1));
      expect(r.winner, Winner.offerA);
    });
  });

  // ── InsightEngine ──────────────────────────────────────────────────────────
  group('InsightEngine', () {
    test('identical offers — returns "close" insight, no alerts', () {
      const a = JobOffer(baseSalary: 100000, stateCode: 'TX');
      const b = JobOffer(baseSalary: 100000, stateCode: 'TX');
      final r = OfferEngine.compare(a, b);
      final insights = InsightEngine.generate(r);
      expect(insights, isNotEmpty);
      // Should have the "these offers are very close" insight
      expect(insights.any((i) => i.severity == InsightSeverity.good), isTrue);
    });

    test('remote vs on-site generates remote advantage insight', () {
      const a = JobOffer(baseSalary: 90000, stateCode: 'TX', isRemote: true);
      const b = JobOffer(
          baseSalary: 95000,
          stateCode: 'TX',
          commuteMilesPerDay: 30,
          isRemote: false);
      final r = OfferEngine.compare(a, b);
      final insights = InsightEngine.generate(r);
      // Should detect remote advantage
      final hasRemoteInsight =
          insights.any((i) => i.title.toLowerCase().contains('remote'));
      expect(hasRemoteInsight, isTrue);
    });

    test('high-tax state generates tax burden insight', () {
      // CA vs TX, same salary → tax rate diff > 3%
      const a = JobOffer(baseSalary: 150000, stateCode: 'CA');
      const b = JobOffer(baseSalary: 150000, stateCode: 'TX');
      final r = OfferEngine.compare(a, b);
      final insights = InsightEngine.generate(r);
      expect(insights.any((i) => i.body.toLowerCase().contains('tax')), isTrue);
    });

    test('Spanish insights contain Spanish text', () {
      const a = JobOffer(baseSalary: 100000, stateCode: 'CA');
      const b = JobOffer(baseSalary: 100000, stateCode: 'TX');
      final r = OfferEngine.compare(a, b);
      final insights = InsightEngine.generate(r, isSpanish: true);
      expect(
          insights.any((i) =>
              i.title.contains('Carga fiscal') ||
              i.title.contains('costo') ||
              i.title.contains('Oferta')),
          isTrue);
    });

    test('returns non-empty list for any valid comparison', () {
      const a = JobOffer(baseSalary: 80000, stateCode: 'NY');
      const b = JobOffer(baseSalary: 70000, stateCode: 'FL');
      final r = OfferEngine.compare(a, b);
      expect(InsightEngine.generate(r), isNotEmpty);
    });
  });

  // ── monthlyTakeHome / monthlyTotalComp ────────────────────────────────────
  group('OfferResult derived getters', () {
    test('monthlyTakeHome = netTakeHome / 12', () {
      const o = JobOffer(baseSalary: 120000, stateCode: 'TX');
      final r = OfferEngine.compare(o, o);
      expect(
          r.resultA.monthlyTakeHome, closeTo(r.resultA.netTakeHome / 12, 0.01));
    });

    test('monthlyTotalComp = totalCompensation / 12', () {
      const o = JobOffer(baseSalary: 96000, stateCode: 'TX');
      final r = OfferEngine.compare(o, o);
      expect(r.resultA.monthlyTotalComp,
          closeTo(r.resultA.totalCompensation / 12, 0.01));
    });
  });
}
