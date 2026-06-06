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
    final l2 = jsonDecode(row['l2_json'] as String) as Map<String, dynamic>;
    final savedAt = DateTime.fromMillisecondsSinceEpoch(row['saved_at'] as int);

    return DatabaseHelper.instance.insertHistory({
      'job_title': (l2['job_title'] as String?) ?? '',
      'company': (l2['company'] as String?) ?? '',
      'location': (l2['location'] as String?) ?? '',
      'salary': (l2['salary'] as num?)?.toDouble() ?? 0.0,
      'bonus': (l2['bonus'] as num?)?.toDouble() ?? 0.0,
      'benefits': (l2['benefits'] as num?)?.toDouble() ?? 0.0,
      'stock_options': (l2['stock_options'] as num?)?.toDouble() ?? 0.0,
      'relocation': (l2['relocation'] as num?)?.toDouble() ?? 0.0,
      'pto': (l2['pto'] as num?)?.toInt() ?? 0,
      'signing_bonus': (l2['signing_bonus'] as num?)?.toDouble() ?? 0.0,
      'net_salary': (l2['net_salary'] as num?)?.toDouble() ?? 0.0,
      'monthly_net': (l2['monthly_net'] as num?)?.toDouble() ?? 0.0,
      'tax_rate': (l2['tax_rate'] as num?)?.toDouble() ?? 0.0,
      'comparison_json': l2['comparison_json'],
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
