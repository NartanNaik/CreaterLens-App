import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'api_service.dart';

class ShareService {
  ShareService({
    required this.api,
    required this.onUrlReceived,
    required this.onUploadComplete,
  });

  final ApiService api;
  final void Function(String url) onUrlReceived;
  final void Function(String url, ShareResult result) onUploadComplete;

  StreamSubscription<List<SharedMediaFile>>? _intentSubscription;

  void init() {
    // App already open in the background
    _intentSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handle,
      onError: (err) => debugPrint('Share stream error: $err'),
    );

    // App was closed (cold start)
    ReceiveSharingIntent.instance.getInitialMedia().then(_handle);
  }

  void _handle(List<SharedMediaFile> files) {
    if (files.isNotEmpty && files.first.type == SharedMediaType.text) {
      _processUrl(files.first.path);
    }
  }

  Future<void> _processUrl(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;

    onUrlReceived(cleanUrl);
    final result = await api.sendUrlToBackend(cleanUrl);
    onUploadComplete(cleanUrl, result);

    // Clear the intent so it doesn't fire again
    ReceiveSharingIntent.instance.reset();
  }

  void dispose() {
    _intentSubscription?.cancel();
  }
}