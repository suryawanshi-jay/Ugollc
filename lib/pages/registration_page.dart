import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugo_flutter/pages/home_page.dart';
import 'package:ugo_flutter/pages/webview_page.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/models/gender.dart';
import 'package:ugo_flutter/models/profile.dart';
import 'package:ugo_flutter/models/country.dart';
import 'package:ugo_flutter/models/zone.dart';
import 'package:ugo_flutter/models/addressType.dart';
import 'package:flutter/src/widgets/editable_text.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';


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
  String _city = "";
  String apartmentName = "";
  String _address1 = "";
  String _address2 = "";
  //String _fax = "";
  String _postCode = "";

  List<Country> country = [];
  Country _selectedCountry;
  bool _countryLoading = false;
  bool loadCountry = false;
  String optedCountry = '';

  List<Zone> zone;
  Zone _selectedZone;
  bool _zoneLoading = false;
  bool loadZone = false;
  String optedZone = '';

  bool showApartment = false;

  //Profile
  Profile selectedProfile;
  List<Profile> profile = <Profile>[const Profile(8,'Student'), const Profile(9,'Non-Student'), const Profile(10,'Student-Greek'), const Profile(11,'Parent'), const Profile(12,'Faculty')];
  bool loadProfile = false;
  String optedProfile = '';
  // Gender
  Gender selectedGender;
  List<Gender> gender = <Gender>[const Gender(5,'Male'), const Gender(6,'Female'), const Gender(7,'Other')];
  bool loadGender = false;
  String optedGender = '';

  bool _loading = false;


  AddressType selectedAddressType;
  List<AddressType> addressType = <AddressType>[const AddressType(13,'House'), const AddressType(14,'Apartment')];
  bool _typeloading = false;
  bool loadAddressType = false;
  String optedAddressType = '';

  String guestRegCoupon;
  bool _showGuestCoupon = false;


  final _analytics = new FirebaseAnalytics();


  @override
  initState() {
    super.initState();
    _countryLoading = true;
    _getCountries();
    _getZones();
  }

  void _submitRegistration(BuildContext context) {
    optedGender = (loadGender == true) ? selectedGender.id.toString() : '';
    optedProfile = (loadProfile == true) ? selectedProfile.id.toString() : '';
    optedCountry = '223';
    optedZone = (loadZone == true) ? _selectedZone.id.toString() : '';
    optedAddressType = (loadAddressType == true) ? selectedAddressType.id.toString() : '';
    setState(() => _loading = true);
    ApiManager.request(
      OCResources.REGISTER,
      (json) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString(PreferenceNames.USER_EMAIL, _email.toLowerCase());
        prefs.setString(PreferenceNames.USER_FIRST_NAME, _firstName);
        prefs.setString(PreferenceNames.USER_LAST_NAME, _lastName);
        prefs.setString(PreferenceNames.USER_TELEPHONE, _phone);
        //prefs.setString(PreferenceNames.USER_FAX, _fax);
        prefs.setString(PreferenceNames.USER_ADDRESS_TYPE, optedAddressType);
        prefs.setString(PreferenceNames.USER_APARTMENT_NAME, apartmentName);
        prefs.setString(PreferenceNames.USER_ADDRESS1, _address1);
        prefs.setString(PreferenceNames.USER_ADDRESS2, _address2);
        prefs.setString(PreferenceNames.USER_CITY, _city);
        prefs.setString(PreferenceNames.USER_POSTCODE, _postCode);
        prefs.setString(PreferenceNames.USER_COUNTRY, optedCountry);
        prefs.setString(PreferenceNames.USER_ZONE, optedZone);
        prefs.setString(PreferenceNames.USER_GENDER, optedGender);
        prefs.setString(PreferenceNames.USER_PROFILE, optedProfile);
        prefs.setString(PreferenceNames.USER_DATE_OF_BIRTH, _dob.text.toString());

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
        //"fax": _fax,
        "custom_field[account][2]":optedGender,
        "custom_field[account][3]":optedProfile,
        "custom_field[account][4]":  _dob.text.toString(),
        /*"company": STRIPE_STANDIN,*/
        "company": '',
        "custom_field[address][6]":optedAddressType,
        "custom_field[address][7]": apartmentName,
        "address_1": _address1,
        "address_2": _address2,
        "city": _city,
        "postcode": _postCode,
        "country_id":optedCountry,
        "zone_id": optedZone,


      },

      errorHandler: (error) {
        setState(() => _loading = false);
        ApiManager.defaultErrorHandler(error, context: context);
      }
    );
  }

  final TextEditingController _dob = new TextEditingController();
  Future _chooseDate(BuildContext context, String initialDateString) async {
    var now = new DateTime.now();
    var initialDate = convertToDate(initialDateString) ?? now;
    initialDate = (initialDate.year >= 1900 && initialDate.isBefore(now) ? initialDate : now);

    var result = await showDatePicker(
        context: context,
        initialDate: initialDate,
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
    //var countryId = (_selectedCountry == null) ? 223 : _selectedCountry.id ;
    var countryId =223;
    ApiManager.request(
      OCResources.POST_ZONE,
          (json) {
        _selectedZone = new Zone(int.parse(json['zone'][0]['zone_id']), json['zone'][0]['name']);
        if(json["zone"] != null) {
          final zones = json["zone"].map((zone) =>
          new Zone.fromJSON(zone)).toList();
          setState(() => zone = zones);
          setState(() => _zoneLoading = false);
          setState(() => loadZone = true);

        }
      },
      params: {
        "country_id":countryId.toString(),
      },
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

  bool _apartmentNameValid() {
    if(selectedAddressType.id == 14) {
      return apartmentName.length >0;
    }else if(selectedAddressType.id == 13)
    {
      return true;
    }
  }

  bool _address2Valid() {
    if(selectedAddressType.id == 14) {
      return _address2.length >0;
    }else if(selectedAddressType.id == 13)
    {
      return true;
    }
  }

  bool isValidDob(String dob) {
    return dob.isNotEmpty;
  }

  bool _formValid() =>
    _email.trim().toLowerCase().replaceAll(EMAIL_REGEXP, "").length == 0
      && _email.length > 4
      && _phone.replaceAll(PHONE_LENGTH_REGEXP, "").length > 9
      && _phone.replaceAll(PHONE_REGEXP, "").length == _phone.length
      && _firstName.length > 1
      && _lastName.length > 1
      && _password.length > 0
      && _password == _confirmation
      && _address1.length >0
      && _postCode.length > 3
      && _city.length > 0
      //&& _selectedCountry != null
      && _selectedZone !=  null
      && selectedGender != null
      && selectedProfile != null
      && selectedAddressType != null
      && _address2Valid()
      && _apartmentNameValid()
      && isValidDob(_dob.text);

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
              //new TextField(
              //  decoration: new InputDecoration(
              //      prefixIcon: new Icon(phoneIcon),
              //      labelText: 'Fax'
              //  ),
              //  onChanged: (value) {
              //    setState(() => _fax = value);
              //  },
              //  autocorrect: false,
              //),
              new Row(children: <Widget>[
                new Expanded(
                    child: new TextFormField(
                      decoration: new InputDecoration(
                        icon: const Icon(Icons.calendar_today),
                        labelText: 'Date of Birth',
                      ),
                      controller: _dob,
                      keyboardType: TextInputType.datetime,
                    )),
                new IconButton(
                  icon: new Icon(Icons.date_range),
                  tooltip: 'Choose date',
                  onPressed: (() {
                    _chooseDate(context, _dob.text);
                  }),
                )
              ]),
              new InputDecorator(
                decoration: const InputDecoration(
                    prefixIcon: const Icon(Icons.person),
                    labelText: 'Gender'
                ),
                isEmpty: selectedGender == '',
                child: new DropdownButtonHideUnderline(
                  child: new DropdownButton<Gender>(
                    value: selectedGender,
                    isDense: true,
                    onChanged: (Gender newValue) {
                      setState(() {
                        loadGender = true;
                        selectedGender = newValue;
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
                    prefixIcon: const Icon(Icons.portrait),
                    labelText: 'Customer Profile'
                ),
                isEmpty: selectedProfile == '',
                child: new DropdownButtonHideUnderline(
                  child: new DropdownButton<Profile>(
                    value: selectedProfile,
                    isDense: true,
                    onChanged: (Profile newValue) {
                      setState(() {
                        loadProfile = true;
                        selectedProfile = newValue;
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
              //new Text("selected user name is ${selectedGender.name} : and Id is : ${selectedGender.id}"),
              new InputDecorator(
                decoration: const InputDecoration(
                    prefixIcon: const Icon(Icons.merge_type),
                    labelText: 'Address Type'
                ),
                isEmpty: selectedAddressType == '',
                child: new DropdownButtonHideUnderline(
                  child: new DropdownButton<AddressType>(
                    value: selectedAddressType,
                    isDense: true,
                    onChanged: (AddressType newValue) {
                      setState(() {
                        selectedAddressType = newValue;
                        loadAddressType = true;
                        if (selectedAddressType.id != null)
                        {
                          if (selectedAddressType.id == 14) {
                            showApartment = true;
                          } else if (selectedAddressType.id == 13) {
                            showApartment = false;
                            apartmentName = "";
                            _address2 = "";
                          }
                        }
                      });
                    },
                    items: addressType.map((AddressType at) {
                      return new DropdownMenuItem<AddressType>(
                        value: at,
                        child: new Text(
                            at.name
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              showApartment ? new TextField(
                decoration: const InputDecoration(
                    prefixIcon: const Icon(Icons.business),
                    labelText: 'Apartment Name'
                ),
                onChanged: (value) {
                  setState(() => apartmentName = value);
                },
                autocorrect: false,
              ): new Container(),
              new TextField(
                decoration: const InputDecoration(
                    prefixIcon: const Icon(Icons.home),
                    labelText: 'Street Address'
                ),
                onChanged: (value) {
                  setState(() => _address1 = value);
                },
                autocorrect: false,
              ),
              showApartment ? new TextField(
                decoration: const InputDecoration(
                    prefixIcon: const Icon(Icons.home),
                    labelText: 'Suite/Apt #'
                ),
                onChanged: (value) {
                  setState(() => _address2 = value);
                },
                autocorrect: false,
              ): new Container(),
              new TextField(
                decoration: const InputDecoration(
                    prefixIcon: const Icon(Icons.location_city),
                    labelText: 'City'
                ),
                onChanged: (value) {
                  setState(() => _city = value);
                },
                autocorrect: false,
              ),
              //new InputDecorator(
              //  decoration: const InputDecoration(
              //      prefixIcon: const Icon(Icons.flag),
              //      labelText: 'Country'
              //  ),
              //  isEmpty: _selectedCountry == '',
              //  child: new DropdownButtonHideUnderline(
              //    child: new DropdownButton<Country>(
              //      value: _selectedCountry,
              //      isDense: true,
              //      onChanged: (Country newValue) {
              //        setState(() {
              //          loadCountry = true;
              //          _selectedCountry = newValue;
              //          _zoneLoading = true;
              //          _getZones();
              //        });
              //      },
              //      items: country.map((Country country) {
              //        return new DropdownMenuItem<Country>(
              //          value: country,
              //          child: new SizedBox(width: 200.0, child: new Text(country.name)),
              //        );
              //      }).toList(),
              //    ),
              //  ),
              //),
              new InputDecorator(
                decoration: const InputDecoration(
                    prefixIcon: const Icon(Icons.local_florist),
                    labelText: 'State'
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
                          child: new SizedBox(width: 200.0, child: new Text(zone.name))
                      );
                    })?.toList() ?? [],
                  ),
                ),
              ),
              new TextField(
                decoration: const InputDecoration(
                    prefixIcon: const Icon(Icons.dialpad),
                    labelText: 'Zip Code'
                ),
                onChanged: (value) {
                  setState(() => _postCode = value);
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
