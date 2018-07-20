import 'package:flutter/material.dart';
import 'package:ugo_flutter/pages/account_page.dart';
import 'package:ugo_flutter/pages/login_page.dart';
import 'package:ugo_flutter/pages/webview_page.dart';
//import 'package:ugo_flutter/pages/webview_page.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';
import 'package:ugo_flutter/utilities/widget_utils.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class UgoDrawer extends StatefulWidget {
  final Function() updateCart;

  UgoDrawer({this.updateCart});

  @override
  _UgoDrawerState createState() => new _UgoDrawerState();
}

class _UgoDrawerState extends State<UgoDrawer> {
  String _loginText = "LOGIN";
  bool _loggedIn = false;

  @override
  initState() {
    super.initState();
    _drawerText();
  }

  _drawerText() async {
    final username = await PrefsManager.getString(PreferenceNames.USER_FIRST_NAME);
    if (username != null) {
      setState(() => _loginText = "Hello, $username");
      setState(() => _loggedIn = true);
    }
  }


  @override
  Widget build(BuildContext context) {
    var loginPage = _loggedIn
      ? new AccountPage(updateCart: widget.updateCart,)
      : new LoginPage(updateCart: widget.updateCart,);
    return new Drawer(
      child: new Container(
        color: Colors.grey[900],
        child: new ListView(
          padding: new EdgeInsets.all(0.0),
          children: <Widget>[
            WidgetUtils.addTap(
              new Container(
                padding: new EdgeInsets.only(top: 40.0, bottom: 20.0),
                color: UgoGreen,
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Text(
                      _loginText,
                      style: new TextStyle(
                        color: Colors.white,
                        fontSize: 22.0,
                        fontFamily: 'JosefinSans'
                      ),
                    ),
                  ],
                ),
              ),
              () {
                Navigator.pop(context);
                Navigator.push(context,
                  new MaterialPageRoute(
                    builder: (BuildContext context) => loginPage
                  )
                );
              },
            ),

            new UgoDrawerRow("Our Company", Icons.star, "http://ugodelivery.herokuapp.com/origin"),
            new UgoDrawerRow("FAQ", Icons.info_outline, "http://ugodelivery.herokuapp.com/support"),
            new UgoDrawerRow("Privacy Policy", Icons.security, "http://ugodelivery.herokuapp.com/privacy-policy"),
            new UgoDrawerRow("Terms and Conditions", Icons.assignment, "http://ugodelivery.herokuapp.com/terms"),
            new UgoDrawerRow("Feedback/Contact", Icons.chat, "http://ugodelivery.herokuapp.com/contact"),
          ],
        )
      )

    );
  }
}

class UgoDrawerRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String url;

  UgoDrawerRow(this.title, this.icon, this.url);

  final flutterWebviewPlugin = new FlutterWebviewPlugin();

  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.grey[800];
    final textColor = Colors.grey[400];
    return new Container(
      margin: new EdgeInsets.only(bottom: 2.0),
      padding: new EdgeInsets.all(20.0),
      color: bgColor,
      child: new GestureDetector(
        onTap: () => Navigator.push(
            context, new MaterialPageRoute(
                builder: (BuildContext context) => new WebViewPage(url)
            )
        ),
        child: new Row(
          children: <Widget>[
            new Icon(icon, color: textColor),
            new Padding(padding: new EdgeInsets.only(left: 10.0)),
            new Text(
              title,
              style: new TextStyle(
                color: textColor,
                fontSize: 18.0,
                fontFamily: 'JosefinSans'
              ),
            ),
          ],
        ),
      ),
    );
  }
}


