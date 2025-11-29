// Lightweight fallback NotificationService used when
// `flutter_local_notifications` is not enabled. This keeps the
// app buildable on web/desktop and provides a simple console
// log for notification events. Replace with a full
// flutter_local_notifications implementation when targeting
// Android/iOS and the plugin is available.

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _initialized = false;

  Future<void> init() async {
    // no-op fallback; in mobile builds you can replace this
    // file with the real plugin-backed implementation.
    _initialized = true;
  }

  Future<void> showOrderReady(String orderId, String title, String body) async {
    await init();
    // For now just log. This avoids depending on native
    // plugins for web/desktop builds and keeps behavior
    // predictable during development.
    // When you re-introduce flutter_local_notifications,
    // restore the original implementation.
    // ignore: avoid_print
    print('Notification for order $orderId: $title - $body');
  }

  Future<void> showNotification(String title, String body) async {
    await init();
    // For now just log. This avoids depending on native
    // plugins for web/desktop builds and keeps behavior
    // predictable during development.
    // When you re-introduce flutter_local_notifications,
    // restore the original implementation.
    // ignore: avoid_print
    print('Notification: $title - $body');
  }
}
