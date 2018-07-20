import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:ugo_flutter/utilities/constants.dart';

import 'pages/home_page.dart';

void main() {
  // Enable integration testing with the Flutter Driver extension.
  // See https://flutter.io/testing/ for more info.
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  static FirebaseAnalytics analytics = new FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer = new FirebaseAnalyticsObserver(analytics: analytics);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Ugo',
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
        primaryColor: UgoGreen,
        accentColor: UgoGreen
      ),
      home: new HomePage(),
      navigatorObservers: <NavigatorObserver>[observer],
    );
  }
}
