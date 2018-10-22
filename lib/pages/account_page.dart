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
import 'package:ugo_flutter/models/addressType.dart';
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
  bool loadCountry =true;
  String optedCountry = '';

  List<Zone> zone;
  Zone _selectedZone;
  Zone fetchedZone;
  bool _zoneLoading = false;
  bool loadZone =true;
  String optedZone = '';

  bool showApartment = false;

  bool showDob;
  bool blankDob = false;

  String guestRegCoupon;
  bool _showGuestCoupon = false;

  @override
  initState() {
    super.initState();
    _tabController = new TabController(length: 3, vsync: this);
    _getAccountInfo();
    _getAddresses();
    _getCountries();
    _checkIfGuest();

  }

  _checkIfGuest() async {
    guestRegCoupon = await PrefsManager.getString(PreferenceNames.GUEST_REG_COUPON);
    debugPrint('$guestRegCoupon');
    if(guestRegCoupon != null){
      setState(() => _showGuestCoupon = true);
    }

  }

  Gender selectedGender;
  Gender fetchedGender;
  List<Gender> gender = <Gender>[ new Gender(5,'Male'), new Gender(6,'Female'), new Gender(7,'Other')];
  bool _loading = false;
  bool loadGender = true;
  String optedGender = '';

  Profile selectedProfile;
  Profile fetchedProfile;
  List<Profile> profile = <Profile>[const Profile(8,'Student'), const Profile(9,'Non-Student'), const Profile(10,'Student-Greek'), const Profile(11,'Parent'), const Profile(12,'Faculty')];
  bool loadProfile = true;
  String optedProfile = '';


  AddressType selectedAddressType;
  AddressType fetchedAddressType;
  List<AddressType> addressType = <AddressType>[const AddressType(13,'House'), const AddressType(14,'Apartment')];
  bool loadAddressType = true;
  String optedAddressType = '';

  TextEditingController firstNamecntrl = new TextEditingController();
  TextEditingController lastNamecntrl = new TextEditingController();
  TextEditingController emailcntrl = new TextEditingController();
  TextEditingController telephonecntrl = new TextEditingController();
  //TextEditingController faxtcntrl = new TextEditingController();

  TextEditingController apartmentNamecntrl = new TextEditingController();
  TextEditingController streetAddresscntrl = new TextEditingController();
  TextEditingController suitecntrl = new TextEditingController();
  TextEditingController citycntrl = new TextEditingController();
  TextEditingController postcodecntrl = new TextEditingController();

  TextEditingController passwordcntrl = new TextEditingController();
  TextEditingController cnfpasswordcntrl = new TextEditingController();


  _getAccountInfo() async {
    var firstName = await PrefsManager.getString(PreferenceNames.USER_FIRST_NAME);
    var lastName = await PrefsManager.getString(PreferenceNames.USER_LAST_NAME);
    var email = await PrefsManager.getString(PreferenceNames.USER_EMAIL);
    var phone = await PrefsManager.getString(PreferenceNames.USER_TELEPHONE);
    //var fax = await PrefsManager.getString(PreferenceNames.USER_FAX);
    var dateOfBirth = await PrefsManager.getString(PreferenceNames.USER_DATE_OF_BIRTH);
    var selGender = await PrefsManager.getString(PreferenceNames.USER_GENDER);
    var profile = await PrefsManager.getString(PreferenceNames.USER_PROFILE);

    setState(() => _accountInfo = {
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "phone": phone,
      //"fax" : fax,
      "dateOfBirth":dateOfBirth,
      "gender": selGender,
      "profile": profile
    });

    firstNamecntrl.text = firstName;
    lastNamecntrl.text = lastName;
    emailcntrl.text = email;
    telephonecntrl.text = phone;
    //faxtcntrl.text = fax;

    if(_accountInfo['dateOfBirth'] == '' || dateOfBirth == null ){
      showDob = false;
      blankDob = true;
    }else {
      showDob = true;
    }

    if(_accountInfo['gender']  == '5'){
      selectedGender = new Gender(5, "Male");
    }else if(_accountInfo['gender']  == '6'){
      selectedGender = new Gender(6, "Female");
    }else if(_accountInfo['gender']  == '7'){
      selectedGender = new Gender(7, "Other");
    }else{
      loadGender = false;
    }

    if(_accountInfo['profile']  == '8'){
      selectedProfile = new Profile(8, "Student");
    }else if(_accountInfo['profile']  == '9'){
      selectedProfile = new Profile(9, "Non-Student");
    }else if(_accountInfo['profile']  == '10'){
      selectedProfile = new Profile(10, "Student-Greek");
    }else if(_accountInfo['profile']  == '11'){
      selectedProfile = new Profile(11, "Parent");
    }else if(_accountInfo['profile']  == '12'){
      selectedProfile = new Profile(12, "Faculty");
    }else{
      loadProfile = false;
    }
  }

  // Get new account information
  TextEditingController _dob = new TextEditingController();

  Future _chooseDate(BuildContext context, String initialDateString) async {
    var now = new DateTime.now();
    var fetchDate = _accountInfo['dateOfBirth'].toString();
    var initialDate = convertToDate(initialDateString) ?? now;
    initialDate = (initialDate.year >= 1900 && initialDate.isBefore(now) ? initialDate : now);
    var result = await showDatePicker(
        context: context,
        initialDate : blankDob ? initialDate : DateTime.parse(fetchDate),
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
    optedGender = (loadGender == true) ? selectedGender.id.toString() : '';
    optedProfile = (loadProfile == true) ? selectedProfile.id.toString() : '';
    final params = {
      "email": _accountInfo["email"].toLowerCase(),
      "firstname": _accountInfo["firstName"],
      "lastname": _accountInfo["lastName"],
      "telephone": _accountInfo["phone"],
      //"fax": _accountInfo["fax"],
      "custom_field[2]":optedGender,
      "custom_field[3]":optedProfile,
      "custom_field[4]":showDob ?_accountInfo['dateOfBirth']: _dob.text.toString(),
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
            //PreferenceNames.USER_FAX: account["fax"],
            PreferenceNames.USER_DATE_OF_BIRTH:  account['custom_fields'][0]['value'],
            PreferenceNames.USER_GENDER:  account['custom_fields'][1]['value'],
            PreferenceNames.USER_PROFILE:  account['custom_fields'][2]['value'],
          };
          PrefsManager.setStringGroup(prefGroup);
          Navigator.pop(context);
        },
        params: params

    );
  }


  _updateAddress(BuildContext context) {
    optedCountry = '223';
    optedZone = (loadZone == true) ? _selectedZone.id.toString() : '';
    optedAddressType = (loadAddressType == true) ? selectedAddressType.id.toString() : '';
    final params = {
      "firstname":_accountInfo["firstName"],
      "lastname" : _accountInfo["lastName"],
      "custom_field[6]":optedAddressType,
      "custom_field[7]":_accountAddress["apartmentName"],
      "address_1": _accountAddress["address_1"],
      "address_2": _accountAddress["address_2"],
      "city": _accountAddress["city"],
      "postcode": _accountAddress["postcode"],
      "country_id": optedCountry,
      "zone_id":optedZone
    };
    ApiManager.request(
        OCResources.PUT_ADDRESS,
            (json) {
          final address = json["address"];
          final prefGroup = {
            PreferenceNames.USER_ADDRESS_TYPE: address['custom_fields'][0]['value'],
            PreferenceNames.USER_APARTMENT_NAME: address['custom_fields'][1]['value'],
            PreferenceNames.USER_ADDRESS1: address["address_1"],
            PreferenceNames.USER_CITY: address["city"],
            PreferenceNames.USER_POSTCODE: address["postcode"],
            PreferenceNames.USER_COUNTRY: address["country_id"],
            PreferenceNames.USER_ZONE: address["zone_id"]
          };
          PrefsManager.setStringGroup(prefGroup);
          Navigator.pop(context);
        },
        params: params,
        resourceID: _accountAddress['address_id'].toString()
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
          //PrefsManager.clearPref(PreferenceNames.USER_FAX);
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
            "address_id" : address[0]['address_id'],
            "addressType" :address[0]['custom_field']['6'],
            "apartmentName" : address[0]['custom_field']['7'],
            "address_1": address[0]['address_1'],
            "address_2": address[0]['address_2'],
            "postcode": address[0]['postcode'],
            "city": address[0]['city'],
            "zone_id": address[0]['zone_id'],
            "zone":address[0]['zone'],
            "country_id":address[0]['country_id'],
            "country":address[0]['country'],
          });

          apartmentNamecntrl.text = address[0]['custom_field']['7'];
          streetAddresscntrl.text =  address[0]['address_1'];
          suitecntrl.text = address[0]['address_2'];
          citycntrl.text = address[0]['city'];
          postcodecntrl.text = address[0]['postcode'];

          if(_accountAddress['addressType'] == 13){
            selectedAddressType = new AddressType(13, "House");
          }else if(_accountAddress['addressType'] ==14){
            selectedAddressType = new AddressType(14, "Apartment");
            showApartment = true;
          }else{
            loadAddressType = false;
          }

          if(_accountAddress["country_id"] != null) {
            _selectedCountry = new Country(address[0]['country_id'], _accountAddress['country']);
          }else {
            loadCountry = false;
          }

          if(_accountAddress["country_id"] != null) {
            _selectedZone = new Zone(address[0]['zone_id'], _accountAddress['zone']);
            _getZones();
          }else{
            loadZone = false;
          }
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


  _refreshZones() {
    var cid = _accountAddress["country_id"];
    var countryId = (_selectedCountry == null) ? cid : _selectedCountry.id ;
    ApiManager.request(
      OCResources.POST_ZONE,
          (json) {
        _selectedZone = new Zone(int.parse(json['zone'][0]['zone_id']), json['zone'][0]['name']);
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
          && _emailValid()
          && isValidDob()
          && selectedGender != null
          && selectedProfile != null;
    }
    return false;
  }
  bool _addressformValid() {
    if(_accountAddress["address_1"] != null && _accountAddress["city"] != null && _accountAddress["postcode"] != null && _accountAddress["address_2"] != null) {
      return _accountAddress['address_1'].length >0
          && _accountAddress['city'].length >0
          && _accountAddress['postcode'].length >0
          //&& _selectedCountry != null
          && _selectedZone !=  null
          && selectedAddressType != null
          && _address2Valid()
          && _apartmentNameValid();
    }
    return false;
  }

  bool _apartmentNameValid() {
    if(selectedAddressType.id == 14) {
      return _accountAddress['apartmentName'].length >0;
    }else if(selectedAddressType.id == 13)
    {
      return true;
    }
  }

  bool _address2Valid(){
    if(selectedAddressType.id == 14) {
      return _accountAddress['address_2'].length >0;
    }else if(selectedAddressType.id == 13)
    {
      return true;
    }
  }

  bool isValidDob() {
    final dob =showDob ? _accountInfo["dateOfBirth"]: _dob.text;
    return dob.isNotEmpty;
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
          _showGuestCoupon ? new Text("Use coupon $guestRegCoupon to avail 10% off on your new order",style: new TextStyle(fontSize: 18.0, color: Colors.green, fontStyle: FontStyle.italic)
          ): new Container(),
          new TextField(
              decoration: const InputDecoration(
                  labelText: 'First Name'
              ),
              //controller: new TextEditingController(text: _accountInfo["firstName"]),
              controller: firstNamecntrl,
              onChanged: (value) => setState(() => _accountInfo["firstName"] = value)
          ),
          new TextField(
              decoration: const InputDecoration(
                  labelText: 'Last Name'
              ),
              controller: lastNamecntrl,
              onChanged: (value) => setState(() => _accountInfo["lastName"] = value)
          ),
          new TextField(
              decoration: const InputDecoration(
                  labelText: 'Email'
              ),
              controller: emailcntrl,
              onChanged: (value) => setState(() => _accountInfo["email"] = value)
          ),
          new TextField(
              decoration: const InputDecoration(
                  labelText: 'Phone'
              ),
              controller: telephonecntrl,
              onChanged: (value) => setState(() => _accountInfo["phone"] = value)
          ),
          //new TextField(
          //    decoration: const InputDecoration(
          //       labelText: 'Fax'
          //   ),
          //   controller: faxtcntrl,
          //   onChanged: (value) => setState(() => _accountInfo["fax"] = value)
          //),
          new Row(children: <Widget>[
            new Expanded(
                child: new TextField(
                  decoration: const InputDecoration(
                      labelText: 'Date of Birth'
                  ),
                  controller: blankDob ? _dob : new TextEditingController(text: showDob ? _accountInfo["dateOfBirth"]: _dob.text),
                  keyboardType: TextInputType.datetime,
                )),
            new IconButton(
              icon: new Icon(Icons.date_range),
              tooltip: 'Choose date',
              onPressed:(() {
                showDob =  false;
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
                value: selectedGender,
                isDense: true,
                onChanged: (Gender newValue) {
                  setState(() {
                    loadGender  = true;
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
                labelText: 'Customer Profile'
            ),
            isEmpty: selectedProfile == '',
            child: new DropdownButtonHideUnderline(
              child: new DropdownButton<Profile>(
                value: selectedProfile,
                isDense: true,
                onChanged: (Profile newValue) {
                  setState(() {
                    loadProfile  = true;
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
                labelText: 'New Password',
              ),
              controller: passwordcntrl,
              onChanged: (value) {
                setState(() => _accountInfo["password"] = value);
              }
          ),
          new TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
              ),
              controller: cnfpasswordcntrl,
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
                    loadAddressType = true;
                    selectedAddressType = newValue;
                    if(selectedAddressType.id == 14){
                      showApartment = true;
                    }else if(selectedAddressType.id == 13){
                      showApartment = false;
                      _accountAddress["apartmentName"]="";
                      _accountAddress["address_2"]= "";

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
                  labelText: 'Apartment Name'
              ),
              controller: apartmentNamecntrl,
              onChanged: (value) => setState(() => _accountAddress["apartmentName"] = value)
          ): new Container(),
          new TextField(
              decoration: const InputDecoration(
                  labelText: 'Street Address'
              ),
              controller: streetAddresscntrl,
              onChanged: (value) => setState(() => _accountAddress["address_1"] = value)
          ),
          showApartment ? new TextField(
              decoration: const InputDecoration(
                  labelText: 'Suite/Apt #'
              ),
              controller:suitecntrl,
              onChanged: (value) => setState(() => _accountAddress["address_2"] = value)
          ): new Container(),
          new TextField(
              decoration: const InputDecoration(
                  labelText: 'City'
              ),
              controller: citycntrl,
              onChanged: (value) => setState(() => _accountAddress["city"] = value)
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
          //          _refreshZones();
          //        });
          //      },
          //      items: country.map((Country country) {
          //        return new DropdownMenuItem<Country>(
          //            value: country,
          //            child: new SizedBox(width: 200.0, child: new Text(country.name))
          //        );
          //      }).toList(),
          //   ),
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
                    loadZone = true;
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
                  labelText: 'Zip Code'
              ),
              controller: postcodecntrl,
              onChanged: (value) => setState(() => _accountAddress["postcode"] = value)
          ),
          new Padding(padding: new EdgeInsets.only(top: 10.0),),
          new Row(
            children: <Widget>[
              new Expanded(
                child: new RaisedButton(
                    color: UgoGreen,
                    onPressed: _addressformValid()
                        ? () => _updateAddress(context)
                        : null,
                    child: new Text(
                      _addressformValid()
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
