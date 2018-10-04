import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugo_flutter/pages/registration_page.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/constants.dart';

class LoginPage extends StatefulWidget {
  final Function() updateCart;

  LoginPage({this.updateCart});

  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _email = "";
  String _password = "";
  bool _loading = false;
  final _analytics = new FirebaseAnalytics();

  _login(BuildContext context) {
    setState(() => _loading = true);
    ApiManager.request(
      OCResources.LOGIN,
      (json) async {
        final account = json["account"];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final accountData = {
          "firstname": account["firstname"],
          "lastname": account["lastname"],
          "email": account["email"],
          "telephone": account["telephone"],
          "fax":account["fax"],
          "custom_field[account][4]" : account['custom_fields'][1]['value'],
          "custom_field[account][2]" : account['custom_fields'][2]['value'],
          "custom_field[account][3]" : account['custom_fields'][3]['value']
        };

        final List customFields = account["custom_fields"];
        customFields.forEach((field) {
          if (field["name"] == "stripe_id") {
            accountData["stripe_field_id"] = field["custom_field_id"];
            accountData["stripe_id"] = field["value"];
          } else if (field["name"] == "payment_address_id") {
            accountData["addr_field_id"] = field["custom_field_id"];
            accountData["payment_address_id"] = field["value"];
          }
        });

        if (accountData["payment_address_id"] == "") {
          _setupDummyAddress(context, accountData);
        } else {
          _setAccountPrefs(context, accountData);
        }
      },
      params: {
        "email": _email,
        "password": _password,
      },
//      context: context,
      errorHandler: (error) {
        setState(() => _loading = false);
        ApiManager.defaultErrorHandler(error, context: context);
      }
    );
  }

  _setupDummyAddress(BuildContext ctx, Map accountData) {
    ApiManager.request(
      OCResources.ADD_ADDRESS,
      (json) async {
        final addr = json["address"];
        final id = addr["address_id"];
        accountData["payment_address_id"] = id;
        _updateAccountInfo(ctx, accountData);
      },
      params: standinAddress
    );
  }

  _updateAccountInfo(BuildContext ctx, Map accountData) {
    ApiManager.request(
      OCResources.PUT_ACCOUNT,
      (json) {
        //handle prefs setting here;
        _setAccountPrefs(ctx, accountData);
      },
      params: {
        "firstname": accountData["firstname"],
        "lastname": accountData["lastname"],
        "email": accountData["email"],
        "telephone": accountData["telephone"],
        "fax": accountData["fax"],
        "custom_field[account][4]": accountData['custom_field']['account'][4],
        "custom_field[account][2]": accountData['custom_field']['account'][2],
        "custom_field[account][3]": accountData['custom_field']['account'][3],
        "custom_field[${accountData["stripe_field_id"]}]": accountData["stripe_id"].toString(),
        "custom_field[${accountData["addr_field_id"]}]": accountData["payment_address_id"].toString(),
      },
//      context: ctx,
      errorHandler: (error) {
        setState(() => _loading = false);
        ApiManager.defaultErrorHandler(error, context: ctx);
      }
    );
  }

  _setAccountPrefs(BuildContext ctx, Map accountData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(PreferenceNames.USER_FIRST_NAME, accountData["firstname"]);
    prefs.setString(PreferenceNames.USER_LAST_NAME, accountData["lastname"]);
    prefs.setString(PreferenceNames.USER_EMAIL, accountData["email"]);
    prefs.setString(PreferenceNames.USER_TELEPHONE, accountData["telephone"]);
    prefs.setString(PreferenceNames.USER_FAX, accountData["fax"]);
    prefs.setString(PreferenceNames.USER_DATE_OF_BIRTH, accountData["custom_field[account][4]"]);
    prefs.setString(PreferenceNames.USER_GENDER, accountData["custom_field[account][2]"]);
    prefs.setString(PreferenceNames.USER_PROFILE, accountData["custom_field[account][3]"]);
    prefs.setString(PreferenceNames.USER_STRIPE_ID, accountData["stripe_id"]);
//    prefs.setString(PreferenceNames.USER_PAYMENT_ADDR_ID, accountData["payment_address_id"].toString());
    setState(() => _loading = false);

    await _analytics.logLogin();

    if (widget.updateCart != null) {
      widget.updateCart();
    }

    Navigator.pop(context);
  }

  _forgotPassword(BuildContext context) {
    ApiManager.request(
      OCResources.POST_FORGOTTEN,
      (json) async {
        await _analytics.logEvent(name: "password_reset_request");

        Scaffold.of(context).showSnackBar(
          new SnackBar(
            content: new Text("Password reset! Check your email for instructions.", style: new TextStyle(fontSize: 18.0),),
            backgroundColor: UgoGreen,
          )
        );
      },
      params: {
        "email": _email
      },
      context: context
    );
  }

  List<Widget> _loginForm() {
    return [
      new TextField(
        decoration: const InputDecoration(
          labelText: 'Email'
        ),
        onChanged: (value) {
          setState(() => _email = value);
        },
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
      ),
      new TextField(
        decoration: const InputDecoration(
          labelText: 'Password'
        ),
        onChanged: (value) {
          setState(() => _password = value);
        },
        obscureText: true,
        autocorrect: false,
      ),
    ];
  }

  bool _emailValid() =>
    _email.toLowerCase().replaceAll(EMAIL_REGEXP, "").length == 0
      && _email.length > 4;

  bool _formValid() =>
      _emailValid()
      && _password.length > 0;

  @override
  Widget build(BuildContext context) {
    final loginText = _loading ? "Logging In . . ." : "Login";
    var list = [];
    list.addAll(_loginForm());
    list.add(new Padding(padding: new EdgeInsets.only(top: 20.0),));
    list.add(new Builder(
      builder: (BuildContext context) {
        return new Row(
          children: <Widget>[
            new Expanded(
              child: new RaisedButton(
                color: UgoGreen,
                onPressed: (_formValid() && !_loading)
                  ? () => _login(context)
                  : null,
                child: new Text(
                  loginText,
                  style: new TextStyle(
                    fontSize: 18.0,
                    color: Colors.white
                  ),
                )
              ),
            ),
          ],
        );
      },
    ));
    list.add(new Padding(padding: new EdgeInsets.only(top: 10.0),));
    list.add(new Row(
      children: <Widget>[
        new Expanded(
          child: new FlatButton(
            onPressed: () => Navigator.push(
              context, new MaterialPageRoute(
              builder: (BuildContext context) => new RegistrationPage()
            )
            ),
            child: new Text(
              "Need an Account? Sign Up Now!",
              style: new TextStyle(
                fontSize: 18.0,
                color: Colors.white
              ),
            ),
            color: UgoGreen,
          ),
        ),
      ],
    ));
    list.add(new Expanded(child: new Container(),));
    list.add(new Builder(
      builder: (BuildContext context) {
        return new Row(
          children: <Widget>[
            new Expanded(
              child: new FlatButton(
                onPressed: !_emailValid()
                  ? null
                  : () => _forgotPassword(context),
                  child: new Text(
                  "Forgot Password?",
                  style: new TextStyle(
                    fontSize: 18.0,
                    color: Colors.white
                  ),
                ),
                color: UgoGreen
              ),
            ),
          ],
        );
      },
    ));

    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Login"),
      ),
      body: new Container(
        margin: new EdgeInsets.all(20.0),
        child: new Column(
          children: list,
        ),
      ),
    );
  }
}
