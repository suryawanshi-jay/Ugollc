import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:ugo_flutter/models/address.dart';
import 'package:ugo_flutter/models/cart.dart';
import 'package:ugo_flutter/models/payment_card.dart';
import 'package:ugo_flutter/models/shipping_method.dart';
import 'package:ugo_flutter/pages/add_card_page.dart';
import 'package:ugo_flutter/pages/loading_screen.dart';
import 'package:ugo_flutter/pages/order_confirm_page.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/models/addressType.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';
import 'package:flutter/src/widgets/editable_text.dart';
import 'package:flutter/src/material/text_field.dart';


class CheckoutPage extends StatefulWidget {
  final List<CartTotal> cartTotals;
  final ShippingMethod shippingMethod;
  final double creditAmount;
  final bool guestUser;


  CheckoutPage(this.cartTotals, this.shippingMethod,this.creditAmount,this.guestUser);

  @override
  _CheckoutPageState createState() => new _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _cardLoading = false;
  bool _addressLoading = false;
  bool _ordering = false;
  double _orderProcess = 0.0;
  bool _isCouponCodeValid = false;
  bool _isRewardValid = false;
  double _couponCodeAmount = 0.0;
  double _rewardPointAmount = 0.0;
  bool _isButtonDisabled;
  bool _isRewardButtonDisabled;
  String couponMessage = '';
  String paymentWarning;
  String rewardMessage = '';
  String couponCodeType = '';
  double couponValue = 0.0;
  String dCCAmount = "0.0";
  Color msgColor = Colors.red;
  double _couponTax = 0.0;
  double _rewardPointTax = 0.0;
  bool updateUser = false;
  bool showPaymentWarning = false;

  Cart _cart;
  String _cartError;


  List<PaymentCard> _cards = [];
  String _selectedCard;

  AddressType selectedAddressType;
  AddressType fetchedAddressType;
  List<AddressType> addressType = <AddressType>[const AddressType(13,'House'), const AddressType(14,'Apartment')];
  bool loadAddressType = true;
  String optedAddressType = '';

  bool showApartment = false;

  bool _addressAvailable = false;

  bool showuniqueId = false;

  List<Address> _addresses = [];
  int _selectedAddress;

  String _address1;
  String _address2;
  String _city;
  String _zip;
  String _apartmentName;
  String firstName;
  String lastName;
  String email;
  String telephone;
  String dob;
  String gender;
  String profile;
  int countryID;
  int zoneID;
  int addressTypeID;
  String _uniqueId;


  TextEditingController _addressController = new TextEditingController();
  TextEditingController _zipController = new TextEditingController();
  TextEditingController _commentController = new TextEditingController();
  TextEditingController _couponCodeController = new TextEditingController();
  TextEditingController _rewardPointController = new TextEditingController();
  TextEditingController _address2Controller = new TextEditingController();
  TextEditingController _cityController = new TextEditingController();
  TextEditingController _apartmentNameController = new TextEditingController();
  TextEditingController _uniqueIdController = new TextEditingController();

  ShippingMethod _shippingMethod;
  List<CartTotal> _totals;
  bool _guestUser;
  String _firstname;
  String _lastname;
  String _email;
  String _telephone;
  String _dob;
  String _gender;
  String _profile;
  String guestRegCoupon;
  bool _showGuestCoupon = false;
  double _credits;
  bool _showRewardPoint = false;
  int _rewardTotal = 0;
  String _userEmail;
  int _maxPointUse = 0;

  BuildContext _navContext;

  String _userComment;


  final _analytics = new FirebaseAnalytics();

  @override
  initState() {
    super.initState();
    _totals = widget.cartTotals;
    _shippingMethod = widget.shippingMethod;
    _credits = widget.creditAmount;
    _guestUser = widget.guestUser;
    _cardLoading = true;
    _addressLoading = true;
    _isButtonDisabled = false;
    _isRewardButtonDisabled = false;

    if(_guestUser == false){
      _logCheckout();
      _getCards();
      _getAddresses();
      _checkIfGuest();
      _getCart();
    }else{
      _getGuestInfo();

    }

  }

  _getCart() {
    ApiManager.request(
        OCResources.GET_CART,
            (json) {
          setState(() => _cart = new Cart.fromJSON(json["cart"]));
          if (_cart != null) {
            setState(() => _maxPointUse = json["cart"]["max_reward_points_to_use"]);
            _cart.products.forEach((product) {
              if (product.points > 0) {
                setState(() => _showRewardPoint = true);
                _getUserEmail();
              }
            });
          }
        },
        errorHandler: (json) {
          setState(() => _cartError = json["errors"].first["message"]);
        }
    );
  }

  _getUserEmail() async{
    _userEmail = await PrefsManager.getString(PreferenceNames.USER_EMAIL);
    setState(() => _userEmail = _userEmail);
    _getRewards();
  }

  _getRewards() {
    ApiManager.request(
      OCResources.POST_REWARD_POINTS,
          (json) {
        if(json["rewards_total"] != null) {
          setState(() => _rewardTotal = json['rewards_total']);
        }
      },
      params: {
        "customer_email" : _userEmail
      },
    );
  }

  _checkIfGuest() async {
    guestRegCoupon = await PrefsManager.getString(PreferenceNames.GUEST_REG_COUPON);
    if(guestRegCoupon != null){
      setState(() => _showGuestCoupon = true);
      setState(() => _couponCodeController.text  = guestRegCoupon);
    }

  }

