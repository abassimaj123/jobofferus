import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calcwise_core/calcwise_core.dart';

class _MemoryAdapter implements DatabaseAdapter {
  final List<Map<String, dynamic>> _rows = [];
  int _nextId = 1;
  int get rowCount => _rows.length;

  @override
  Future<int> insertRow(Map<String, dynamic> row) async {
    final id = _nextId++;
    _rows.add({...row, 'id': id});
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> getRows({
    required String appKey,
    String? screenId,
    bool? isPinned,
    int? limit,
  }) async {
    var result = _rows.where((r) {
      if (r['app_key'] != appKey) return false;
      if (screenId != null && r['screen_id'] != screenId) return false;
      if (isPinned != null) return ((r['is_pinned'] as int) == 1) == isPinned;
      return true;
    }).toList();
    result.sort((a, b) {
      final aPin = a['is_pinned'] as int;
      final bPin = b['is_pinned'] as int;
      if (aPin != bPin) return bPin.compareTo(aPin);
      return (b['saved_at'] as int).compareTo(a['saved_at'] as int);
    });
    if (limit != null && result.length > limit) result = result.sublist(0, limit);
    return result;
  }

  @override
  Future<Map<String, dynamic>?> getRowByHash({required String appKey, required String screenId, required String resultHash}) async {
    try { return _rows.firstWhere((r) => r['app_key'] == appKey && r['screen_id'] == screenId && r['result_hash'] == resultHash); }
    catch (_) { return null; }
  }

  @override
  Future<int> updateRow(int id, Map<String, dynamic> values) async {
    final idx = _rows.indexWhere((r) => r['id'] == id);
    if (idx < 0) return 0;
    _rows[idx] = {..._rows[idx], ...values};
    return 1;
  }

  @override
  Future<int> deleteRow(int id) async {
    final before = _rows.length;
    _rows.removeWhere((r) => r['id'] == id);
    return before - _rows.length;
  }

  @override
  Future<int> countRows({required String appKey, bool? isPinned}) async =>
      _rows.where((r) {
        if (r['app_key'] != appKey) return false;
        if (isPinned != null) return ((r['is_pinned'] as int) == 1) == isPinned;
        return true;
      }).length;

  @override
  Future<List<Map<String, dynamic>>> getOldestAutoSaves({required String appKey, required int limit}) async {
    final rows = _rows.where((r) => r['app_key'] == appKey && (r['is_pinned'] as int) == 0).toList()
      ..sort((a, b) => (a['saved_at'] as int).compareTo(b['saved_at'] as int));
    return rows.take(limit).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getOldestPinned({required String appKey, required int limit}) async {
    final rows = _rows.where((r) => r['app_key'] == appKey && (r['is_pinned'] as int) == 1).toList()
      ..sort((a, b) => (a['saved_at'] as int).compareTo(b['saved_at'] as int));
    return rows.take(limit).toList();
  }
}

Future<void> _pump() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  late _MemoryAdapter adapter;
  late CalcwiseFreemium freemium;
  late SmartHistoryService svc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    adapter = _MemoryAdapter();
    freemium = CalcwiseFreemium(appKey: 'jobofferus');
    await freemium.initialize();
    svc = SmartHistoryService(
      db: adapter,
      freemium: freemium,
      overrideSaveDebounce: Duration.zero,
    );
  });

  tearDown(() => svc.dispose());

  group('JobOfferUS — save → history scenarios', () {
    test('scenario: compare two job offers → entry appears in history', () async {
      // GIVEN: two job offers (mirrors _l1Snapshot / _l2Snapshot in home_screen.dart)
      // appKey='jobofferus', screenId='home' (from static const _appKey/_screenId)
      const offerASalary = 95000.0;
      const offerBSalary = 88000.0;
      const offerATotal = 125000.0;   // base + bonus + equity
      const offerBTotal = 118000.0;

      final inputHash = ResultHasher.hashMixed({
        'offer_a': ResultHasher.roundTo(offerASalary, 1000),
        'offer_b': ResultHasher.roundTo(offerBSalary, 1000),
      });

      // WHEN: auto-save triggered (mirrors home_screen._compare)
      var savedCalled = false;
      svc.scheduleAutoSave(
        appKey: 'jobofferus',
        screenId: 'home',
        inputHash: inputHash,
        l1: {
          'offer_a_salary': offerASalary,
          'offer_b_salary': offerBSalary,
          'offer_a_total': offerATotal,
          'offer_b_total': offerBTotal,
        },
        l2: {
          'offer_a': {
            'base_salary': offerASalary,
            'bonus': 10000.0,
            'equity': 20000.0,
            'benefits_value': 8000.0,
            'total_compensation': offerATotal,
          },
          'offer_b': {
            'base_salary': offerBSalary,
            'bonus': 15000.0,
            'equity': 10000.0,
            'benefits_value': 5000.0,
            'total_compensation': offerBTotal,
          },
          'winner': 'A',
        },
        onSaved: () => savedCalled = true,
      );
      await _pump();

      // THEN
      final history = await svc.getHistory('jobofferus');
      expect(history, isNotEmpty,
          reason: 'History must contain the job comparison entry');
      expect(history.first.l1['offer_a_salary'], offerASalary);
      expect(savedCalled, isTrue,
          reason: 'onSaved must fire — anti-regression for history refresh race condition');
    });

    test('scenario: two different comparisons → both entries in history', () async {
      for (var i = 0; i < 2; i++) {
        final salA = 80000.0 + i * 15000;
        svc.scheduleAutoSave(
          appKey: 'jobofferus',
          screenId: 'home',
          inputHash: 'hash-job-$i',
          l1: {'offer_a_salary': salA, 'offer_b_salary': 75000.0,
               'offer_a_total': salA + 20000, 'offer_b_total': 95000.0},
          l2: {
            'offer_a': {'base_salary': salA, 'total_compensation': salA + 20000},
            'offer_b': {'base_salary': 75000.0, 'total_compensation': 95000.0},
          },
        );
        await _pump();
      }
      final history = await svc.getHistory('jobofferus');
      expect(history.length, 2);
    });

    test('scenario: same inputs twice → only one history entry', () async {
      const hash = 'same-hash-jobofferus';
      for (var i = 0; i < 3; i++) {
        svc.scheduleAutoSave(
          appKey: 'jobofferus',
          screenId: 'home',
          inputHash: hash,
          l1: {'offer_a_salary': 90000.0, 'offer_b_salary': 85000.0},
          l2: {'offer_a': {'base_salary': 90000.0}, 'offer_b': {'base_salary': 85000.0}},
        );
        await _pump();
      }
      expect(adapter.rowCount, 1,
          reason: 'Identical inputs must not create duplicates');
    });

    test('scenario: pinned offer comparison survives ring buffer eviction', () async {
      await svc.saveScenario(
        appKey: 'jobofferus',
        screenId: 'home',
        inputHash: 'pinned-job-scenario',
        l1: {'offer_a_salary': 140000.0, 'offer_b_salary': 120000.0,
             'offer_a_total': 180000.0, 'offer_b_total': 155000.0},
        l2: {
          'offer_a': {'base_salary': 140000.0, 'total_compensation': 180000.0},
          'offer_b': {'base_salary': 120000.0, 'total_compensation': 155000.0},
          'winner': 'A',
        },
        label: 'FAANG vs startup',
      );
      for (var i = 0; i < MonetizationConfig.freeRingBufferSize + 2; i++) {
        svc.scheduleAutoSave(
          appKey: 'jobofferus',
          screenId: 'home',
          inputHash: 'auto-job-$i',
          l1: {'offer_a_salary': i * 10000.0, 'offer_b_salary': i * 9000.0},
          l2: {'offer_a': {'base_salary': i * 10000.0}, 'offer_b': {'base_salary': i * 9000.0}},
        );
        await _pump();
      }
      final pinned = await svc.getPinned('jobofferus');
      expect(pinned, isNotEmpty,
          reason: 'Pinned offer comparison must survive ring buffer eviction');
      expect(pinned.first.l1['offer_a_salary'], 140000.0);
    });
  });
}
