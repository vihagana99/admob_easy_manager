import 'dart:async';
import 'package:flutter/foundation.dart';

typedef ErrorCallback = void Function(Object error);

/// Base contract for handling ad display outcomes (interstitial, appOpen).
/// Enforces single-invocation safety to eliminate duplicate callback bugs.
abstract class RequestHandler {
  bool _isHandled = false;

  void onSuccess();
  void onError(String error);

  /// Safe trigger for success that guarantees single execution.
  void dispatchSuccess() {
    if (_isHandled) return;
    _isHandled = true;
    onSuccess();
  }

  /// Safe trigger for error that guarantees single execution.
  void dispatchError(String error) {
    if (_isHandled) return;
    _isHandled = true;
    onError(error);
  }
}

/// Standard [RequestHandler] implementation with timeout protection.
class RequestHandlerImpl extends RequestHandler {
  final VoidCallback? _success;
  final void Function(String error)? _error;
  Timer? _timeoutTimer;

  RequestHandlerImpl({
    VoidCallback? onSuccess,
    void Function(String error)? onError,
    Duration? timeout,
  })  : _success = onSuccess,
        _error = onError {
    if (timeout != null) {
      _timeoutTimer = Timer(timeout, () {
        dispatchError('timeout');
      });
    }
  }

  @override
  void onSuccess() {
    _timeoutTimer?.cancel();
    _success?.call();
  }

  @override
  void onError(String error) {
    _timeoutTimer?.cancel();
    _error?.call(error);
  }
}

/// Callback bundle for Rewarded and Rewarded Interstitial ad events.
class RewardedCallbacks {
  final VoidCallback? onLoaded;
  final VoidCallback? onShowed;
  final VoidCallback? onRewarded;
  final VoidCallback? onDismissed;
  final ErrorCallback? onError;
  final ErrorCallback? onFailedToShow;

  bool _rewardGranted = false;
  bool _dismissed = false;

  RewardedCallbacks({
    this.onLoaded,
    this.onShowed,
    this.onRewarded,
    this.onDismissed,
    this.onError,
    this.onFailedToShow,
  });

  void dispatchRewarded() {
    if (_rewardGranted) return;
    _rewardGranted = true;
    onRewarded?.call();
  }

  void dispatchDismissed() {
    if (_dismissed) return;
    _dismissed = true;
    onDismissed?.call();
  }

  void dispatchError(Object error) {
    onError?.call(error);
  }

  void dispatchFailedToShow(Object error) {
    onFailedToShow?.call(error);
  }
}

/// Fluent builder for constructing [RewardedCallbacks].
class RewardedHandlerBuilder {
  VoidCallback? _onLoaded;
  VoidCallback? _onShowed;
  VoidCallback? _onRewarded;
  VoidCallback? _onDismissed;
  ErrorCallback? _onError;
  ErrorCallback? _onFailedToShow;

  RewardedHandlerBuilder onLoaded(VoidCallback cb) {
    _onLoaded = cb;
    return this;
  }

  RewardedHandlerBuilder onShowed(VoidCallback cb) {
    _onShowed = cb;
    return this;
  }

  RewardedHandlerBuilder onRewarded(VoidCallback cb) {
    _onRewarded = cb;
    return this;
  }

  RewardedHandlerBuilder onDismissed(VoidCallback cb) {
    _onDismissed = cb;
    return this;
  }

  RewardedHandlerBuilder onError(ErrorCallback cb) {
    _onError = cb;
    return this;
  }

  RewardedHandlerBuilder onFailedToShow(ErrorCallback cb) {
    _onFailedToShow = cb;
    return this;
  }

  RewardedCallbacks build() {
    return RewardedCallbacks(
      onLoaded: _onLoaded,
      onShowed: _onShowed,
      onRewarded: _onRewarded,
      onDismissed: _onDismissed,
      onError: _onError,
      onFailedToShow: _onFailedToShow,
    );
  }
}
