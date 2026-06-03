export 'platform/notification_service_stub.dart'
    if (dart.library.io) 'platform/notification_service_mobile.dart'
    if (dart.library.js_interop) 'platform/notification_service_web.dart';
