import 'package:flutter_test/flutter_test.dart';
import 'package:jobofferus/core/services/deadline_notification_service.dart';

void main() {
  // ── DeadlineNotificationService.idFor ───────────────────────────────────────
  group('DeadlineNotificationService.idFor', () {
    test(
        'same label, different slots (A vs B) — different notification IDs '
        '(regression: was colliding when derived from label.hashCode only)',
        () {
      final idA = DeadlineNotificationService.idFor('A', 'Offer A', 48);
      final idB = DeadlineNotificationService.idFor('B', 'Offer A', 48);
      expect(idA, isNot(equals(idB)));
    });

    test('same label, different slots (A vs C) — different notification IDs',
        () {
      final idA = DeadlineNotificationService.idFor('A', 'My Offer', 0);
      final idC = DeadlineNotificationService.idFor('C', 'My Offer', 0);
      expect(idA, isNot(equals(idC)));
    });

    test('same slot + label + hoursOffset — deterministic (same ID twice)',
        () {
      final first = DeadlineNotificationService.idFor('A', 'Offer A', 48);
      final second = DeadlineNotificationService.idFor('A', 'Offer A', 48);
      expect(first, equals(second));
    });

    test('same slot + label, different hoursOffset — different IDs', () {
      final id48h = DeadlineNotificationService.idFor('A', 'Offer A', 48);
      final id0h = DeadlineNotificationService.idFor('A', 'Offer A', 0);
      expect(id48h, isNot(equals(id0h)));
    });
  });
}
