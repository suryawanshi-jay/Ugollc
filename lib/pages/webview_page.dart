import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class WebViewPage extends StatefulWidget {
  final String url;

  WebViewPage(this.url);

  @override
  _WebViewPageState createState() => new _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
//  @override
//  initState() {
//    super.initState();
//  }

  @override
  Widget build(BuildContext context) {
    return new WebviewScaffold(
      appBar: new AppBar(title: new Image.asset("assets/images/ugo_logo.png")),
      url: widget.url,
    );
  }
}
