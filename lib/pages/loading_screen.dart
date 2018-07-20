import 'package:flutter/material.dart';
import 'package:ugo_flutter/utilities/constants.dart';

class LoadingScreen extends StatelessWidget {
  final String loadingText;

  LoadingScreen({this.loadingText});

  @override
  Widget build(BuildContext context) =>
    new Scaffold(
      appBar: new AppBar(),
      body: new LoadingContainer(loadingText: loadingText,));
}

class LoadingContainer extends StatelessWidget {
  final String loadingText;

  LoadingContainer({this.loadingText});

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.white,
      child: new Center(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new Padding(
              padding: const EdgeInsets.only(top: 60.0),
              child: new Image.asset("assets/images/ugo_logo.png", color: UgoGreen,),
            ),
            new Padding(
              padding: const EdgeInsets.only(bottom: 36.0),
              child: new Text(
                loadingText ?? "LOADING . . .",
                style: new TextStyle(
                  fontSize: 24.0,
                  color: Colors.grey[700]
                ),
              ),
            ),
            new CircularProgressIndicator(
              valueColor: new AlwaysStoppedAnimation<Color>(UgoGreen),
              value: null,
            ),
          ],
        ),
      ),
    );
  }
}
