import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugo_flutter/pages/card_management_page.dart';
import 'package:ugo_flutter/pages/order_history_page.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';

class AccountPage extends StatefulWidget {
  final Function() updateCart;

  AccountPage({this.updateCart});

  @override
  _AccountPageState createState() => new _AccountPageState();
}

class _AccountPageState extends State<AccountPage> with SingleTickerProviderStateMixin {
  Map<String, String> _accountInfo = {};

  TabController _tabController;

  @override
  initState() {
    super.initState();
    _tabController = new TabController(length: 3, vsync: this);
    _getAccountInfo();
  }

  _getAccountInfo() async {
    var firstName = await PrefsManager.getString(PreferenceNames.USER_FIRST_NAME);
    var lastName = await PrefsManager.getString(PreferenceNames.USER_LAST_NAME);
    var email = await PrefsManager.getString(PreferenceNames.USER_EMAIL);
    var phone = await PrefsManager.getString(PreferenceNames.USER_TELEPHONE);
    var fax = await PrefsManager.getString(PreferenceNames.USER_FAX);

    setState(() => _accountInfo = {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "phone": phone,
      "fax": fax
    });
  }

  _updateAccount(BuildContext context) {
    final params = {
      "email": _accountInfo["email"].toLowerCase(),
      "firstname": _accountInfo["firstName"],
      "lastname": _accountInfo["lastName"],
      "telephone": _accountInfo["phone"],
      "fax": _accountInfo["fax"]
    };

    ApiManager.request(
      OCResources.PUT_ACCOUNT,
      (json) {
        final account = json["account"];
        final prefGroup = {
          PreferenceNames.USER_FIRST_NAME: account["firstname"],
          PreferenceNames.USER_LAST_NAME: account["lastname"],
          PreferenceNames.USER_EMAIL: account["email"],
          PreferenceNames.USER_TELEPHONE: account["telephone"],
          PreferenceNames.USER_FAX: account["fax"]
        };
        PrefsManager.setStringGroup(prefGroup);
        Navigator.pop(context);
      },
      params: params
    );
  }

  _updatePassword(BuildContext context) {
    ApiManager.request(
      OCResources.POST_PASSWORD,
      (json) {
        Scaffold.of(context).showSnackBar(
          new SnackBar(
            content: new Text("Password Updated!", style: new TextStyle(fontSize: 18.0),),
            backgroundColor: UgoGreen,
          )
        );
      },
      params: {
        "password": _accountInfo["password"],
        "confirm": _accountInfo["confirm"]
      }
    );
  }

  _logout(BuildContext context) {
    ApiManager.request(
      OCResources.LOGOUT,
      (json) {
        _refreshToken(context);
        PrefsManager.clearPref(PreferenceNames.USER_FIRST_NAME);
        PrefsManager.clearPref(PreferenceNames.USER_LAST_NAME);
        PrefsManager.clearPref(PreferenceNames.USER_EMAIL);
        PrefsManager.clearPref(PreferenceNames.USER_TELEPHONE);
        PrefsManager.clearPref(PreferenceNames.USER_FAX);
        PrefsManager.clearPref(PreferenceNames.USER_STRIPE_ID);
      }
    );
  }

