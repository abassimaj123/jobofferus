import 'dart:convert';

import 'package:calcwise_core/calcwise_core.dart' show DatabaseAdapter;
import 'database_helper.dart';

/// DatabaseAdapter implementation for JobOfferUS.
///
/// Bridges SmartHistoryService (which speaks HistoryEntry / l1_json / l2_json)
/// to JobOfferUS's flat sqflite `history` table. A "scenario" here is a saved
/// comparison of 2-3 job offers.
///
/// `app_key` / `screen_id` are always 'jobofferus' / 'calculator' for this app.
class JobOfferUSDatabaseAdapter implements DatabaseAdapter {
  static const _appKey = 'jobofferus';
  static const _screenId = 'calculator';

  // ── Insert ──────────────────────────────────────────────────────────────────

  @override
  Future<int> insertRow(Map<String, dynamic> row) async {
    final l1 = jsonDecode(row['l1_json'] as String) as Map<String, dynamic>;
    final l2 = jsonDecode(row['l2_json'] as String) as Map<String, dynamic>;
    final savedAt = DateTime.fromMillisecondsSinceEpoch(row['saved_at'] as int);

    // Both save paths (home_screen.dart's live autosave and
    // comparison_screen.dart's explicit save) produce a nested
    // `{inputs: {offerA, offerB, ...}, results: {winner, ...}}` shape — never
    // the flat job_title/company/salary/... shape this method used to read.
    // Every field silently defaulted to '' / 0.0 as a result. Extract from
    // the actual shape instead, tolerating the two callers' differing key
    // names (e.g. 'base_salary' vs 'base', 'pto_days' vs 'pto').
    final inputs = (l2['inputs'] as Map?)?.cast<String, dynamic>() ?? {};
    final results = (l2['results'] as Map?)?.cast<String, dynamic>() ?? {};
    final offerA = (inputs['offerA'] as Map?)?.cast<String, dynamic>() ?? {};
    final offerB = (inputs['offerB'] as Map?)?.cast<String, dynamic>() ?? {};
    final winnerLetter = results['winner'] as String?;
    final winnerKey = winnerLetter == 'B'
        ? 'offerB'
        : winnerLetter == 'C'
            ? 'offerC'
            : 'offerA';
    final winner =
        (inputs[winnerKey] as Map?)?.cast<String, dynamic>() ?? offerA;

    double numOf(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v is num) return v.toDouble();
      }
      return 0.0;
    }

    final labelA = offerA['label'] as String? ?? 'Offer A';
    final labelB = offerB['label'] as String? ?? 'Offer B';
    final offerC = (inputs['offerC'] as Map?)?.cast<String, dynamic>();
    final labelC = offerC?['label'] as String?;
    final winnerTotalKey = winnerKey == 'offerB'
        ? 'offer_b_total'
        : winnerKey == 'offerC'
            ? 'offer_c_total'
            : 'offer_a_total';

    return DatabaseHelper.instance.insertHistory({
      'job_title': labelC != null && labelC.isNotEmpty
          ? '$labelA vs $labelB vs $labelC'
          : '$labelA vs $labelB',
      'company': (winner['company'] as String?) ?? '',
      'location': (winner['city'] as String?) ?? '',
      'salary': numOf(winner, ['base_salary', 'base']),
      'bonus': numOf(winner, ['bonus_pct']),
      'benefits': numOf(winner, ['health_insurance_savings']) +
          numOf(winner, ['dental_vision_savings']) +
          numOf(winner, ['health_savings']),
      'stock_options': numOf(winner, ['rsu']),
      'relocation': 0.0,
      'pto': numOf(winner, ['pto_days', 'pto']).toInt(),
      'signing_bonus': numOf(winner, ['signing_bonus', 'signing']),
      'net_salary': winner['net'] is num
          ? (winner['net'] as num).toDouble()
          : numOf(l1, ['winner_net', winnerTotalKey]),
      'monthly_net': numOf(winner, ['monthly']),
      'tax_rate': numOf(winner, ['tax_rate']),
      'comparison_json': results['comparison_json'],
      'created_at': savedAt.toIso8601String(),
      'input_hash': row['result_hash'],
      'is_pinned': row['is_pinned'] ?? 0,
      'pin_label': row['pin_label'],
      'pin_order': row['pin_order'] ?? 0,
      'l1_json': row['l1_json'],
    });
  }

  // ── Query ────────────────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getRows({
    required String appKey,
    String? screenId,
    bool? isPinned,
    int? limit,
  }) async {
    final db = await DatabaseHelper.instance.database;
    String? where;
    List<dynamic>? whereArgs;
    if (isPinned != null) {
      where = 'is_pinned = ?';
      whereArgs = [isPinned ? 1 : 0];
    }
    final rows = await db.query(
      'history',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'is_pinned DESC, pin_order DESC, created_at DESC',
      limit: limit,
    );
    return rows.map(_toAdapterRow).toList();
  }

  @override
  Future<Map<String, dynamic>?> getRowByHash({
    required String appKey,
    required String resultHash,
  }) async {
    final row = await DatabaseHelper.instance.getHistoryByHash(resultHash);
    return row == null ? null : _toAdapterRow(row);
  }

  // ── Update / Delete ──────────────────────────────────────────────────────────

  @override
  Future<int> updateRow(int id, Map<String, dynamic> values) async {
    return DatabaseHelper.instance.updateHistoryEntry(id, values);
  }

  @override
  Future<int> deleteRow(int id) async {
    await DatabaseHelper.instance.deleteHistory(id);
    return 1;
  }

  // ── Count / Eviction ─────────────────────────────────────────────────────────

  @override
  Future<int> countRows({required String appKey, bool? isPinned}) async {
    return DatabaseHelper.instance.countHistory(isPinned: isPinned);
  }

  @override
  Future<List<Map<String, dynamic>>> getOldestAutoSaves({
    required String appKey,
    required int limit,
  }) async {
    final rows = await DatabaseHelper.instance.getOldestAutoSaves(limit);
    return rows.map(_toAdapterRow).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getOldestPinned({
    required String appKey,
    required int limit,
  }) async {
    final rows = await DatabaseHelper.instance.getOldestPinnedEntries(limit);
    return rows.map(_toAdapterRow).toList();
  }

  // ── Mapping ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> _toAdapterRow(Map<String, dynamic> row) {
    final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '')
            ?.millisecondsSinceEpoch ??
        0;
    final l1Json = (row['l1_json'] as String?) ?? _buildDefaultL1Json(row);
    final l2Json = _buildL2Json(row);
    return {
      'id': row['id'],
      'app_key': _appKey,
      'screen_id': _screenId,
      'result_hash': (row['input_hash'] as String?) ?? '',
      'l1_json': l1Json,
      'l2_json': l2Json,
      'saved_at': createdAt,
      'is_pinned': (row['is_pinned'] as int?) ?? 0,
      'pin_label': row['pin_label'],
      'pin_order': (row['pin_order'] as int?) ?? 0,
    };
  }

  String _buildDefaultL1Json(Map<String, dynamic> row) {
    return jsonEncode({
      'job_title': row['job_title'],
      'company': row['company'],
      'net_salary': (row['net_salary'] as num?)?.toDouble() ?? 0.0,
      'monthly_net': (row['monthly_net'] as num?)?.toDouble() ?? 0.0,
      'tax_rate': (row['tax_rate'] as num?)?.toDouble() ?? 0.0,
    });
  }

  String _buildL2Json(Map<String, dynamic> row) {
    return jsonEncode({
      'job_title': row['job_title'],
      'company': row['company'],
      'location': row['location'],
      'salary': row['salary'],
      'bonus': row['bonus'],
      'benefits': row['benefits'],
      'stock_options': row['stock_options'],
      'relocation': row['relocation'],
      'pto': row['pto'],
      'signing_bonus': row['signing_bonus'],
      'net_salary': row['net_salary'],
      'monthly_net': row['monthly_net'],
      'tax_rate': row['tax_rate'],
      'comparison_json': row['comparison_json'],
    });
  }
}
