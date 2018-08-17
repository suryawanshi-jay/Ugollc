import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
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


class CheckoutPage extends StatefulWidget {
  final List<CartTotal> cartTotals;
  final ShippingMethod shippingMethod;

  CheckoutPage(this.cartTotals, this.shippingMethod);

  @override
  _CheckoutPageState createState() => new _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _cardLoading = false;
  bool _addressLoading = false;
  bool _ordering = false;
  double _orderProcess = 0.0;
  bool _isCouponCodeValid = false;
  double _couponCodeAmount = 0.0;
  bool _isButtonDisabled;
  String couponMessage = '';
  String couponCodeType = '';
  double couponValue = 0.0;



  List<PaymentCard> _cards = [];
  String _selectedCard;

  List<Address> _addresses = [];
  int _selectedAddress;

  String _address1;
  String _zip;

  TextEditingController _addressController = new TextEditingController();
  TextEditingController _zipController = new TextEditingController();
  TextEditingController _commentController = new TextEditingController();
  TextEditingController _couponCodeController = new TextEditingController();

  ShippingMethod _shippingMethod;
  List<CartTotal> _totals;

  BuildContext _navContext;

  String _userComment;

  final _analytics = new FirebaseAnalytics();

  @override
  initState() {
    super.initState();
    _totals = widget.cartTotals;
    _shippingMethod = widget.shippingMethod;
    _cardLoading = true;
    _addressLoading = true;
    _isButtonDisabled = false;
    _logCheckout();
    _getCards();
    _getAddresses();
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
//    _geocodeNewAddress();
//    return;
    setState(() => _orderProcess = 0.0);
    setState(() => _ordering = true);
    _submitPaymentAddress(context);
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

  _submitExistingShippingAddress(BuildContext context) {
    setState(() => _orderProcess = 0.3);
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

  _geocodeNewAddress(BuildContext context) {
    setState(() => _orderProcess = 0.2);
    final addrString = "$_address1, $_zip".replaceAll(" ", "+");
    ApiManager.request(
      GoogleResources.GET_COORDS,
      (json) async {
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
        final List componentList = json["results"].first["address_components"];
        componentList.forEach((comp) {
          final type = comp["types"].first;
          addressComponents[type] = comp["short_name"];
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.getString(PreferenceNames.USER_FIRST_NAME);

        final ocAddr = {
          "firstname": prefs.getString(PreferenceNames.USER_FIRST_NAME),
          "lastname": prefs.getString(PreferenceNames.USER_LAST_NAME),
          "address_1": "${addressComponents["street_number"]} ${addressComponents["route"]}",
          "city": addressComponents["locality"],
          "postcode": addressComponents["postal_code"],
          "country_id": "223",
          "zone_id": "3613",
          "shipping_address": "new"
        };

        _submitNewShippingAddress(ocAddr, context);
      },
      resourceID: addrString,
      errorHandler: (error) {
        setState(() => _orderProcess = 0.0);
        setState(() => _ordering = false);
        ApiManager.defaultErrorHandler(error, context: context);
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
          "shipping_method": _shippingMethod.id.toString()
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
          _submitPayment("cod", "Cash on Delivery", context);
        } else if (_selectedCard != null) {
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
    double shippingCost = 0.0;
    if (_shippingMethod != null && _shippingMethod.cost != null) {
      shippingCost = _shippingMethod.cost.toDouble();
      final shippingTax = (shippingCost * 100 * TAX_RATE).round()/100.0;
      shippingCost += shippingTax;
    }

    final double floatTotal = double.parse(cleanTotal) + shippingCost;
    return (floatTotal * 100.0).toInt();
  }

  // POST PAYMENT METHOD (stripe or cod)
  // INCLUDE STRIPE TRANSACTION ID (IF STRIPE)
  _submitPayment(String method, String comment, BuildContext context) {
    setState(() => _orderProcess = 0.7);
    var commentText = comment;
    if (_userComment != null) {
      commentText = "$_userComment\n\n$comment";
    }

    ApiManager.request(
      OCResources.POST_PAYMENT_METHOD,
      (json) {
        _confirmOrder(context);
      },
      params: {
        "payment_method": method,
        "comment": commentText
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

  // GET CONFIRM
  _confirmOrder(BuildContext context) {
    setState(() => _orderProcess = 0.8);
    ApiManager.request(
      OCResources.GET_CONFIRM,
       // (json) => _orderPaid(context),
       (json){
         _orderPaid(context);
         var orderId = json["order_id"];
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
        (json) => _orderSuccess(context),
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
    setState(() {
      _selectedAddress = addressID;
      _address1 = pickedAddr.address1;
      _zip = pickedAddr.zip;
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
        addedAmount = -_couponCodeAmount;
    }
    return new Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        new Text(
          "$text: \$${(total + addedAmount).toStringAsFixed(2)}",
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

  void _isCouponValid() {
    var couponCodeValue = _couponCodeController.text;
    // Give call coupon code api and get validity and coupon value from it
    ApiManager.request(
        OCResources.POST_COUPON_DETAILS,
            (json) {
          String status = json["status"];
          if(status == "valid"){
            setState(() => _couponCodeAmount = double.parse(json["discount"]));
            setState(() => _isButtonDisabled = true);
            setState(() => couponMessage = json["success"]);
            setState(() => couponCodeType = json["type"]);
            if(couponCodeType == "P"){
              final CartTotal subTotal = _totals.where((total) => total.title == "Sub-Total").first;
              final String clnTotal = subTotal.text.replaceAll(PRICE_REGEXP, "");
              double reduceAmount = (double.parse(clnTotal) * _couponCodeAmount).round() / 100 ;
              setState(() => _couponCodeAmount = reduceAmount);
            }else{
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

  Row _coupounCodeRow() {
    if (_isCouponCodeValid == false) {
      return new Row();
    }
    var text = "Coupon Value : -\$$_couponCodeAmount";

    return new Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        new Text(text, style: new TextStyle(fontSize: 18.0))
      ],
    );
  }

  bool _isFormValid() {
    bool addressValid = _address1 != null && _address1.length > 0;
    final nondigitRegExp = new RegExp(r"\D");
    bool zipValid = _zip != null
      && _zip.length == _zip.replaceAll(nondigitRegExp, "").length;
    bool cardValid = _selectedCard != null;
    return addressValid && zipValid && cardValid;
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

    if (_cardLoading || _addressLoading) {
      return new LoadingScreen();
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
                          new Text("Select Delivery Address", style: titleStyle),
                          new DropdownButton(
                            items: _addressList(),
                            onChanged: (value) => _setAddress(value),
                            value: _selectedAddress,
                          ),
                          new Text("- OR -\nEnter New Address", style: titleStyle),
                          new TextField(
                            controller: _addressController,
                            decoration: new InputDecoration(
                              labelText: 'Address'
                            ),
                            onChanged: (value) => setState(() {
                              _address1 = value;
                              _selectedAddress = null;
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
                              labelText: 'Zip'
                            ),
                            onChanged: (value) => setState(() => _zip = value),
                          ),
                        ],
                      ),
                    ),
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
                                onChanged: (value) => setState(() => _selectedCard = value)
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
                                child: new Text("Add New Card", style: new TextStyle(fontSize: 18.0, color: Colors.white)),
                              ),
                            ]
                          )
                        ],
                      ),
                    ),
                    new Container(
                      padding: new EdgeInsets.only(bottom: 10.0),
                      child: new Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          new Text("Use Coupon Code", style: titleStyle),
                          new TextField(
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
                            onPressed: _isButtonDisabled ? null : _isCouponValid,
                          ),
                        ],
                      ),
                    ),
                    new Container(
                      padding: new EdgeInsets.only(bottom: 10.0),
                      child: new Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          new Text(couponMessage, style: new TextStyle(fontSize: 11.0, color: Colors.red)),
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
                    _totalRow("Sales Tax", "Sales Tax", addedAmount: shippingTax),
                    _totalRow("Total", "Total", addedAmount: (shippingCost+shippingTax)),
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