  _getGuestInfo() async {
    _firstname = await PrefsManager.getString(PreferenceNames.GUEST_USER_FIRST_NAME);
    _lastname = await PrefsManager.getString(PreferenceNames.GUEST_USER_LAST_NAME);
    _email = await PrefsManager.getString(PreferenceNames.GUEST_USER_EMAIL);
    _telephone = await PrefsManager.getString(PreferenceNames.GUEST_USER_TELEPHONE);
    _addressController.text = await PrefsManager.getString(PreferenceNames.GUEST_USER_ADDRESS1);
    _zipController.text =await PrefsManager.getString(PreferenceNames.GUEST_USER_POSTCODE);
    _cityController.text = await PrefsManager.getString(PreferenceNames.GUEST_USER_CITY);
    _address2Controller.text = await PrefsManager.getString(PreferenceNames.GUEST_USER_ADDRESS2);
    _apartmentNameController.text = await PrefsManager.getString(PreferenceNames.GUEST_USER_APARTMENT_NAME);
    zoneID =  await PrefsManager.getInt(PreferenceNames.GUEST_USER_ZONE_ID);
    countryID = await PrefsManager.getInt(PreferenceNames.GUEST_USER_COUNTRY_ID);
    addressTypeID = await PrefsManager.getInt(PreferenceNames.GUEST_USER_ADDRESS_TYPE_ID);
    if(addressTypeID == 13) {
      selectedAddressType = new AddressType(13, "House");
    }else if(addressTypeID == 14){
      selectedAddressType = new AddressType(14, "Apartment");
      showApartment = true;
    }else{
      loadAddressType = false;
      updateUser = true;
    }
    setState((){
      _selectedAddress = null;
      _address2 =  _address2Controller.text;
      _city = _cityController.text;
      _address1 = _addressController.text;
      _zip = _zipController.text;
      _apartmentName = _apartmentNameController.text;
      _uniqueId = _uniqueIdController.text;
      selectedAddressType = selectedAddressType;
      firstName = _firstname;
      lastName = _lastname;
      email = _email;
      telephone = _telephone;
    });
  }

  _logCheckout() async {
    await _analytics.logBeginCheckout();
  }

