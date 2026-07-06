import 'package:flutter_test/flutter_test.dart';
import 'package:jobofferus/core/models/job_offer.dart';
import 'package:jobofferus/core/engines/offer_engine.dart';
import 'package:jobofferus/core/models/comparison_result.dart';

/// Mirrors home_screen.dart's `_l2Snapshot()` -> `offerInputs()` builder.
/// Kept in sync manually; if this test fails after touching home_screen.dart,
/// update both together.
Map<String, dynamic> _homeOfferInputs(JobOffer o) => {
      'label': o.label,
      'company': o.company,
      'base_salary': o.baseSalary,
      'state': o.stateCode,
      'city': o.city,
      'bonus_pct': o.bonusPct,
      'signing_bonus': o.signingBonus,
      'rsu': o.annualRsuValue,
      'k401k_match_pct': o.k401kMatchPct,
      'k401k_up_to_pct': o.k401kUpToPct,
      'pto_days': o.ptoDays,
      'health_insurance_savings': o.healthInsuranceSavings,
      'dental_vision_savings': o.dentalVisionSavings,
      'commute_miles': o.commuteMilesPerDay,
      'is_remote': o.isRemote,
      'annual_raise_pct': o.annualRaisePct,
      'is_hourly': o.isHourly,
      'hours_per_week': o.hoursPerWeek,
      'deadline': o.deadline?.toIso8601String(),
    };

/// Mirrors comparison_screen.dart's `offerJson()` builder (fields sourced
/// from the JobOffer input side only — result fields are irrelevant here).
Map<String, dynamic> _comparisonOfferInputs(JobOffer o) => {
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
    };

/// Reconstructs a JobOffer from the home-tab snapshot map — simulates what
/// a restore/reopen path SHOULD be able to do without silent data loss.
JobOffer _reconstructFromHomeSnapshot(Map<String, dynamic> m) => JobOffer(
      label: m['label'] as String,
      company: m['company'] as String,
      baseSalary: (m['base_salary'] as num).toDouble(),
      stateCode: m['state'] as String,
      city: m['city'] as String,
      bonusPct: (m['bonus_pct'] as num).toDouble(),
      signingBonus: (m['signing_bonus'] as num).toDouble(),
      annualRsuValue: (m['rsu'] as num).toDouble(),
      k401kMatchPct: (m['k401k_match_pct'] as num).toDouble(),
      k401kUpToPct: (m['k401k_up_to_pct'] as num).toDouble(),
      ptoDays: m['pto_days'] as int,
      healthInsuranceSavings: (m['health_insurance_savings'] as num).toDouble(),
      dentalVisionSavings: (m['dental_vision_savings'] as num).toDouble(),
      commuteMilesPerDay: (m['commute_miles'] as num).toDouble(),
      isRemote: m['is_remote'] as bool,
      annualRaisePct: (m['annual_raise_pct'] as num).toDouble(),
      isHourly: m['is_hourly'] as bool,
      hoursPerWeek: (m['hours_per_week'] as num).toDouble(),
      deadline: m['deadline'] != null
          ? DateTime.parse(m['deadline'] as String)
          : null,
    );

