import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugo_flutter/pages/card_management_page.dart';
import 'package:ugo_flutter/pages/order_history_page.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/models/gender.dart';
import 'package:ugo_flutter/models/profile.dart';
import 'package:ugo_flutter/models/country.dart';
import 'package:ugo_flutter/models/zone.dart';
import 'package:flutter/src/widgets/editable_text.dart';
import 'package:intl/intl.dart';
import 'dart:async';


class AccountPage extends StatefulWidget {
  final Function() updateCart;

  AccountPage({this.updateCart});

  @override
  _AccountPageState createState() => new _AccountPageState();
}

class _AccountPageState extends State<AccountPage> with SingleTickerProviderStateMixin {
  Map<String, String> _accountInfo = {};
  Map<String, String> _accountAddress = {};
  TabController _tabController;


  List<Country> country = [];
  Country _selectedCountry;
  bool _countryLoading = false;

  List<Zone> zone;
  Zone _selectedZone;
  Zone fetchedZone;
  bool _zoneLoading = false;


  @override
  initState() {
    super.initState();
    _tabController = new TabController(length: 3, vsync: this);
    _getAccountInfo();
    _getAddresses();
    _getCountries();

  }

  Gender selectedGender;
  Gender fetchedGender;
  List<Gender> gender = <Gender>[ new Gender(5,'Male'), new Gender(6,'Female'), new Gender(7,'Other')];
  bool _loading = false;

  Profile selectedProfile;
  Profile fetchedProfile;
  List<Profile> profile = <Profile>[const Profile(8,'Student'), const Profile(9,'Non-Student'), const Profile(10,'Student-Greek'), const Profile(11,'Parent'), const Profile(12,'Faculty')];

  _getAccountInfo() async {
    var firstName = await PrefsManager.getString(PreferenceNames.USER_FIRST_NAME);
    var lastName = await PrefsManager.getString(PreferenceNames.USER_LAST_NAME);
    var email = await PrefsManager.getString(PreferenceNames.USER_EMAIL);
    var phone = await PrefsManager.getString(PreferenceNames.USER_TELEPHONE);
    var fax = await PrefsManager.getString(PreferenceNames.USER_FAX);
    var dateOfBirth = await PrefsManager.getString(PreferenceNames.USER_DATE_OF_BIRTH);
    var selGender = await PrefsManager.getString(PreferenceNames.USER_GENDER);
    var profile = await PrefsManager.getString(PreferenceNames.USER_PROFILE);

    setState(() => _accountInfo = {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "phone": phone,
      "fax" : fax,
      "dateOfBirth":dateOfBirth,
      "gender": selGender,
      "profile": profile
    });

   // debugPrint("Accoutn Info => $_accountInfo");

    if(_accountInfo['gender']  == '5'){
      fetchedGender = new Gender(5, "Male");
    }else if(_accountInfo['gender']  == '6'){
      fetchedGender = new Gender(6, "Female");
    }else if(_accountInfo['gender']  == '7'){
      fetchedGender = new Gender(7, "Other");
    }

    if(_accountInfo['profile']  == '8'){
      fetchedProfile = new Profile(8, "Student");
    }else if(_accountInfo['profile']  == '9'){
      fetchedProfile = new Profile(9, "Non-Student");
    }else if(_accountInfo['profile']  == '10'){
      fetchedProfile = new Profile(10, "Student-Greek");
    }else if(_accountInfo['profile']  == '11'){
      fetchedProfile = new Profile(11, "Parent");
    }else if(_accountInfo['profile']  == '12'){
      fetchedProfile = new Profile(12, "Faculty");
    }
  }

