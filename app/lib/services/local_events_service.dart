import 'dart:convert';
import 'dart:io';

import '../models/event_models.dart';

class LocalEventsService {
  static Future<List<EventItem>> loadEvents() async {
    final eventsFile = await _findFile('events.json');
    final communityFile = await _findFile('community.json');

    if (eventsFile == null) {
      return [];
    }

    final eventPayload = await _readJsonList(eventsFile);
    final communityPayload = communityFile != null
        ? await _readJsonMap(communityFile)
        : null;

    final clubNames = _extractClubNames(communityPayload);
    final collegeNames = _extractCollegeNames(communityPayload);

    return parseEventsFromPayload(eventPayload, clubNames, collegeNames);
  }

  static List<EventItem> parseEventsFromPayload(
    List<dynamic> payload,
    Map<String, String> clubNames,
    Map<String, String> collegeNames,
  ) {
    return payload.whereType<Map<String, dynamic>>().map((item) {
      final title = (item['title'] ?? item['eventName'] ?? '').toString();
      final venue = (item['venue'] ?? item['location'] ?? '').toString();
      final clubId = (item['club'] ?? '').toString();
      final collegeId = (item['college'] ?? '').toString();
      final registrationLink =
          (item['registration_link'] ?? item['eventLink'] ?? '').toString();
      final rawDate = (item['date'] ?? item['eventDate'] ?? '').toString();
      final rawTime = (item['time'] ?? '').toString();
      final formattedDate = _formatDate(rawDate, rawTime);

      return EventItem(
        id: (item['id'] ?? '').toString(),
        eventName: title,
        location: venue,
        communityName: clubNames[clubId] ??
            collegeNames[collegeId] ??
            _titleCase(clubId.isNotEmpty ? clubId : 'Community'),
        communityLogo: '',
        eventLink: registrationLink,
        eventDate: formattedDate,
      );
    }).where((event) => event.eventName.isNotEmpty).toList();
  }

  static Future<List<dynamic>> _readJsonList(File file) async {
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    return decoded is List ? decoded : <dynamic>[];
  }

  static Future<Map<String, dynamic>> _readJsonMap(File file) async {
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
  }

  static Future<File?> _findFile(String fileName) async {
    var directory = Directory.current;
    while (true) {
      final candidate = File('${directory.path}/$fileName');
      if (await candidate.exists()) {
        return candidate;
      }

      final parent = directory.parent;
      if (parent.path == directory.path) {
        break;
      }
      directory = parent;
    }
    return null;
  }

  static Map<String, String> _extractClubNames(Map<String, dynamic>? payload) {
    if (payload == null) {
      return <String, String>{};
    }

    final clubs = payload['clubs'];
    if (clubs is! List) {
      return <String, String>{};
    }

    final names = <String, String>{};
    for (final entry in clubs) {
      if (entry is! Map<String, dynamic>) continue;
      final id = (entry['id'] ?? '').toString();
      final name = (entry['name'] ?? '').toString();
      if (id.isNotEmpty && name.isNotEmpty) {
        names[id] = name;
      }
    }
    return names;
  }

  static Map<String, String> _extractCollegeNames(Map<String, dynamic>? payload) {
    if (payload == null) {
      return <String, String>{};
    }

    final colleges = payload['colleges'];
    if (colleges is! List) {
      return <String, String>{};
    }

    final names = <String, String>{};
    for (final entry in colleges) {
      if (entry is! Map<String, dynamic>) continue;
      final id = (entry['id'] ?? '').toString();
      final name = (entry['name'] ?? '').toString();
      if (id.isNotEmpty && name.isNotEmpty) {
        names[id] = name;
      }
    }
    return names;
  }

  static String _formatDate(String rawDate, String rawTime) {
    if (rawDate.isEmpty) {
      return rawTime.isEmpty ? '' : rawTime;
    }

    try {
      final date = DateTime.parse(rawDate);
      final timeLabel = rawTime.isEmpty ? '' : ' • $rawTime';
      return '${_month(date.month)} ${date.day}, ${date.year}$timeLabel';
    } catch (_) {
      return rawDate;
    }
  }

  static String _month(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[month - 1];
  }

  static String _titleCase(String text) {
    if (text.isEmpty) return '';
    return text.split('_').map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }
}
