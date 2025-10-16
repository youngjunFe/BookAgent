import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

class WebLottie extends StatefulWidget {
  final String assetPath;
  final double width;
  final double height;

  const WebLottie({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
  });

  @override
  State<WebLottie> createState() => _WebLottieState();
}

class _WebLottieState extends State<WebLottie> {
  final String viewType = 'lottie-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _registerView();
  }

  void _registerView() {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final container = html.DivElement()
          ..id = 'lottie-$viewId'
          ..style.width = '${widget.width}px'
          ..style.height = '${widget.height}px';

        // Lottie 라이브러리가 로드되었는지 확인
        if (js.context.hasProperty('lottie')) {
          final lottieObj = js.context['lottie'];
          
          lottieObj.callMethod('loadAnimation', [
            js.JsObject.jsify({
              'container': container,
              'renderer': 'svg',
              'loop': true,
              'autoplay': true,
              'path': widget.assetPath,
            })
          ]);
        } else {
          print('❌ Lottie library not loaded');
          container.innerHtml = '<div style="display:flex;align-items:center;justify-content:center;height:100%;color:#666;">Loading...</div>';
        }

        return container;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: viewType),
    );
  }
}

