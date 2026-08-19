import 'package:flutter_test/flutter_test.dart';
import 'package:overblik/models/activity.dart';

void main() {
  group('ActivityRecurrence string mapping', () {
    for (final recurrence in ActivityRecurrence.values) {
      test('${recurrence.name} round-trips through the database string', () {
        final dbValue = activityRecurrenceToDatabase(recurrence);
        expect(activityRecurrenceFromString(dbValue), recurrence);
      });
    }

    test('unknown string falls back to none', () {
      expect(activityRecurrenceFromString('not-a-real-value'), ActivityRecurrence.none);
    });
  });
}
