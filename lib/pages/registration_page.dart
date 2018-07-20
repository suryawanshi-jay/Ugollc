import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugo_flutter/pages/home_page.dart';
import 'package:ugo_flutter/pages/webview_page.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/constants.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => new _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  String _email = "";
  String _firstName = "";
  String _lastName = "";
  String _password = "";
  String _confirmation = "";
  String _phone = "";
  String _fax = "";

  bool _loading = false;

  final _analytics = new FirebaseAnalytics();

  void _submitRegistration(BuildContext context) {
    setState(() => _loading = true);
    ApiManager.request(
      OCResources.REGISTER,
      (json) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString(PreferenceNames.USER_EMAIL, _email.toLowerCase());
        prefs.setString(PreferenceNames.USER_FIRST_NAME, _firstName);
        prefs.setString(PreferenceNames.USER_LAST_NAME, _lastName);
        prefs.setString(PreferenceNames.USER_TELEPHONE, _phone);
        prefs.setString(PreferenceNames.USER_FAX, _fax);
        await _analytics.logSignUp(signUpMethod: "form");

        _setupStripeCustomer(context);
      },
      params: {
        "firstname": _firstName,
        "lastname": _lastName,
        "email": _email.toLowerCase(),
        "password": _password,
        "confirm": _confirmation,
        "telephone": _phone,
        "fax": _fax,
        "company": STRIPE_STANDIN,
        "address_1": "NAA",
        "address_2": "NAA",
        "city": "Tuscaloosa",
        "postcode": "35401",
        "country_id": "223",
        "zone_id": "3613"
      },
      errorHandler: (error) {
        setState(() => _loading = false);
        ApiManager.defaultErrorHandler(error, context: context);
      }
    );
  }

  void _setupStripeCustomer(BuildContext context) {
    ApiManager.request(
      StripeResources.ADD_CUSTOMER,
      (json) async {
//        SharedPreferences prefs = await SharedPreferences.getInstance();
//        prefs.setString(PreferenceNames.USER_STRIPE_ID, json["id"]);
        setState(() => _loading = false);
        Navigator.of(context).pushAndRemoveUntil(
          new MaterialPageRoute(builder: (BuildContext context) => new HomePage()),
          ModalRoute.withName("/false"));
      },
      params: {
        "email": _email.toLowerCase(),
      },
      errorHandler: (error) {
        setState(() => _loading = false);
        Navigator.of(context).pushAndRemoveUntil(
          new MaterialPageRoute(builder: (BuildContext context) => new HomePage()),
          ModalRoute.withName("/false"));
      }
    );
  }

  bool _formValid() =>
    _email.trim().toLowerCase().replaceAll(EMAIL_REGEXP, "").length == 0
      && _email.length > 4
      && _phone.replaceAll(PHONE_LENGTH_REGEXP, "").length > 9
      && _phone.replaceAll(PHONE_REGEXP, "").length == _phone.length
      && _firstName.length > 0
      && _lastName.length > 0
      && _password.length > 0
      && _password == _confirmation;

  String _buttonText() {
    if (_loading) return "Submitting...";
    if (_formValid()) { return "Sign Up Now"; }
    return "Complete Form to Sign Up";
  }

  @override
  Widget build(BuildContext context) {
    final phoneIcon = Theme.of(context).platform == TargetPlatform.iOS
      ? Icons.phone_iphone : Icons.phone_android;

    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Sign Up"),
        backgroundColor: UgoGreen,
      ),
      body: new Container(
        margin: new EdgeInsets.only(top: 15.0, left: 20.0, right: 20.0, bottom: 0.0),
        child: new SingleChildScrollView(
          child: new Column(
            children: <Widget>[
              new TextField(
                decoration: const InputDecoration(
                  prefixIcon: const Icon(Icons.mail_outline),
                  labelText: 'Email'
                ),
                onChanged: (value) {
                  setState(() => _email = value);
                },
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
              ),
              new TextField(
                decoration: new InputDecoration(
                  prefixIcon: new Icon(phoneIcon),
                  labelText: 'Phone Number',
                  helperText: 'To contact you if needed to complete orders.'
                ),
                onChanged: (value) {
                  setState(() => _phone = value);
                },
                autocorrect: false,
              ),
              new Padding(padding: const EdgeInsets.only(top: 10.0)),
              new TextField(
                decoration: const InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  labelText: 'First Name'
                ),
                onChanged: (value) {
                  setState(() => _firstName = value);
                },
                autocorrect: false,
              ),
              new TextField(
                decoration: const InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  labelText: 'Last Name'
                ),
                onChanged: (value) {
                  setState(() => _lastName = value);
                },
                autocorrect: false,
              ),
              new TextField(
                decoration: const InputDecoration(
                    prefixIcon: const Icon(Icons.print),
                    labelText: 'Fax'
                ),
                onChanged: (value) {
                  setState(() => _fax = value);
                },
                autocorrect: false,
              ),
              new TextField(
                decoration: const InputDecoration(
                  prefixIcon: const Icon(Icons.lock_open),
                  labelText: 'Password'
                ),
                onChanged: (value) {
                  setState(() => _password = value);
                },
                obscureText: true,
                autocorrect: false,
              ),
              new TextField(
                decoration: const InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  labelText: 'Password (Confirmation)'
                ),
                onChanged: (value) {
                  setState(() => _confirmation = value);
                },
                obscureText: true,
                autocorrect: false,
              ),
              new Padding(padding: new EdgeInsets.only(top: 20.0),),
              new Builder(
                builder: (BuildContext context) {
                  return new RaisedButton(
                    onPressed: (_formValid() && !_loading)
                      ? () => _submitRegistration(context)
                      : null,
                    color: UgoGreen,
                    child: new Text(
                      _buttonText(),
//                  "Sign Up Now",
                      style: new TextStyle(
                        color: Colors.white,
                        fontSize: 18.0
                      ),
                    ),
                  );
                }
              ),
              new Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 10.0),
                child: new Text(
                  "By signing up, you are agreeing to our\nTerms & Conditions",
                  textAlign: TextAlign.center,
//                  style: new TextStyle(fontSize: 18.0),
                ),
              ),
              new FlatButton(
                child: new Text(
                  "View Terms Here",
                  style: new TextStyle(
                    color: Colors.white,
                    fontSize: 18.0
                  ),
                ),
                color: UgoGreen,
                onPressed: () => Navigator.push(
                  context, new MaterialPageRoute(
                  builder: (BuildContext context) => new WebViewPage("http://ugodelivery.herokuapp.com/terms")
                )
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
