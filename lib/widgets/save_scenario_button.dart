import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/freemium/freemium_service.dart';
import '../l10n/strings_en.dart';
import '../l10n/strings_es.dart';

/// A "Save Scenario" button that pins the current comparison result.
///
/// - **Premium users**: shows a name-entry dialog before saving.
/// - **Free users**: saves immediately without a label (3 max pinned slots).
///
/// Bilingual EN/ES via [isSpanish].
class SaveScenarioButton extends StatefulWidget {
  /// Called when the user confirms the save. [label] is null for free users.
  final Future<void> Function(String? label) onSave;
  final bool isSpanish;

  const SaveScenarioButton({
    super.key,
    required this.onSave,
    required this.isSpanish,
  });

  @override
  State<SaveScenarioButton> createState() => _SaveScenarioButtonState();
}

class _SaveScenarioButtonState extends State<SaveScenarioButton> {
  bool _saving = false;

  Future<void> _handleTap() async {
    final isEs = widget.isSpanish;
    String? label;

    if (freemiumService.hasFullAccess) {
      label = await _showNameDialog(isEs);
      if (label == null) return;
      if (label.trim().isEmpty) label = null;
    }

    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    try {
      await widget.onSave(label);
      if (!mounted) return;
      final s = isEs ? const AppStringsEs() : const AppStringsEn();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            label != null && label.isNotEmpty
                ? s.scenarioSavedNamed(label)
                : s.scenarioSavedWithLabel,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _showNameDialog(bool isEs) async {
    final s = isEs ? const AppStringsEs() : const AppStringsEn();
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.saveScenarioTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: s.scenarioNameOptional,
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(s.saveScenario),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.isSpanish ? const AppStringsEs() : const AppStringsEn();
    return OutlinedButton.icon(
      onPressed: _saving ? null : _handleTap,
      icon: _saving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.bookmark_add_outlined, size: 18),
      label: Text(_saving ? s.saving : s.saveScenario),
    );
  }
}