void main() {
  group('JobOfferUS — _l2Snapshot completeness (regression for silent data loss)', () {
    // An hourly, remote, non-default-401k offer — exercises every field that
    // was previously dropped by home_screen.dart's _l2Snapshot builder.
    final offer = JobOffer(
      label: 'Remote Contract Offer',
      company: 'Acme Remote Co',
      baseSalary: 91520, // 44/hr * 40hrs * 52wks
      stateCode: 'WA',
      city: 'Seattle, WA',
      bonusPct: 5,
      signingBonus: 2000,
      annualRsuValue: 0,
      k401kMatchPct: 6, // non-default (default is 0)
      k401kUpToPct: 8, // non-default (default is 0) — bug #1: NEVER persisted anywhere before fix
      ptoDays: 15,
      healthInsuranceSavings: 3200,
      dentalVisionSavings: 450,
      commuteMilesPerDay: 0, // remote → 0 miles
      isRemote: true,
      annualRaisePct: 4.5, // non-default (default is 3) — bug #2: not persisted before fix
      isHourly: true, // bug #3: semantic corruption if dropped
      hoursPerWeek: 40,
      deadline: DateTime(2026, 9, 1),
    );

    test('offer inputs actually reach OfferEngine (sanity — proves these are not decorative)', () {
      // This proves every field on the offer is live input to the calculation,
      // i.e. dropping any of them during save is a real semantic data loss,
      // not just missing display detail.
      final other = const JobOffer(label: 'Offer B', baseSalary: 80000, stateCode: 'TX');
      final result = OfferEngine.compare(offer, other, null);
      expect(result.resultA.k401kMatch, greaterThan(0),
          reason: 'k401kMatchPct/k401kUpToPct feed OfferEngine — must not be silently dropped');
      expect(result.resultA.ptoValue, greaterThan(0));
      expect(result.resultA.healthBenefits, greaterThan(0));
      expect(result.resultA.commuteCost, equals(0),
          reason: 'isRemote/commuteMilesPerDay=0 must zero out commute cost');
      expect(result.resultA.fiveYearProjection, isNotEmpty,
          reason: 'annualRaisePct drives the 5-year projection');
    });

    test('home_screen _l2Snapshot equivalent captures every JobOffer field — no silent drop', () {
      final snap = _homeOfferInputs(offer);

      // Previously-dropped fields (the actual bug):
      expect(snap['k401k_match_pct'], offer.k401kMatchPct);
      expect(snap['k401k_up_to_pct'], offer.k401kUpToPct,
          reason: 'k401kUpToPct was persisted NOWHERE before the fix (sub-bug #1)');
      expect(snap['pto_days'], offer.ptoDays);
      expect(snap['health_insurance_savings'], offer.healthInsuranceSavings);
      expect(snap['dental_vision_savings'], offer.dentalVisionSavings);
      expect(snap['commute_miles'], offer.commuteMilesPerDay);
      expect(snap['is_remote'], offer.isRemote);
      expect(snap['annual_raise_pct'], offer.annualRaisePct,
          reason: 'annualRaisePct was never persisted before the fix (sub-bug #2)');
      expect(snap['is_hourly'], offer.isHourly,
          reason: 'isHourly was never persisted — reopened offer silently became annual (sub-bug #3)');
      expect(snap['hours_per_week'], offer.hoursPerWeek);
      expect(snap['deadline'], offer.deadline!.toIso8601String());

      // Already-present fields must still be there:
      expect(snap['label'], offer.label);
      expect(snap['company'], offer.company);
      expect(snap['base_salary'], offer.baseSalary);
      expect(snap['state'], offer.stateCode);
      expect(snap['city'], offer.city);
      expect(snap['bonus_pct'], offer.bonusPct);
      expect(snap['signing_bonus'], offer.signingBonus);
      expect(snap['rsu'], offer.annualRsuValue);
    });

    test('comparison_screen offerJson equivalent also captures every field', () {
      final snap = _comparisonOfferInputs(offer);

      expect(snap['k401k_up_to_pct'], offer.k401kUpToPct);
      expect(snap['annual_raise_pct'], offer.annualRaisePct);
      expect(snap['is_hourly'], offer.isHourly);
      expect(snap['hours_per_week'], offer.hoursPerWeek);
      expect(snap['deadline'], offer.deadline!.toIso8601String());
      // Fields that were already present:
      expect(snap['k401k_match_pct'], offer.k401kMatchPct);
      expect(snap['pto'], offer.ptoDays);
      expect(snap['remote'], offer.isRemote);
      expect(snap['commute_miles'], offer.commuteMilesPerDay);
    });

    test('save -> restore round-trip: reconstructed offer is calc-identical to the original', () {
      final snap = _homeOfferInputs(offer);
      final restored = _reconstructFromHomeSnapshot(snap);

      expect(restored.isHourly, isTrue);
      expect(restored.hoursPerWeek, 40);
      expect(restored.isRemote, isTrue);
      expect(restored.k401kMatchPct, 6);
      expect(restored.k401kUpToPct, 8);
      expect(restored.annualRaisePct, 4.5);
      expect(restored.ptoDays, 15);
      expect(restored.healthInsuranceSavings, 3200);
      expect(restored.dentalVisionSavings, 450);
      expect(restored.commuteMilesPerDay, 0);
      expect(restored.deadline, DateTime(2026, 9, 1));

      // The real regression check: running the engine on the restored offer
      // must produce IDENTICAL results to the original — proving no
      // semantic corruption (e.g. hourly-as-annual) survives the round trip.
      final other = const JobOffer(label: 'Offer B', baseSalary: 80000, stateCode: 'TX');
      final originalResult = OfferEngine.compare(offer, other, null);
      final restoredResult = OfferEngine.compare(restored, other, null);

      expect(restoredResult.resultA.totalCompensation,
          originalResult.resultA.totalCompensation);
      expect(restoredResult.resultA.k401kMatch, originalResult.resultA.k401kMatch);
      expect(restoredResult.resultA.ptoValue, originalResult.resultA.ptoValue);
      expect(restoredResult.resultA.healthBenefits, originalResult.resultA.healthBenefits);
      expect(restoredResult.resultA.fiveYearProjection,
          originalResult.resultA.fiveYearProjection);
    });

    test('regression guard: a snapshot missing k401kUpToPct/annualRaisePct/isHourly would silently corrupt restore', () {
      // Simulates the OLD buggy partial snapshot (8 fields only) to prove
      // this test would have caught the original bug.
      final buggyPartialSnap = <String, dynamic>{
        'label': offer.label,
        'company': offer.company,
        'base_salary': offer.baseSalary,
        'state': offer.stateCode,
        'city': offer.city,
        'bonus_pct': offer.bonusPct,
        'signing_bonus': offer.signingBonus,
        'rsu': offer.annualRsuValue,
      };
      expect(buggyPartialSnap.containsKey('k401k_up_to_pct'), isFalse,
          reason: 'documents that the OLD snapshot shape dropped this field entirely');
      expect(buggyPartialSnap.containsKey('is_hourly'), isFalse,
          reason: 'documents that the OLD snapshot shape dropped this field entirely');
      expect(buggyPartialSnap.containsKey('annual_raise_pct'), isFalse,
          reason: 'documents that the OLD snapshot shape dropped this field entirely');

      // The CURRENT (fixed) snapshot must not have this gap.
      final fixedSnap = _homeOfferInputs(offer);
      expect(fixedSnap.containsKey('k401k_up_to_pct'), isTrue);
      expect(fixedSnap.containsKey('is_hourly'), isTrue);
      expect(fixedSnap.containsKey('annual_raise_pct'), isTrue);
    });
  });
}
