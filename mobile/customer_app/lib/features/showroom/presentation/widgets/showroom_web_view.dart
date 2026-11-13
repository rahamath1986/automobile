import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../domain/entities/showroom_asset.dart';

class ShowroomWebView extends StatefulWidget {
  const ShowroomWebView({
    super.key,
    required this.asset,
    this.onEvent,
  });

  final ShowroomAsset asset;
  final void Function(String type, Map<String, dynamic> payload)? onEvent;

  @override
  State<ShowroomWebView> createState() => ShowroomWebViewState();
}

class ShowroomWebViewState extends State<ShowroomWebView> {
  late final WebViewController _controller;
  bool _pageReady = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B1020))
      ..addJavaScriptChannel(
        'ShowroomBridge',
        onMessageReceived: (message) {
          try {
            final decoded = jsonDecode(message.message);
            if (decoded is Map) {
              final payload = Map<String, dynamic>.from(decoded);
              final type = payload['type']?.toString() ?? 'unknown';
              if (mounted) widget.onEvent?.call(type, payload);
            }
          } catch (_) {
            // Bridge payloads are best-effort telemetry only.
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _pageReady = true;
            _loadManifest();
          },
          onWebResourceError: (error) {
            if (mounted) {
              widget.onEvent?.call('webview-error', {'message': error.description});
            }
          },
        ),
      )
      ..loadFlutterAsset('assets/viewer/showroom.html');
  }

  @override
  void didUpdateWidget(covariant ShowroomWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.variantId != widget.asset.variantId) {
      _loadManifest();
    }
  }

  Map<String, dynamic> _manifest() {
    final asset = widget.asset;
    Map<String, dynamic> vector(CameraVector3 value) => {'x': value.x, 'y': value.y, 'z': value.z};

    Map<String, dynamic> preset(CameraPreset value) => {
          'position': vector(value.position),
          'target': vector(value.target),
          'fov': value.fov,
          'minPolarAngleDeg': value.minPolarAngleDeg,
          'maxPolarAngleDeg': value.maxPolarAngleDeg,
          'minDistanceMeters': value.minDistanceMeters,
          'maxDistanceMeters': value.maxDistanceMeters,
        };

    return {
      'variantId': asset.variantId,
      'modelName': asset.modelName,
      'variantName': asset.variantName,
      'glbFileUrl': asset.glbFileUrl,
      'hexCode': asset.hexCode,
      'hasDracoCompression': asset.hasDracoCompression,
      'cameraPresets': {
        'heroView': preset(asset.cameraPresets.hero),
        'profileView': preset(asset.cameraPresets.profile),
        'cockpitView': preset(asset.cameraPresets.cockpit),
        'rearView': preset(asset.cameraPresets.rear),
        'topView': preset(asset.cameraPresets.top),
      },
      'hotspots': asset.hotspots
          .map((hotspot) => {
                'id': hotspot.id,
                'title': hotspot.title,
                'description': hotspot.description,
                'category': hotspot.category,
                'specMetric': hotspot.specMetric,
                'position': vector(hotspot.position),
              })
          .toList(),
    };
  }

  Future<void> _loadManifest() async {
    if (!_pageReady) return;
    final encoded = jsonEncode(jsonEncode(_manifest()));
    try {
      await _controller.runJavaScript('window.showroom.load($encoded);');
      await setColor(widget.asset.hexCode);
    } catch (_) {
      // The WebView may have been disposed while the manifest was loading.
    }
  }

  Future<void> setColor(String hexCode) async {
    if (!_pageReady) return;
    try {
      await _controller.runJavaScript('window.showroom.setColor(${jsonEncode(hexCode)});');
    } catch (_) {
      // Ignore JS failures; the fallback gallery remains usable.
    }
  }

  Future<void> setView(String view) async {
    if (!_pageReady) return;
    try {
      await _controller.runJavaScript('window.showroom.setView(${jsonEncode(view)});');
    } catch (_) {
      // Ignore JS failures.
    }
  }

  Future<void> reset() async {
    if (!_pageReady) return;
    try {
      await _controller.runJavaScript('window.showroom.reset();');
    } catch (_) {
      // Ignore JS failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
