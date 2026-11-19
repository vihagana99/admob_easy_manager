import 'dart:async';
import 'package:flutter/material.dart';

/// Full-screen loading overlay displayed while on-demand ads are being fetched.
/// Features automatic timeout safety to ensure users are never trapped on a locked screen.
class LoadingOverlay {
  Color? _tintColor;
  OverlayEntry? _currentEntry;
  Timer? _safetyTimeoutTimer;

  void setColor(Color color) {
    _tintColor = color;
  }

  OverlayEntry _buildEntry() {
    return OverlayEntry(
      builder: (_) {
        return AbsorbPointer(
          absorbing: true,
          child: ColoredBox(
            color: (_tintColor ?? Colors.black54).withOpacity(0.6),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  /// Displays the overlay. Automatically dismisses after [timeout] (default 6s)
  /// as a failsafe against network hangs or unhandled errors.
  void show(BuildContext context, {Duration timeout = const Duration(seconds: 6)}) {
    if (_currentEntry != null) return;
    if (!context.mounted) return;

    try {
      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      if (overlay == null) return;

      _currentEntry = _buildEntry();
      overlay.insert(_currentEntry!);

      _safetyTimeoutTimer?.cancel();
      _safetyTimeoutTimer = Timer(timeout, () {
        hide();
      });
    } catch (_) {
      _currentEntry = null;
    }
  }

  /// Safely dismisses the loading overlay if currently displayed.
  void hide() {
    _safetyTimeoutTimer?.cancel();
    _safetyTimeoutTimer = null;

    final entry = _currentEntry;
    _currentEntry = null;
    if (entry == null) return;

    try {
      entry.remove();
    } catch (_) {
      // Ignored: already removed or context unmounted
    }
  }

  bool get isShowing => _currentEntry != null;
}
