import 'package:flutter_test/flutter_test.dart';
import 'package:codesapiens/models/event_models.dart';
import 'package:codesapiens/services/local_events_service.dart';

void main() {
  group('LocalEventsService', () {
    test('maps provided JSON payload into EventItem values', () {
      final events = LocalEventsService.parseEventsFromPayload(
        [
          {
            'id': 'psg-tech-code-sprint-2026',
            'title': 'Code Sprint 2026',
            'date': '2026-08-14',
            'time': '09:00',
            'venue': 'CS Block, Seminar Hall 2',
            'registration_link': 'https://forms.gle/example1',
            'club': 'psg-acm-club',
            'college': 'psg-tech',
          }
        ],
        {
          'psg-acm-club': 'ACM Student Chapter',
        },
        {
          'psg-tech': 'PSG College of Technology',
        },
      );

      expect(events, isA<List<EventItem>>());
      expect(events.length, 1);
      expect(events.first.eventName, 'Code Sprint 2026');
      expect(events.first.location, 'CS Block, Seminar Hall 2');
      expect(events.first.communityName, 'ACM Student Chapter');
      expect(events.first.eventLink, 'https://forms.gle/example1');
      expect(events.first.eventDate, contains('Aug 14, 2026'));
    });
  });
}