  // API FETCH METHODS
  _getCards() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final stripe_email = prefs.getString(PreferenceNames.USER_EMAIL);
    if (stripe_email != null && stripe_email != "") {
      ApiManager.request(
        StripeResources.ADD_CUSTOMER,
            (json) {
          prefs.setString(PreferenceNames.USER_STRIPE_ID, json["id"]);
          final sources = json["sources"];
          final stripeCards = sources["data"].map((source) =>
          new PaymentCard.fromJSON(source));
          setState(() => _cards = stripeCards.toList());
          setState(() => _cardLoading = false);
        },
        params: {
          "email": stripe_email,
        },
      );
    }
  }

  _getAddresses() {
    ApiManager.request(
        OCResources.GET_ADDRESSES,
            (json) {
          final addrs = json["addresses"].map((addr) =>
          new Address.fromJSON(addr)).toList();
          setState(() => _addresses = addrs);
          setState(() => _addressLoading = false);
        }
    );
  }

  // API SUBMIT METHODS
  // FIGURE OUT BAILOUT SAFETY NET WHEN ANY OF THESE FAILS

  _placeOrder(BuildContext context) {
    setState(() => _orderProcess = 0.0);
    setState(() => _ordering = true);
    if(_guestUser == true){
      _submitGuestPaymentAddress(context);
    }else {
      _submitPaymentAddress(context);
    }
  }

  //SUBMIT GUEST PAYMENT ADDRESS
  _submitGuestPaymentAddress(BuildContext context) {
    setState(() => _orderProcess = 0.1);
    var params;
    params = standinAddress;
    params["payment_address"] = "new";
    ApiManager.request(
        OCResources.POST_PAYMENT_ADDRESS,
            (json) {
          _submitGuestShippingAddress(context);
        },
        params: params,
        errorHandler: (error) {
          setState(() => _orderProcess = 0.0);
          setState(() => _ordering = false);
          ApiManager.defaultErrorHandler(error, context: context);
        }
    );

  }


  // POST BILLING ADDRESS (STANDIN)
  _submitPaymentAddress(BuildContext context) {
    setState(() => _orderProcess = 0.1);
    var addrID;
    var params;
    final stripeAddrs = _addresses.where((addr) => addr.company == STRIPE_STANDIN);
    if (stripeAddrs.isNotEmpty) {
      addrID = stripeAddrs.first.id;
      params = {
        "payment_address": "existing",
        "address_id": addrID.toString()
      };
    } else {
      params = standinAddress;
      params["payment_address"] = "new";
    }

    // TODO add handling of null addrID (logout/login?), indicates no default payment address
    ApiManager.request(
        OCResources.POST_PAYMENT_ADDRESS,
            (json) {
          _submitShippingAddress(context);
        },
        params: params,
        errorHandler: (error) {
          setState(() => _orderProcess = 0.0);
          setState(() => _ordering = false);
          ApiManager.defaultErrorHandler(error, context: context);
        }
    );
  }

  // POST SHIPPING ADDRESS (ENTERED -- NEW OR EXISTING?)
  _submitShippingAddress(BuildContext context) {
    if (_selectedAddress != null) {
      _submitExistingShippingAddress(context);
    } else {
      _geocodeNewAddress(context);
    }
  }


  _submitGuestShippingAddress(BuildContext context) {
    _geocodeNewAddress(context);
  }

  _submitExistingShippingAddress(BuildContext context) {
    setState(() => _orderProcess = 0.3);
    var addID = _selectedAddress.toString();

    //Update existing user
    if(updateUser == true){
      final params = {
        "firstname": firstName,
        "lastname" : lastName,
        "custom_field[6]":selectedAddressType.id.toString(),
        "custom_field[7]":_apartmentName,
        "address_1": _address1,
        "address_2": _address2,
        "city": _city,
        "postcode": _zip,
        "country_id": countryID.toString(),
        "zone_id":zoneID.toString()
      };
      ApiManager.request(
          OCResources.PUT_ADDRESS,
              (json) {
            final address = json["address"];
          },
          params: params,
          resourceID: addID
      );
    }//Update existing user end

    ApiManager.request(
        OCResources.POST_SHIPPING_ADDRESS,
            (json) {
          _submitShippingMethod(context);
        },

        params: { "shipping_address": "existing", "address_id": _selectedAddress.toString()},
        errorHandler: (error) {
          setState(() => _orderProcess = 0.0);
          setState(() => _ordering = false);
          ApiManager.defaultErrorHandler(error, context: context);
        }
    );
  }

  _submitNewShippingAddress(Map params, BuildContext context) {
    setState(() => _orderProcess = 0.3);
    ApiManager.request(
        OCResources.POST_SHIPPING_ADDRESS,
            (json) {
          _submitShippingMethod(context);
        },
        params: params,
        errorHandler: (error) {
          setState(() => _orderProcess = 0.0);
          setState(() => _ordering = false);
          ApiManager.defaultErrorHandler(error, context: context);
        }
    );
  }

  _submitGuestNewShippingAddress(Map params, BuildContext context) {
    setState(() => _orderProcess = 0.3);
    ApiManager.request(
        OCResources.POST_GUEST_SHIPPING_ADDRESS,
            (json) {
          _submitShippingMethod(context);
        },
        params: params,
        errorHandler: (error) {
          setState(() => _orderProcess = 0.0);
          setState(() => _ordering = false);
          ApiManager.defaultErrorHandler(error, context: context);
        }
    );
  }

  _geocodeNewAddress(BuildContext context) {
    setState(() => _orderProcess = 0.2);
    final addrString = "$_address1, $_zip".replaceAll(" ", "+");
    ApiManager.request(
        GoogleResources.GET_COORDS,
            (json) async {
            if(json['status'] != "ZERO_RESULTS") {
              final location = json["results"].first["geometry"]["location"];
              final double lat = location["lat"];
              final double lon = location["lng"];
              final addressPoint = new Point(lat, lon);
              if (_deliveryDistance(addressPoint) > UGO_DELIVERY_RADIUS) {
                setState(() => _orderProcess = 0.0);
                setState(() => _ordering = false);
                ApiManager.defaultErrorHandler(
                    {},
                    context: context,
                    message: "Your address appears to be outside our delivery area. "
                        "If you would like to continue, "
                        "please enter another address and try again.",
                    analyticsInfo: "Coordinates: $lat, $lon",
                    delay: 5000
                );
                return;
              }

              var addressComponents = {};
              final List componentList = json["results"]
                  .first["address_components"];
              componentList.forEach((comp) {
                final type = comp["types"].first;
                addressComponents[type] = comp["short_name"];
              });
              SharedPreferences prefs = await SharedPreferences.getInstance();

              if (_guestUser == true) {
                prefs.getString(PreferenceNames.GUEST_USER_FIRST_NAME);
                final ocAddr = {
                  "firstname": prefs.getString(
                      PreferenceNames.GUEST_USER_FIRST_NAME),
                  "lastname": prefs.getString(
                      PreferenceNames.GUEST_USER_LAST_NAME),
                  "custom_field[6]": '13',
                  "custom_field[7]": _apartmentName,
                  "address_1": _address1,
                  "address_2": _address2,
                  "city": _city,
                  "postcode": _zip,
                  "country_id": countryID.toString(),
                  "zone_id": zoneID.toString(),
                  "shipping_address": "new"
                };
                _submitGuestNewShippingAddress(ocAddr, context);
              } else {
                prefs.getString(PreferenceNames.USER_FIRST_NAME);
                final ocAddr = {
                  "firstname": prefs.getString(PreferenceNames.USER_FIRST_NAME),
                  "lastname": prefs.getString(PreferenceNames.USER_LAST_NAME),
                  "custom_field[6]": selectedAddressType.id.toString(),
                  "custom_field[7]": _apartmentName,
                  "address_1": _address1,
                  "address_2": _address2,
                  "city": _city,
                  "postcode": _zip,
                  "country_id": countryID.toString(),
                  "zone_id": zoneID.toString(),
                  "shipping_address": "new"
                };
                _submitNewShippingAddress(ocAddr, context);
              }
            }else{
              setState(() => _orderProcess = 0.0);
              setState(() => _ordering = false);
              ApiManager.defaultErrorHandler(
                  {},
                  context: context,
                  message: "Your address appears to be outside our delivery area. "
                      "If you would like to continue, "
                      "please enter another address and try again.",
                  delay: 5000
              );
              return;
            }
        },
        resourceID: addrString,
        errorHandler: (error) {
          setState(() => _orderProcess = 0.0);
          setState(() => _ordering = false);
          ApiManager.defaultErrorHandler(
              {},
              context: context,
              message: "Your address appears to be outside our delivery area. "
                  "If you would like to continue, "
                  "please enter another address and try again.",
              delay: 5000
          );
        }
    );
  }

  double _deliveryDistance(Point addressPoint) {
    final radFactor = PI/180.0;

    var storeLat = UGO_STORE_LOC.x;
    var storeLon = UGO_STORE_LOC.y;

    final lat1 = storeLat * radFactor;
    final lon1 = storeLon * radFactor;
    final lat2 = addressPoint.x * radFactor;
    final lon2 = addressPoint.y * radFactor;

    var sinLat = pow(sin((lat2 - lat1)/2.0), 2);
    var sinLon = pow(sin((lon2 - lon1)/2.0), 2);
    var cosLat = cos(lat1) * cos(lat2);

    var a = sinLat + cosLat * sinLon;
    var c = 2 * atan2(sqrt(a), sqrt(1-a));
    var distance = EARTH_RADIUS * c;

    return distance;
  }

  // POST SHIPPING METHOD
  _submitShippingMethod(BuildContext context) {
    setState(() => _orderProcess = 0.4);
    ApiManager.request(OCResources.GET_SHIPPING_METHODS, (json) {
      ApiManager.request(
          OCResources.POST_SHIPPING_METHOD,
              (json) {
            _pickPaymentMethod(context);
          },
          params: {
            "shipping_method": (_shippingMethod == null ? 'flat.flat' : _shippingMethod.id.toString())
          },
          errorHandler: (error) {
            setState(() => _orderProcess = 0.0);
            setState(() => _ordering = false);
            ApiManager.defaultErrorHandler(error, context: context);
          }
      );
    });
  }

  // GET PAYMENT METHODS
  _pickPaymentMethod(BuildContext context) {
    setState(() => _orderProcess = 0.5);
    ApiManager.request(
        OCResources.GET_PAYMENT_METHOD,
            (json) {
          if (_selectedCard == "cod") {
            // post payment
            _submitPayment("cod", "", context);
          }else if(_selectedCard == "BAMA Cash") {
            _submitPayment("BAMA Cash", "", context);
          }else if(_selectedCard == "DD") {
            _submitPayment("DD", "", context);
          }
          else if (_selectedCard != null) {
            // post stripe transaction
            _submitStripePayment(context);
          }
        },
        errorHandler: (error) {
          setState(() => _orderProcess = 0.0);
          setState(() => _ordering = false);
          ApiManager.defaultErrorHandler(error, context: context);
        }
    );
  }

  // POST STRIPE TRANSACTION (IF STRIPE)
  _submitStripePayment(BuildContext context) async {
    setState(() => _orderProcess = 0.6);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final customerID = prefs.getString(PreferenceNames.USER_STRIPE_ID);
    final now = new DateTime.now();
    final total = _cartTotalForStripe();

    bool regenerateKey = false;
    var idemKey = prefs.getString(PreferenceNames.STRIPE_IDEM_KEY);
    if (idemKey == null || idemKey == "") {
      regenerateKey = true;
    } else {
      final expire = prefs.getInt(PreferenceNames.STRIPE_IDEM_KEY_EXPIRE);
      final price = prefs.getInt(PreferenceNames.STRIPE_IDEM_KEY_PRICE);

      if (expire == null
          || expire == 0
          || price == null
          || price == 0
          || now.millisecondsSinceEpoch > expire
          || price != total
      ) {
        regenerateKey = true;
      }
    }

    if (regenerateKey) {
      idemKey = new Uuid().v4();
      prefs.setString(PreferenceNames.STRIPE_IDEM_KEY, idemKey);
      // 1000 milliseconds * 3600 seconds/hr * 24 hours
      final newExpire = now.millisecondsSinceEpoch + (1000 * 3600 * 24);
      prefs.setInt(PreferenceNames.STRIPE_IDEM_KEY_EXPIRE, newExpire);
      prefs.setInt(PreferenceNames.STRIPE_IDEM_KEY_PRICE, total);
    }

    ApiManager.request(
        StripeResources.POST_CHARGE,
            (json) {
          if (json["paid"] == true) {
            final id = json["id"];
            _submitPayment("stripe", "Stripe Transaction ID: $id", context);
          }
        },
        params: {
          "customer_id": customerID,
          "card_id": _selectedCard,
          "amount": total,
          "order_number": "${now.year}_${now.month}_${now.day}",
          "idem_key": idemKey
        },
        errorHandler: (error) {
          setState(() => _orderProcess = 0.0);
          setState(() => _ordering = false);
          ApiManager.defaultErrorHandler(error, context: context);
        }
    );
  }

  int _cartTotalForStripe() {
    final CartTotal total = _totals.where((total) => total.title == "Total").first;
    final String cleanTotal = total.text.replaceAll(PRICE_REGEXP, "");
    double couponTotal = 0.0;
    if(_isCouponCodeValid){ // If coupon code is applied
      couponTotal = (_couponCodeAmount + _couponTax) ;
    }
    double shippingCost = 0.0;
    if (_shippingMethod != null && _shippingMethod.cost != null) {
      shippingCost = _shippingMethod.cost.toDouble();
      final shippingTax = (shippingCost * 100 * TAX_RATE).round()/100.0;
      shippingCost += shippingTax;
    }

    final double floatTotal = (double.parse(cleanTotal) - couponTotal) + shippingCost;
    return (floatTotal * 100.0).toInt();
  }

  // POST PAYMENT METHOD (stripe or cod)
  // INCLUDE STRIPE TRANSACTION ID (IF STRIPE)
  _submitPayment(String method, String comment, BuildContext context) {
    setState(() => _orderProcess = 0.7);
    var commentText = comment;
    if (_userComment != null) {
      commentText = "$_userComment";
    }
    var uniqueIdText = showuniqueId? _uniqueIdController.text:"";

    ApiManager.request(
        OCResources.POST_PAYMENT_METHOD,
            (json) {
            _confirmOrder(context);
        },
        params: {
          "payment_method": method,
          "comment": commentText,
          "payment_id" : uniqueIdText
        },
        errorHandler: (error) {
          setState(() => _orderProcess = 0.0);
          setState(() => _ordering = false);
          ApiManager.defaultErrorHandler(
              error,
              context: context,
              message: "We're sorry, something happened with your order that's preventing it from completing. "
                  "Please try again. "
                  "If you've seen this message multiple times, "
                  "please call us so we can make sure your order gets handled properly.",
              delay: 5000
          );
        }
    );
  }

  // GET ORDER COMPLETE FOR GUEST ORDER
  _completeGuestOrder(orderId) {
    setState(() => _orderProcess = 0.10);
    ApiManager.request(
        OCResources.POST_GUEST_CONFIRM,
            (json){
        },
        errorHandler: (error) {
          setState(() => _orderProcess = 0.0);
          setState(() => _ordering = false);
          ApiManager.defaultErrorHandler(
              error,
              context: context,
              message: "We're sorry, something happened with your order that's preventing it from completing. "
                  "Please try again. "
                  "If you've seen this message multiple times, "
                  "please call us so we can make sure your order gets handled properly.",
              delay: 5000
          );
        },
      params: {
        "guest": "1",
        "firstname": firstName,
        "lastname": lastName,
        "email" : email,
        "telephone": telephone,
//        "custom_field[account][2]" : gender.toString(),
//        "custom_field[account][3]" : profile.toString(),
//        "custom_field[account][4]" : dob,
        "order_id" : orderId.toString()
      },
    );
  }

  // GET CONFIRM
  _confirmOrder(BuildContext context) {
    setState(() => _orderProcess = 0.8);
    ApiManager.request(
        OCResources.GET_CONFIRM,
        // (json) => _orderPaid(context),
            (json){
          _orderPaid(context);
          var orderId = json["order_id"];

          if(_guestUser == true){
           _completeGuestOrder(orderId);
          }
          updateCouponInfo(orderId);
        },
        errorHandler: (error) {
          setState(() => _orderProcess = 0.0);
          setState(() => _ordering = false);
          ApiManager.defaultErrorHandler(
              error,
              context: context,
              message: "We're sorry, something happened with your order that's preventing it from completing. "
                  "Please try again. "
                  "If you've seen this message multiple times, "
                  "please call us so we can make sure your order gets handled properly.",
              delay: 5000
          );
        }
    );
  }

  // GET PAY
  _orderPaid(BuildContext context) {
    setState(() => _orderProcess = 0.9);
    ApiManager.request(
        OCResources.GET_PAY,
            (json) {
          _orderSuccess(context);
          },
        errorHandler: (error) {
          setState(() => _orderProcess = 0.0);
          setState(() => _ordering = false);
          ApiManager.defaultErrorHandler(
              error,
              context: context,
              message: "We're sorry, something happened with your order that's preventing it from completing. "
                  "Please try again. "
                  "If you've seen this message multiple times, "
                  "please call us so we can make sure your order gets handled properly.",
              delay: 5000
          );
        }
    );
  }

  // GET SUCCESS
  _orderSuccess(BuildContext context) {
    setState(() => _orderProcess = 1.0);
    ApiManager.request(OCResources.GET_SUCCESS, (json) async {
      _analytics.logEcommercePurchase(currency: "USD");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove(PreferenceNames.STRIPE_IDEM_KEY);
      prefs.remove(PreferenceNames.STRIPE_IDEM_KEY_EXPIRE);
      prefs.remove(PreferenceNames.STRIPE_IDEM_KEY_PRICE);

      Navigator.push(_navContext,
          new MaterialPageRoute(
              builder: (BuildContext context) => new OrderConfirmPage())
      );
    },
        errorHandler: (error) {
          setState(() => _orderProcess = 0.0);
          setState(() => _ordering = false);
          ApiManager.defaultErrorHandler(
              error,
              context: context,
              message: "We're sorry, something happened with your order that's preventing it from completing. "
                  "Please try again. "
                  "If you've seen this message multiple times, "
                  "please call us so we can make sure your order gets handled properly.",
              delay: 5000
          );
        }
    );
  }


  // LAYOUT METHODS
  List<DropdownMenuItem> _cardList() {
    var cardList = [
      new DropdownMenuItem(child: new Text("Select Payment")),
    ];
    _cards.forEach((PaymentCard card) {
      cardList.add(new DropdownMenuItem(
          child: new Text("${card.brand}  ***${card.last4}"),
          value: card.id)
      );
    });

//    cardList.add(new DropdownMenuItem(child: new Divider(height: 0.0,)));
    cardList.add(new DropdownMenuItem(child: new Text("DINING DOLLARS"), value: "DD"));
    cardList.add(new DropdownMenuItem(child: new Text("BAMA CASH"), value: "BAMA Cash"));
    cardList.add(new DropdownMenuItem(child: new Text("Cash"), value: "cod"));

    return cardList;
  }

  List<DropdownMenuItem> _addressList() {
    var addrList = [new DropdownMenuItem(child: new Text("Select Address"))];
    _addresses.forEach((Address addr) {
      if (addr.address1 != "NAA" && addr.company != STRIPE_STANDIN) {
        var addr1 = addr.address1.length > 16 ? addr.address1.substring(0, 16) : addr.address1;
        addrList.add(new DropdownMenuItem(
          child: new Text("${addr1}, ${addr.zip}"),
          value: addr.id,
        ));
      }
    });
    return addrList;
  }

  _setAddress(addressID) {
    final pickedAddr = _addresses.where((addr) => addr.id == addressID).first;
    _addressController.text = pickedAddr.address1;
    _zipController.text = pickedAddr.zip;
    _cityController.text = pickedAddr.city;
    _address2Controller.text = pickedAddr.address2;
    _apartmentNameController.text = pickedAddr.apartmentName;
    firstName =  pickedAddr.firstName;
    lastName =  pickedAddr.lastName;
    countryID = pickedAddr.countryID;
    zoneID =  pickedAddr.zoneID;
    if(pickedAddr.addressType == 13) {
      selectedAddressType = new AddressType(13, "House");
    }else if(pickedAddr.addressType == 14){
      selectedAddressType = new AddressType(14, "Apartment");
      showApartment = true;
    }else{
      loadAddressType = false;
      updateUser = true;
    }


    setState(() {
      _selectedAddress = addressID;
      _address2 = pickedAddr.address2;
      _city = pickedAddr.city;
      _address1 = pickedAddr.address1;
      _zip = pickedAddr.zip;
      _apartmentName = pickedAddr.apartmentName;
      selectedAddressType = selectedAddressType;
      _addressAvailable = true;
    });
  }

  double _totalType(String type) {
    if (_totals == null) {
      return 0.0;
    }
    final totals = _totals.where((total) => total.title == type);
    if (totals.length > 0) {
      return double.parse(totals.first.text.replaceAll(PRICE_REGEXP, ""));
    }
    return 0.0;
  }

  Widget _totalRow(String text, String type, {double addedAmount: 0.0}) {
    if (_totals == null) {
      return new Container();
    }

    final totals = _totals.where((total) => total.title == type);
    if (totals == null || totals.length == 0) {
      return new Container();
    }

    final total = double.parse(totals.first.text.replaceAll(PRICE_REGEXP, ""));

    if(type =="Total" && _isCouponCodeValid){
      addedAmount = addedAmount -(_couponCodeAmount + _couponTax);
    }
    if(type =="Total" && _isRewardValid){
      addedAmount = addedAmount - _rewardPointAmount  ;
    }

    var totalAmount = total + addedAmount;
    if(type == "Store Credit"){
      if(totalAmount >= _credits) {
        totalAmount == _credits;
        return new Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            new Text(
              "$text: -\$${_credits.toStringAsFixed(2)}",
              style: new TextStyle(fontSize: 18.0),)
          ],
        );
      }else{
        return new Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            new Text(
              "$text: -\$${totalAmount.toStringAsFixed(2)}",
              style: new TextStyle(fontSize: 18.0),)
          ],
        );
      }
    }
    if(type == "Total" && total == 0.0){
      return new Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          new Text(
            "$text: \$${total.toStringAsFixed(2)}",
            style: new TextStyle(fontSize: 18.0),)
        ],
      );
    }
   
    return new Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        new Text(
          "$text: \$${(totalAmount).toStringAsFixed(2)}",
          style: new TextStyle(fontSize: 18.0),)
      ],
    );
  }

  Row _shippingRow() {
    if (_shippingMethod == null) {
      return new Row();
    }

    var text = "Delivery Charge: ${_shippingMethod.displayCost}";
    if (_shippingMethod.cost == 0) {
      text = "FREE DELIVERY!";
    }
    return new Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        new Text(text, style: new TextStyle(fontSize: 18.0))
      ],
    );
  }

  Row _storeCreditRow() {
    if (_credits == null) {
      return new Row();
    }

    var text = "Store Credit: - \$${_credits}";
    if (_credits == 0) {
      return new Row();
    }
    return new Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        new Text(text, style: new TextStyle(fontSize: 18.0))
      ],
    );
  }

  Row _rewardPointRow() {
    if (_isRewardValid == false) {
      return new Row();
    }
    var text = "Reward Point Value (${_rewardPointController.text}): -\$${_rewardPointAmount.toStringAsFixed(2)}";
    if (_rewardPointAmount == 0) {
      return new Row();
    }
    return new Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        new Text(text, style: new TextStyle(fontSize: 18.0))
      ],
    );
  }

  void _isGuestCouponValid() {
    if(_guestUser == true){
      setState(() => couponMessage = "Coupon codes are only available to registered customers");
    }
  }

  void _isCouponValid() {

    var couponCodeValue = _couponCodeController.text;

    // Give call coupon code api and get validity and coupon value from it
    ApiManager.request(
        OCResources.POST_COUPON_DETAILS,
            (json) {
          String status = json["status"];
          if(status == "valid"){
            setState(() => msgColor = Colors.green);
            setState(() => _couponCodeAmount = double.parse(json["discount"]));
            setState(() => _isButtonDisabled = true);
            setState(() => couponMessage = json["success"]);
            setState(() => couponCodeType = json["type"]);

            if(couponCodeType == "P"){
              final CartTotal subTotal = _totals.where((total) => total.title == "Sub-Total").first;
              final String clnTotal = subTotal.text.replaceAll(PRICE_REGEXP, "");
              double calcPercentage = ((double.parse(clnTotal) * _couponCodeAmount).round() / 100);
              setState(() => _couponCodeAmount = calcPercentage);
              // Calculate and reduce tax of coupon
              final tempCouponTax = (calcPercentage * TAX_RATE);
              setState(() => _couponTax = tempCouponTax);
            }else{
              final tempCouponTax1 = ((_couponCodeAmount * TAX_RATE));
              setState(() => _couponTax = tempCouponTax1);
              setState(() => _couponCodeAmount = _couponCodeAmount);
            }
          }else{
            setState(() => couponMessage = json["error"]);
          }
          setState(() => _isCouponCodeValid = true);
        },
        params: {
          "call_type": "api_call",
          "coupon": couponCodeValue
        },
        errorHandler: (error) {
          ApiManager.defaultErrorHandler(error, context: context);
        }
    );
    if(_guestUser == true){
      setState(() => couponMessage = "Coupon codes are only available to registered customers");
    }

  }

  void _clearAddress(){
    setState(() {
      _selectedAddress = null;
      selectedAddressType  = null;
      _apartmentNameController = new TextEditingController();
      _addressController = new TextEditingController();
      _address2Controller = new TextEditingController();
      _cityController = new TextEditingController();
      _zipController = new TextEditingController();
    });
  }

  void _isRewardPointValid(){
    var rewardPointValue = int.parse(_rewardPointController.text);
    if(_rewardTotal >= rewardPointValue && _maxPointUse >= rewardPointValue ){
      ApiManager.request(
          OCResources.POST_REWARD_VALUE,
              (json) {
                 if(json != null){
                   setState(() => msgColor = Colors.green);
                   setState(() => rewardMessage = "Your reward points discount has been applied!");
                   setState(() => _rewardPointAmount = json["discount"]);
                   setState(() => _rewardPointTax = json["discount"] * TAX_RATE);
                   setState(() => _isRewardButtonDisabled = true);
                   setState(() =>  _isRewardValid = true);

                 }

              },
          params: {
            "call_type": "rewardApiCall",
            "reward": _rewardPointController.text
          },
          errorHandler: (error) {
            ApiManager.defaultErrorHandler(error, context: context);
          }
      );


    }else{
      setState(() => rewardMessage = "Invalid reward points");

    }



  }

  void updateCouponInfo(lastOrderId){
    if(_isCouponCodeValid){
      ApiManager.request(
          OCResources.POST_UPDATE_COUPON_DETAILS,
              (json) {
          },
          params: {
            "order_id": "$lastOrderId",
            "coupon_code": _couponCodeController.text,
          },
          errorHandler: (error) {
            ApiManager.defaultErrorHandler(error, context: context);
          }
      );
    }

  }

  void forbiddenCheck(){
    ApiManager.request(
        OCResources.GET_FORBIDDEN_CHECK,
            (json) {
           if(json != null){
             setState(() => paymentWarning = json["error"]["warning"]);
             setState(() => showPaymentWarning = true);
           }
        },
        errorHandler: (error) {
          ApiManager.defaultErrorHandler(error, context: context);
        }
    );

  }


  Row _coupounCodeRow() {
    if (_isCouponCodeValid == false) {
      return new Row();
    }
    var text = "Coupon Value : -\$${_couponCodeAmount.toStringAsFixed(2)}";

    return new Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        new Text(text, style: new TextStyle(fontSize: 18.0))
      ],
    );
  }

  bool _isFormValid() {
    bool addressValid = _address1 != null && _address1.length > 0;
    bool addressTypeValid = selectedAddressType!= null;
    bool _address2Valid = _address2valueValid();
    bool cityValid = _city != null && _city.length >0;
    final nondigitRegExp = new RegExp(r"\D");
    bool zipValid = _zip != null
        && _zip.length == _zip.replaceAll(nondigitRegExp, "").length;
    bool cardValid = _selectedCard != null;
    bool _apartmentValid = _apartmentNameValid();
    bool _uniqueIdValid = _cardUniqueIdValid();
    bool _paymentValid = _paymentMethodValid();
    return addressValid && zipValid && cardValid && addressTypeValid && _address2Valid && cityValid && _apartmentValid && _uniqueIdValid && _paymentValid;
  }

  bool _apartmentNameValid() {
    if(selectedAddressType != null) {
      if (selectedAddressType.id == 14) {
        if(_apartmentName !=null){
          return _apartmentName.length > 0;
        }
      } else if (selectedAddressType.id == 13) {
        return true;
      }
    }
  }

  bool _paymentMethodValid() {
    if (showPaymentWarning == true){
      return false;
    } else {
      return true;
    }

  }

  bool _cardUniqueIdValid() {
      if (_selectedCard == "BAMA Cash" || _selectedCard == "DD"){
        if(_uniqueIdController !=null){
          return _uniqueIdController.text.length >= 8 && _uniqueIdController.text.length <= 19;
        }else{
          return false;
        }
      } else {
        return true;
      }
  }

  bool _address2valueValid() {
    if(selectedAddressType != null) {
      if (selectedAddressType.id == 14) {
        if(_address2 !=null) {
          return _address2.length > 0;
        }
      } else if (selectedAddressType.id == 13) {
        return true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = new TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold);
    final shippingCost = _shippingMethod == null
        ? 0.0
        : _shippingMethod.cost.toDouble();

    // get number of cents, rounded, then convert to dollars
    final shippingTax = (shippingCost * 100 * TAX_RATE).round()/100.0;

    final buttonText = _isFormValid() ? "Place Order" : "Complete Form to Order";

    if(_guestUser == false) {
      if (_cardLoading || _addressLoading) {
        return new LoadingScreen();
      }
    }

    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Checkout"),
        ),
        body: new GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(new FocusNode());
          },
          child: new Container(
            child: new ListView(
              padding: new EdgeInsets.symmetric(horizontal: 0.0, vertical: 15.0),
              children: <Widget>[
                new Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: new Column(
                    children: <Widget>[
                      new Container(
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _guestUser ? new Container() : new Text("Select Delivery Address", style: titleStyle),
                            _guestUser ? new Container() : new DropdownButton(
                              items: _addressList(),
                              onChanged: (value) => _setAddress(value),
                              value: _selectedAddress,
                            ),
                            _guestUser ? new Text("Your Address", style: titleStyle) : new Text("- OR -\nEnter New Address", style: titleStyle),
                            new InputDecorator(
                              decoration: const InputDecoration(
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
                                      }else if(selectedAddressType.id == 13) {
                                        showApartment = false;
                                        _apartmentName = "";
                                        _address2 = "";
                                      }
                                      if(_guestUser == false && updateUser == false) {
                                        _selectedAddress = null;
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
                              controller: _apartmentNameController,
                              decoration: new InputDecoration(
                                  labelText: 'Apartment Name'
                              ),
                              onChanged: (value) => setState(() {
                                _apartmentName = value;
                                if(_guestUser == false && updateUser == false) {
                                  _selectedAddress = null;
                                }
                              }),
                            ): new Container(),
                            new TextField(
                              controller: _addressController,
                              decoration: new InputDecoration(
                                  labelText: 'Address'
                              ),
                              onChanged: (value) => setState(() {
                                _address1 = value;
                                if(_guestUser == false && updateUser == false) {
                                  _selectedAddress = null;
                                }
                              }),
                            ),
                            showApartment ? new TextField(
                              controller: _address2Controller,
                              decoration: new InputDecoration(
                                  labelText: 'Suite/Apt #'
                              ),
                              onChanged: (value) => setState(() {
                                _address2 = value;
                                if(_guestUser == false && updateUser == false) {
                                  _selectedAddress = null;
                                }
                              }),
                            ): new Container(),
                            new TextField(
                              controller: _cityController,
                              decoration: new InputDecoration(
                                  labelText: 'City'
                              ),
                              onChanged: (value) => setState(() {
                                _city = value;
                                if(_guestUser == false && updateUser == false) {
                                  _selectedAddress = null;
                                }
                              }),
                            ),
                          ],
                        ),
                      ),
                      new Container(
                        padding: new EdgeInsets.only(bottom: 10.0),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new TextField(
                                controller: _zipController,
                                keyboardType: TextInputType.number,
                                decoration: new InputDecoration(
                                    labelText: 'Zip Code'
                                ),
                                onChanged: (value) => setState(() {
                                  _zip = value;
                                  if(_guestUser == false && updateUser == false) {
                                    _selectedAddress = null;
                                  }
                                })
                            ),
                          ],
                        ),
                      ),
                      _addressAvailable ? new Container(
                        padding: new EdgeInsets.only(bottom: 10.0),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            new RaisedButton(
                              color: UgoGreen,
                              child: new Text('Clear & Add New Address',style: new TextStyle(fontSize: 18.0, color: Colors.white)),
                              onPressed: _clearAddress,
                            ),
                          ],
                        ),
                      ): new Container(),
                      new Container(
                        padding: new EdgeInsets.only(bottom: 20.0),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Text("Payment Method", style: titleStyle),
                            new Row(
                                children: [
                                  new DropdownButton(
                                      items: _cardList(),
                                      value: _selectedCard,
                                      //onChanged: (value) => setState(() => _selectedCard = value)
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCard  = value;
                                          if(_selectedCard == "BAMA Cash" || _selectedCard == "DD") {
                                            showuniqueId = true;
                                          }else{
                                            showuniqueId = false;
                                            _uniqueId = " ";
                                          }
                                          if(_selectedCard == "DD"){
                                            forbiddenCheck();
                                          }else{
                                            showPaymentWarning = false;
                                          }
                                        });
                                      },
                                  ),
                                  new Expanded(
                                      child: new Container()
                                  ),
                                  new RaisedButton(
                                    color: UgoGreen,
                                    onPressed: _ordering
                                        ? null
                                        : () {
                                      Navigator.push(context,
                                          new MaterialPageRoute(
                                              builder: (BuildContext context) => new AddCardPage())
                                      ).then((newCard) {
                                        if (newCard != null && newCard.runtimeType == PaymentCard) {
                                          var updatedCards = _cards;
                                          updatedCards.add(newCard);
                                          setState(() => _cards = updatedCards);
                                        }
                                      });
                                    },
                                    padding: new EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
                                    child: new Text("Add New Card", style: new TextStyle(fontSize: 18.0, color: Colors.white)),
                                  ),
                                ]
                            )
                          ],
                        ),
                      ),
                      showPaymentWarning ? new Container(
                        padding: new EdgeInsets.only(bottom: 10.0),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            new Text(paymentWarning, style: new TextStyle(fontSize: 11.0, color: msgColor)),
                          ],
                        ),
                      ): new Container(),
                      showuniqueId ? new Container(
                        padding: new EdgeInsets.only(bottom: 10.0),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Text("Enter CWID#", style: titleStyle),
                             new TextField(
                              controller: _uniqueIdController,
                              decoration: new InputDecoration(
                                  labelText: 'CWID'
                              ),
                               maxLength: 19,
                            ),
                          ],
                        ),
                      ): new Container(),
                      new Container(
                        padding: new EdgeInsets.only(bottom: 10.0),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Text("Use Coupon Code", style: titleStyle),
                            _showGuestCoupon ? new TextField(
                              controller: _couponCodeController,
                              onChanged: (value) => setState(() => guestRegCoupon = value),

                            ): new TextField(
                              controller: _couponCodeController,
                              decoration: new InputDecoration(
                                  labelText: 'Coupon Code'
                              ),
                            ),
                          ],
                        ),
                      ),
                      new Container(
                        padding: new EdgeInsets.only(bottom: 10.0),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            new RaisedButton(
                              color: UgoGreen,
                              child: new Text('Apply Coupon Code',style: new TextStyle(fontSize: 18.0, color: Colors.white)),
                              onPressed: _isButtonDisabled ? null : _guestUser ? _isGuestCouponValid :_isCouponValid,
                            ),
                          ],
                        ),
                      ),
                      new Container(
                        padding: new EdgeInsets.only(bottom: 10.0),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            new Text(couponMessage, style: new TextStyle(fontSize: 11.0, color: msgColor)),
                          ],
                        ),
                      ),
                      _showRewardPoint ? new Container(
                        padding: new EdgeInsets.only(bottom: 10.0),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Text("Use Reward Points (Available ${_rewardTotal})", style: titleStyle),
                            new TextField(
                              controller: _rewardPointController,
                              decoration: new InputDecoration(
                                  labelText: 'Points to use (Max ${_maxPointUse})'
                              ),
                            ),
                          ],
                        ),
                      ): new Container(),
                      _showRewardPoint ? new Container(
                        padding: new EdgeInsets.only(bottom: 10.0),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            new RaisedButton(
                              color: UgoGreen,
                              child: new Text('Apply reward points',style: new TextStyle(fontSize: 18.0, color: Colors.white)),
                              onPressed: _isRewardButtonDisabled ? null : _isRewardPointValid,
                            ),
                          ],
                        ),
                      ): new Container(),
                      new Container(
                        padding: new EdgeInsets.only(bottom: 10.0),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            new Text(rewardMessage, style: new TextStyle(fontSize: 11.0, color: msgColor)),
                          ],
                        ),
                      ),
                      new Container(
                        padding: new EdgeInsets.only(bottom: 20.0),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: new Text("Additional Comments", style: titleStyle,),
                            ),
                            new TextField(
                              controller: _commentController,
                              maxLines: 7,
                              onChanged: (value) => setState(() => _userComment = value),
                              decoration: new InputDecoration(
                                  hintText: "Add special delivery instructions\nhere, if needed.",
                                  border: new OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.all(8.0)
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
//              new Divider(color: Colors.black, height: 0.0,),
                new LinearProgressIndicator(value: _orderProcess, backgroundColor: Colors.grey[300],),
                new Container(
                  padding: new EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: new Column(
                    children: <Widget>[
                      _totalRow("Cart (Including Tip)", "Sub-Total"),
                      _totalRow("Low Order Fee", "Low Order Fee"),
                      _shippingRow(),
                      _coupounCodeRow(),
                      _totalRow("Sales Tax", "Sales Tax", addedAmount: (shippingTax - _couponTax - _rewardPointTax)),
                      _totalRow("Store Credit", "Store Credit",addedAmount: shippingTax + shippingCost -_rewardPointTax),
                      _rewardPointRow(),
                      _totalRow("Total", "Total", addedAmount: (shippingCost+shippingTax -_rewardPointTax)),
                    ],
                  ),
                ),
                new Container(
                  margin: new EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 20.0),
                  child: new Builder(
                    builder: (BuildContext context) {
                      return new Row(
                        children: <Widget>[
                          new Expanded(
                              child: new RaisedButton(
                                  onPressed: _isFormValid() && !_ordering ?
                                      () {
                                    setState(() => _navContext = context);
                                    _placeOrder(context);
                                  }
                                      : null,
                                  color: UgoGreen,
                                  child: new Text(buttonText, style: new TextStyle(fontSize: 18.0, color: Colors.white))
                              )
                          ),
                        ],
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        )
    );
  }
}

class CheckoutTotalRow extends StatelessWidget {
  final String title;
  final double amount;

  CheckoutTotalRow(this.title, this.amount);

  @override
  Widget build(BuildContext context) {
    final style = new TextStyle(fontSize: 18.0);

    return new Container(
      child: new Column(
        children: <Widget>[
          new Container(
              margin: new EdgeInsets.fromLTRB(30.0, .0, 30.0, 5.0),
              child: new Row(
                children: <Widget>[
                  new Text(title, style: style),
                  new Expanded(child: new Container()),
                  new Text('\$$amount', style: style)
                ],
              )
          )
        ],
      ),
    );
  }
}

