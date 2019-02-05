import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugo_flutter/pages/home_page.dart';
import 'package:ugo_flutter/pages/webview_page.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/models/gender.dart';
import 'package:ugo_flutter/models/profile.dart';
import 'package:ugo_flutter/models/zone.dart';
import 'package:ugo_flutter/models/addressType.dart';
import 'package:flutter/src/widgets/editable_text.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:ugo_flutter/pages/checkout_page.dart';
import 'package:ugo_flutter/models/cart.dart';
import 'package:ugo_flutter/models/shipping_method.dart';

class GuestDetailsPage extends StatefulWidget {
  final List<CartTotal> cartTotals;
  final ShippingMethod shippingMethod;
  final double tipAmount;
  final bool guestUser;

  GuestDetailsPage(this.cartTotals,this.tipAmount, this.shippingMethod, this.guestUser);

  @override
  _GuestDetailsPageState createState() => new _GuestDetailsPageState();
}

class _GuestDetailsPageState extends State<GuestDetailsPage> {
  List<CartTotal> _totals;
  ShippingMethod _shippingMethod;
  String _email = "";
  String _firstName = "";
  String _lastName = "";
  String _phone = "";
  String _city = "";
  String apartmentName = "";
  String _address1 = "";
  String _address2 = "";
  String _postCode = "";

  List<Zone> zone;
  Zone _selectedZone;
  bool _zoneLoading = false;
  bool loadZone = false;
  int optedZone;
  int optedCountry = 223;

  bool showApartment = false;
  bool _loading = false;

  AddressType selectedAddressType;
  List<AddressType> addressType = <AddressType>[const AddressType(13,'House'), const AddressType(14,'Apartment')];
  bool _typeloading = false;
  bool loadAddressType = false;
  int optedAddressType;
  bool guestUser = true;
  double _tipAmount;

  final _analytics = new FirebaseAnalytics();


  @override
  initState() {
    super.initState();
    _totals = widget.cartTotals;
    _shippingMethod = widget.shippingMethod;
    _tipAmount = widget.tipAmount;
    _getZones();
  }

  void _submitGuestDetails(BuildContext context) async {
    optedCountry = 223;
    optedZone = (loadZone == true) ? _selectedZone.id : '';
    optedAddressType = (loadAddressType == true) ? selectedAddressType.id : '';
    //setState(() => _loading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(PreferenceNames.GUEST_USER_EMAIL, _email.toLowerCase());
    prefs.setString(PreferenceNames.GUEST_USER_FIRST_NAME, _firstName);
    prefs.setString(PreferenceNames.GUEST_USER_LAST_NAME, _lastName);
    prefs.setString(PreferenceNames.GUEST_USER_TELEPHONE, _phone);
    prefs.setInt(PreferenceNames.GUEST_USER_ADDRESS_TYPE_ID, optedAddressType);
    prefs.setString(PreferenceNames.GUEST_USER_APARTMENT_NAME, apartmentName);
    prefs.setString(PreferenceNames.GUEST_USER_ADDRESS1, _address1);
    prefs.setString(PreferenceNames.GUEST_USER_ADDRESS2, _address2);
    prefs.setString(PreferenceNames.GUEST_USER_CITY, _city);
    prefs.setString(PreferenceNames.GUEST_USER_POSTCODE, _postCode);
    prefs.setInt(PreferenceNames.GUEST_USER_COUNTRY_ID, optedCountry);
    prefs.setInt(PreferenceNames.GUEST_USER_ZONE_ID, optedZone);
    prefs.setBool(PreferenceNames.GUEST_USER,true);
    _nextPage();

  }

  _nextPage(){
    Widget checkoutRoute = new CheckoutPage(_totals,_tipAmount,_shippingMethod,null,guestUser);
    Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (BuildContext context) => checkoutRoute,
        )
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

  _getZones() {
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

  bool _formValid() =>
      _email.trim().toLowerCase().replaceAll(EMAIL_REGEXP, "").length == 0
          && _email.length > 4
          && _phone.replaceAll(PHONE_LENGTH_REGEXP, "").length > 9
          && _phone.replaceAll(PHONE_REGEXP, "").length == _phone.length
          && _firstName.length > 1
          && _lastName.length > 1
          && _address1.length >0
          && _postCode.length > 3
          && _city.length > 0
          && _selectedZone !=  null
          && selectedAddressType != null
          && _address2Valid()
          && _apartmentNameValid();

  String _buttonText() {
    //if (_loading) return "Checking Out...";
    if (_formValid()) { return "Continue to Checkout"; }
    return "Complete Form to Checkout";
  }

  @override
  Widget build(BuildContext context) {
    @override
    final phoneIcon = Theme.of(context).platform == TargetPlatform.iOS
        ? Icons.phone_iphone : Icons.phone_android;
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Enter Details"),
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
              new Padding(padding: new EdgeInsets.only(top: 20.0),),
              new Builder(
                builder: (BuildContext context) {
                  return new RaisedButton(
                    onPressed: (_formValid()) ?() => _submitGuestDetails(context) : null,
                    color: UgoGreen,
                    child: new Text(
                      _buttonText(),
                      style: new TextStyle(
                          color: Colors.white,
                          fontSize: 18.0
                      ),
                    ),
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
