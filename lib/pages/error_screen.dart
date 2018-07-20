import 'package:flutter/material.dart';
import 'package:ugo_flutter/utilities/constants.dart';

import 'package:url_launcher/url_launcher.dart';

class ErrorScreen extends StatelessWidget {
  final Function() clearError;

  ErrorScreen(this.clearError);

  _launchPhone() async {
    final url = "tel:1-$UGO_PHONE_NUMBER";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("can't launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Image.asset("assets/images/ugo_logo.png"),
      ),
      body: new Container(
        child: new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Padding(
                padding: const EdgeInsets.all(24.0),
                child: new Text("We're sorry.", style: new TextStyle(fontSize: 24.0)),
              ),
              new Text(
                "Something went wrong with your order.\n"
                "Your card may have already been charged,\n"
                "but your order was not submitted successfully.\n"
                "It WILL NOT arrive as expected.\n"
                "Please call us to complete the order.", textAlign: TextAlign.center,),
              new Padding(
                padding: const EdgeInsets.all(24.0),
                child: new FlatButton(
                  onPressed: _launchPhone,
                  color: UgoGreen,
                  child: new Text(
                    "Call Us Now",
                    style: new TextStyle(
                      fontSize: 18.0,
                      color: Colors.white
                    ),
                  ),
                ),
              ),
              new Text(
                "If you are sure there was no problem\n"
                  "and would like to continue with your cart,\n"
                  "you can clear the error below.\n\n"
                  "After a few minutes this error message\n"
                  "will stop displaying when you try to checkout.\n\n"
                  "Thank you for your patience, and we hope you\n"
                  "have a Ugo-riffic day!", textAlign: TextAlign.center,),
              new Padding(
                padding: const EdgeInsets.all(24.0),
                child: new FlatButton(
                  onPressed: () => clearError(),
                  color: Colors.red,
                  child: new Text(
                    "Clear Error",
                    style: new TextStyle(
                      fontSize: 18.0,
                      color: Colors.white
                    ),
                  ),
                ),
              )
            ],
          )
        ),
      ),
    );
  }
}


//_launchURL("tel:1-${site.phone}");