  // Get new account information
  final TextEditingController _dob = new TextEditingController();
  Future _chooseDate(BuildContext context, String initialDateString) async {
    var now = new DateTime.now();
    var fetchDate = _accountInfo['dateOfBirth'].toString();
    var initialDate = convertToDate(initialDateString) ?? now;
    initialDate = (initialDate.year >= 1900 && initialDate.isBefore(now) ? initialDate : now);

    var result = await showDatePicker(
        context: context,
        initialDate :DateTime.parse(fetchDate),
        firstDate: new DateTime(1900),
        lastDate: new DateTime.now());

    if (result == null) return;

    setState(() {
      _dob.text = new DateFormat("yyyy-MM-dd").format(result);

    });
  }

  DateTime convertToDate(String input) {
    try
    {
      var d = new DateFormat.yMd().parseStrict(input);
      return d;
    } catch (e) {
      return null;
    }
  }

  _updateAccount(BuildContext context) {
   // debugPrint("hello");
    var test = fetchedGender.id;
   // debugPrint("Gender : $test");
    var test1 = fetchedProfile.id;
   // debugPrint("Gender : $test1");

    final params = {
      "email": _accountInfo["email"].toLowerCase(),
      "firstname": _accountInfo["firstName"],
      "lastname": _accountInfo["lastName"],
      "telephone": _accountInfo["phone"],
      "fax": _accountInfo["fax"],
      "custom_fields[1][value]":fetchedGender.id.toString(),
      "custom_fields[2][value]":fetchedProfile.id.toString(),
    };
     //debugPrint("param : $params");
    ApiManager.request(
      OCResources.PUT_ACCOUNT,
      (json) {
        final account = json["account"];
        //debugPrint("accont: $account");
        final prefGroup = {
          PreferenceNames.USER_FIRST_NAME: account["firstname"],
          PreferenceNames.USER_LAST_NAME: account["lastname"],
          PreferenceNames.USER_EMAIL: account["email"],
          PreferenceNames.USER_TELEPHONE: account["telephone"],
          PreferenceNames.USER_FAX: account["fax"],
          PreferenceNames.USER_DATE_OF_BIRTH:  account["custom_fields"][0]['value'],
          PreferenceNames.USER_GENDER:  account["custom_fields"][1]['value'],
          PreferenceNames.USER_PROFILE:  account["custom_field"][2]['value'],
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
        PrefsManager.clearPref(PreferenceNames.USER_DATE_OF_BIRTH);
        PrefsManager.clearPref(PreferenceNames.USER_GENDER);
        PrefsManager.clearPref(PreferenceNames.USER_PROFILE);
        PrefsManager.clearPref(PreferenceNames.USER_STRIPE_ID);
      }
    );
  }


  _getAddresses() {
    ApiManager.request(
        OCResources.GET_ADDRESSES,
            (json) {
          final address = json['addresses'];
          setState(() => _accountAddress = {
            "address_1": address[0]['address_1'],
            "postcode": address[0]['postcode'],
            "city": address[0]['city'],
            "zone_id": address[0]['zone_id'],
            "zone":address[0]['zone'],
            "country_id":address[0]['country_id'],
            "country":address[0]['country'],
          });
          _selectedCountry = new Country(address[0]['country_id'], _accountAddress['country']);
          _selectedZone = new Zone(address[0]['zone_id'], _accountAddress['zone']);
          _getZones();
        }
    );
  }

  _getCountries() {
    ApiManager.request(
        OCResources.GET_COUNTRY,
            (json) {
          final countries = json["countries"].map((country) =>
          new Country.fromJSON(country)).toList();
          setState(() => country = countries);
          setState(() => _countryLoading = false);
        }
    );
  }

  _getZones() {
    var cid = _accountAddress["country_id"];
    var countryId = (_selectedCountry == null) ? cid : _selectedCountry.id ;
    ApiManager.request(
      OCResources.POST_ZONE,
          (json) {
        if(json["zone"] != null) {
          final zones = json["zone"].map((zone) =>
          new Zone.fromJSON(zone)).toList();
          setState(() => zone = zones);
          setState(() => _zoneLoading = false);
        }
      },
      params: {
        "country_id":countryId.toString(),
      },
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
          new Row(children: <Widget>[
            new Expanded(
                child: new TextFormField(
                  decoration: new InputDecoration(
                    labelText: 'Date of Birth',
                  ),
                  controller: new TextEditingController(text: _dob.text),
                  keyboardType: TextInputType.datetime,
                )),
            new IconButton(
              icon: new Icon(Icons.date_range),
              tooltip: 'Choose date',
              onPressed: (() {
                _chooseDate(context,_dob.text);
              }),
            )
          ]),
          new InputDecorator(
            decoration: const InputDecoration(
                labelText: 'Gender'
            ),
            isEmpty: selectedGender == '',
            child: new DropdownButtonHideUnderline(
              child: new DropdownButton<Gender>(
                value: fetchedGender,
                isDense: true,
                onChanged: (Gender newValue) {
                  setState(() {
                    fetchedGender = newValue;
                  });
                },
                items: gender.map((Gender gen) {
                  return new DropdownMenuItem<Gender>(
                    value: gen,
                    child: new Text(
                        gen.name
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          new InputDecorator(
            decoration: const InputDecoration(
                labelText: 'Customer Profile'
            ),
            isEmpty: selectedProfile == '',
            child: new DropdownButtonHideUnderline(
              child: new DropdownButton<Profile>(
                value: fetchedProfile,
                isDense: true,
                onChanged: (Profile newValue) {
                  setState(() {
                    fetchedProfile = newValue;

                  });
                },
                items: profile.map((Profile pro) {
                  return new DropdownMenuItem<Profile>(
                    value: pro,
                    child: new Text(
                        pro.name
                    ),
                  );
                }).toList(),
              ),
            ),
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
          new TextField(
              decoration: const InputDecoration(
                  labelText: 'Address'
              ),
              controller: new TextEditingController(text: _accountAddress["address_1"]),
              onChanged: (value) => setState(() => _accountAddress["address_1"] = value)
          ),
          new TextField(
              decoration: const InputDecoration(
                  labelText: 'City'
              ),
              controller: new TextEditingController(text: _accountAddress["city"]),
              onChanged: (value) => setState(() => _accountAddress["city"] = value)
          ),
          new TextField(
              decoration: const InputDecoration(
                  labelText: 'Post Code'
              ),
              controller: new TextEditingController(text: _accountAddress["postcode"]),
              onChanged: (value) => setState(() => _accountAddress["postcode"] = value)
          ),
          new InputDecorator(
            decoration: const InputDecoration(
                prefixIcon: const Icon(Icons.flag),
                labelText: 'Country'
            ),
            isEmpty: _selectedCountry == '',
            child: new DropdownButtonHideUnderline(
              child: new DropdownButton<Country>(
                value: _selectedCountry,
                isDense: true,
                onChanged: (Country newValue) {
                  setState(() {
                    _selectedCountry = newValue;
                    _zoneLoading = true;
                    //_getZones();
                  });
                },
                items: country.map((Country country) {
                  return new DropdownMenuItem<Country>(
                    value: country,
                    child: new Text(
                        country.name
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          new InputDecorator(
            decoration: const InputDecoration(
                prefixIcon: const Icon(Icons.local_florist),
                labelText: 'Zone'
            ),
            isEmpty: _selectedZone == '',
            child: new DropdownButtonHideUnderline(
              child: new DropdownButton<Zone>(
                value: _selectedZone,
                isDense: true,
                onChanged: (Zone newValue) {
                  setState(() {
                    _selectedZone = newValue;
                  });
                },
                items: zone?.map((Zone zone) {
                  return new DropdownMenuItem<Zone>(
                    value: zone,
                    child: new Text(
                        zone.name
                    ),
                  );
                })?.toList() ?? [],
              ),
            ),
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
                          ? "Update Address"
                          : "Enter Address to Update",
                      style: new TextStyle(
                          fontSize: 18.0,
                          color: Colors.white
                      ),
                    )
                ),
              ),
            ],
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
        }, //child:
      )
    );
  }
}