  _refreshToken(BuildContext context) {
    ApiManager.request(
      OCResources.POST_TOKEN,
      (json) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.remove(PreferenceNames.USER_TOKEN);
        prefs.setString(PreferenceNames.USER_TOKEN, json["access_token"]);
        if (widget.updateCart != null) {
          widget.updateCart();
        }
        Navigator.pop(context);
      },
    );
  }
  
  bool _phoneValid() {
    final phone = _accountInfo["phone"];
    if (phone != null) {
      final phoneLengthValid = phone.replaceAll(PHONE_LENGTH_REGEXP, "").length > 9;
      return phone.length == phone.replaceAll(PHONE_REGEXP, "").length
        && phoneLengthValid;
    }
    return false;
  }

  bool _emailValid() {
    if (_accountInfo["email"] != null) {
      final email = _accountInfo["email"].toLowerCase();
      return email.replaceAll(EMAIL_REGEXP, "").length == 0;
    }
    return false;
  }
  
  bool _formValid() {
    if (_accountInfo["firstName"] != null && _accountInfo["lastName"] != null) {
      return _accountInfo["firstName"].length > 0
        && _accountInfo["lastName"].length > 0
        && _phoneValid()
        && _emailValid();
    }
    return false;
  }

  bool _passwordUpdateValid() =>
    _accountInfo["password"] != null
    && _accountInfo["confirm"] != null
    && _accountInfo["password"] == _accountInfo["confirm"]
      && _accountInfo["password"].length > 0;

  _view(BuildContext context) {
    var passwordText = _passwordUpdateValid() ? "Update Password" : "Passwords do not match";
    if (_accountInfo["password"] != null && _accountInfo["password"].length < 1) {
      passwordText = "Enter Password to Update";
    }

    return new Container(
      margin: new EdgeInsets.all(20.0),
      child: new ListView(
        children: <Widget>[
          new TextField(
            decoration: const InputDecoration(
              labelText: 'First Name'
            ),
            controller: new TextEditingController(text: _accountInfo["firstName"]),
            onChanged: (value) => setState(() => _accountInfo["firstName"] = value)
          ),
          new TextField(
            decoration: const InputDecoration(
              labelText: 'Last Name'
            ),
            controller: new TextEditingController(text: _accountInfo["lastName"]),
            onChanged: (value) => setState(() => _accountInfo["lastName"] = value)
          ),
          new TextField(
            decoration: const InputDecoration(
              labelText: 'Email'
            ),
            controller: new TextEditingController(text: _accountInfo["email"]),
            onChanged: (value) => setState(() => _accountInfo["email"] = value)
          ),
          new TextField(
            decoration: const InputDecoration(
              labelText: 'Phone'
            ),
            controller: new TextEditingController(text: _accountInfo["phone"]),
            onChanged: (value) => setState(() => _accountInfo["phone"] = value)
          ),
          new TextField(
              decoration: const InputDecoration(
                  labelText: 'Fax'
              ),
              controller: new TextEditingController(text: _accountInfo["fax"]),
              onChanged: (value) => setState(() => _accountInfo["fax"] = value)
          ),
          new Padding(padding: new EdgeInsets.only(top: 10.0),),
          new Row(
            children: <Widget>[
              new Expanded(
                child: new RaisedButton(
                  color: UgoGreen,
                  onPressed: _formValid()
                    ? () => _updateAccount(context)
                    : null,
                  child: new Text(
                    _formValid()
                    ? "Update Account"
                    : "Enter Info to Update",
                    style: new TextStyle(
                      fontSize: 18.0,
                      color: Colors.white
                    ),
                  )
                ),
              ),
            ],
          ),
//          new Padding(padding: new EdgeInsets.only(top: 10.0),),
          new TextField(
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
            controller: new TextEditingController(text: _accountInfo["password"]),
            onChanged: (value) {
              setState(() => _accountInfo["password"] = value);
            }
          ),
          new TextField(
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
            ),
            controller: new TextEditingController(text: _accountInfo["confirm"]),
            onChanged: (value) => setState(() => _accountInfo["confirm"] = value)
          ),
          new Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: new Row(
              children: <Widget>[
                new Expanded(
                  child: new RaisedButton(
                    color: UgoGreen,
                    onPressed: _passwordUpdateValid()
                      ? () => _updatePassword(context)
                      : null,
                    child: new Text(
                      passwordText,
                      style: new TextStyle(
                        fontSize: 18.0,
                        color: Colors.white
                      ),
                    )
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Account"),
        actions: <Widget>[
          new GestureDetector(
            onTap: () => _logout(context),
            child: new Container(
              margin: new EdgeInsets.all(10.0),
              padding: new EdgeInsets.symmetric(horizontal: 15.0),
              decoration: new BoxDecoration(
                color: Colors.red,
                borderRadius: new BorderRadius.all(const Radius.circular(20.0)),
                border: new Border.all(color: Colors.white, width: 3.0)
              ),
              child: new Row(
                children: <Widget>[
                  new Text(
                    "Logout",
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: new TabBar(
          controller: _tabController,
          tabs: [
            new Tab(icon: new Icon(Icons.account_circle), text: "Details",),
            new Tab(icon: new Icon(Icons.credit_card), text: "Cards"),
            new Tab(icon: new Icon(Icons.shopping_cart), text: "History"),
          ],
        ),
      ),
      body: new Builder(
        builder: (BuildContext context) {
          return new TabBarView(
            children: [
              _view(context),
              new CardManagementPage(),
              new OrderHistoryPage()
            ],
            controller: _tabController,
          );
        },
//        child:
      )
    );
  }
}
