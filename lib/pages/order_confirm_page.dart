import 'package:flutter/material.dart';
import 'package:ugo_flutter/pages/home_page.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/pages/send_referral.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';

class OrderConfirmPage extends StatefulWidget {

  @override
  _OrderConfirmPageState createState() => new _OrderConfirmPageState();
}

class _OrderConfirmPageState extends State<OrderConfirmPage> {

  bool _loggedIn = false;

  @override
  initState() {
    super.initState();
    _ifLoggedIn();
  }

  _ifLoggedIn() async {
    final username = await PrefsManager.getString(PreferenceNames.USER_FIRST_NAME);
    if (username != null) {
      setState(() => _loggedIn = true);
    }
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        automaticallyImplyLeading: false,
        title: new Image.asset("assets/images/ugo_logo.png"),
      ),
      body: new Container(
        child: new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
//              new Image.asset("assets/images/ugo_logo.png", color: UgoGreen),
              new Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: new Text(
                  "Thank You!",
                  style: new TextStyle(fontSize: 48.0, fontFamily: 'Pacifico', color: UgoGreen),
                  textAlign: TextAlign.center,
                ),
              ),
              _loggedIn ? new Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: new Text(
                  "Get \$5 OFF on your next order for every friend you refer to Ugo!",
                  textAlign: TextAlign.center,
                  style: new TextStyle(fontSize: 18.0),
                ),
              ): new Container(),
              _loggedIn ?  new Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: new FlatButton(
                  onPressed: () {
                    Navigator.pushReplacement(context,
                        new MaterialPageRoute(
                            builder: (BuildContext context) => new SendReferralPage())
                    );
                  },
                  color: UgoGreen,
                  child: new Text("Refer Now", style: BUTTON_STYLE),
                ),
              ): new Container(),
              new Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0,vertical: 15.0),
                child: new Text(
                  "You should receive a confirmation email soon. "
                  "If you have any questions or concerns, please call us.\n\n"
                  "We'll have it to you shortly!",
                  textAlign: TextAlign.center,
                  style: new TextStyle(fontSize: 18.0),
                ),
              ),
              new Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: new FlatButton(
                  onPressed: () {
                    Navigator.pushReplacement(context,
                      new MaterialPageRoute(
                        builder: (BuildContext context) => new HomePage())
                    );
                  },
                  color: UgoGreen,
                  child: new Text("Continue Shopping", style: BUTTON_STYLE),
                ),
              )
            ],
          )
        ),
      ),
    );
  }
}
