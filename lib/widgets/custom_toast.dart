
import 'package:flutter/material.dart';

class CustomToast {
  static OverlayEntry? _overlayEntry;

  static void show(
      BuildContext context, {
        required String message,
        bool isSuccess = false,
        Duration duration = const Duration(seconds: 3),
      }) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    final overlay = Overlay.of(context);

    final Color backgroundColor =
    isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    final IconData icon =
    isSuccess ? Icons.check_circle : Icons.error;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
      ),
    );

    _overlayEntry = entry;
    overlay.insert(entry);

    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }

      if (identical(_overlayEntry, entry)) {
        _overlayEntry = null;
      }
    });
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, isSuccess: false);
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, isSuccess: true);
  }
}

class _ToastWidget extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;

  const _ToastWidget({
    required this.message,
    required this.backgroundColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 23),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
