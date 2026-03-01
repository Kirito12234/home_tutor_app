import 'package:flutter_test/flutter_test.dart';
import 'package:home_tutor_app/features/notifications/domain/entities/message_notification.dart';

void main() {
  group('MessageNotification', () {
    test('fromJson maps fields correctly', () {
      final json = {
        'id': 'n1',
        'name': 'Ava',
        'isOnline': true,
        'time': '10:30',
        'message': 'Hello',
        'hasAttachment': true,
      };

      final notification = MessageNotification.fromJson(json);

      expect(notification.id, equals('n1'));
      expect(notification.name, equals('Ava'));
      expect(notification.isOnline, isTrue);
      expect(notification.time, equals('10:30'));
      expect(notification.message, equals('Hello'));
      expect(notification.hasAttachment, isTrue);
    });

    test('toJson returns expected map', () {
      const notification = MessageNotification(
        id: 'n2',
        name: 'Ben',
        isOnline: false,
        time: '09:00',
        message: 'Update',
        hasAttachment: false,
      );

      expect(
        notification.toJson(),
        equals({
          'id': 'n2',
          'name': 'Ben',
          'isOnline': false,
          'time': '09:00',
          'message': 'Update',
          'hasAttachment': false,
        }),
      );
    });

    test('copyWith and equality work', () {
      const base = MessageNotification(
        id: 'n3',
        name: 'Chris',
        isOnline: true,
        time: '08:30',
        message: 'Ping',
        hasAttachment: false,
      );

      final updated = base.copyWith(message: 'Pong', hasAttachment: true);
      expect(updated.message, equals('Pong'));
      expect(updated.hasAttachment, isTrue);

      final clone = base.copyWith();
      expect(clone, equals(base));
    });
  });
}
