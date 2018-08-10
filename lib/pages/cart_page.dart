import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:ugo_flutter/models/cart.dart';
import 'package:ugo_flutter/models/shipping_method.dart';
import 'package:ugo_flutter/pages/checkout_page.dart';
import 'package:ugo_flutter/pages/loading_screen.dart';
import 'package:ugo_flutter/pages/login_page.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';

class CartPage extends StatefulWidget {
  final Function(dynamic) updateCart;

  CartPage({this.updateCart});

  @override
  _CartPageState createState() => new _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Cart _cart;
  double _tip;
  Map<String, ShippingMethod> _shippingMethods = {};
  ShippingMethod _shippingMethod;
  bool _loggedIn = false;
  Timer _timer;
  String _cartError;

  final _analytics = new FirebaseAnalytics();

  @override
  initState() {
    super.initState();
    _tip = 0.0;
    _setup();
  }

  @override
  dispose() {
    if (_timer != null && _timer.isActive) {
      _timer.cancel();
    }
    super.dispose();
  }

  _setup() {
    PrefsManager.getString(PreferenceNames.USER_EMAIL).then((value) =>
      setState(() => _loggedIn = (value != null && value != "")));
    _iscouponApplied();
    //_getShippingMethods();
    //_getCart();
  }

  _getCart() {
    ApiManager.request(
      OCResources.GET_CART,
        (json) {
        setState(() => _cart = new Cart.fromJSON(json["cart"]));
        final tips = _cartTips();
        if (tips.length > 0) {
          setState(() => _tip = tips.first.quantity.toDouble());
        }
        if(widget.updateCart != null) {
          widget.updateCart(json);
        }
      },
      errorHandler: (json) {
        setState(() => _cartError = json["errors"].first["message"]);
      }
    );
  }

  _getShippingMethods() {
    ApiManager.request(
      OCResources.GET_SHIPPING_METHODS,
        (json) {
          var methods = {};
        json["shipping_methods"].forEach((item) {
          final method = new ShippingMethod.fromJSON(item);
          methods[method.id] = method;
        });
        setState(() => _shippingMethods = methods);
        if (_cart != null) {
          _setShippingMethod();
        }
      }
    );
  }

  updateProductQuantity(String key, int quantity) {
    ApiManager.request(
      OCResources.PUT_CART_PRODUCT,
      (json) async {
        setState(() => _cart = new Cart.fromJSON(json["cart"]));
        _getShippingMethods();
        if(widget.updateCart != null) {
          widget.updateCart(json);
        }
        _setShippingMethod();
        await _analytics.logEvent(name: "update_product_quantity", parameters: {
          "productID": key,
          "quantity": quantity
        });
      },
      params: { key: quantity.toString() },
    );
  }

  deleteProduct(String key) {
    ApiManager.request(
      OCResources.DELETE_CART_PRODUCT,
      (json) async {
        final updatedCart = new Cart.fromJSON(json["cart"]);
        setState(() => _cart = updatedCart);
        _getShippingMethods();
        if(widget.updateCart != null) {
          widget.updateCart(json);
        }
        _setShippingMethod();

        await _analytics.logEvent(name: "remove_cart_product", parameters: {
          "productID": key,
        });
      },
      resourceID: key
    );
  }

  List<CartProduct> _cartTips() =>
    _cart.products.where(
        (CartProduct product) =>
          product.name == DRIVER_TIP_NAME
    ).toList();

  _setupTimer() {
    if(_timer != null && _timer.isActive) {
      _timer.cancel();
    }
    final duration = const Duration(milliseconds: 300);
    _timer = new Timer(duration, _pushTip);
  }
  
  updateTip(double value) {
    if (value != _tip) {
      setState(() => _tip = value);
      _setupTimer();
    }
  }

  _pushTip() {
    final quantity = _tip.round();
    List<CartProduct> _tips = _cartTips();
    if (_tips.length > 0) {
      CartProduct tip = _tips.first;
      updateProductQuantity(tip.key, quantity);
    } else {
      _addTip(quantity);
    }
  }

  _addTip(int value) {
    ApiManager.request(
      OCResources.ADD_CART_PRODUCT,
      (json) {
        final updatedCart = new Cart.fromJSON(json["cart"]);
        setState(() => _cart = updatedCart);
        if(widget.updateCart != null) {
          widget.updateCart(json);
        }
        _setShippingMethod();
      },
      params: {
        "product_id": DRIVER_TIP_ID,
        "quantity": value.toString()
      }
    );
  }

  double _subtotal() {
    if (_cart != null && _cart.totals.length > 0) {
      final _subtotals = _cart.totals.where((total) => total.title == "Sub-Total").toList();
      if (_subtotals.length > 0) {
        final subtotal = _subtotals.first.text;
        return double.parse(subtotal.replaceAll(PRICE_REGEXP, ""));
      }
    }
    return 0.0;
  }

  _setShippingMethod() {
    if (_timer == null || !_timer.isActive) {
      ShippingMethod method;
      if (_shippingMethods != null && _shippingMethods.length > 0) {
        if ((_subtotal() - _tip) > MIN_FREE_SHIPPING) {
          method =
            _shippingMethods["free.free"] ?? _shippingMethods["flat.flat"];
        } else {
          method = _shippingMethods["flat.flat"] ?? null;
        }
      }
      setState(() => _shippingMethod = method);
    }
  }

  void _iscouponApplied(){
    // Give call coupon code api and get validity and coupon value from it
    ApiManager.request(
        OCResources.GET_CART,
            (json) {
          var status = json["cart"]["coupon_status"];
          if(status){
            // Remove coupon details from cart
            ApiManager.request(
                OCResources.POST_CLEAR_COUPON,
                    (json) {
                      _getShippingMethods();
                      _getCart();
                },
                errorHandler: (error) {
                  ApiManager.defaultErrorHandler(error, context: context);
                }
            );
          }
        },
        errorHandler: (error) {
          ApiManager.defaultErrorHandler(error, context: context);
        }
    );
  }

  Scaffold _cartScaffold() {
    var _productList = [];
    var _totals = [];
    if (_cart != null) {
      _cart.products.forEach((product) {
        if (product.name != DRIVER_TIP_NAME) {
          _productList.add(new CartProductRow(product, updateProductQuantity, deleteProduct));
          _productList.add(new Divider(color: Colors.grey[800], height: 0.0,));
        }
      });
      _totals = _cart.totals;
    }

    if (_productList.length > 0) {
      _productList.add(new Padding(
        padding: new EdgeInsets.only(top: 5.0),
        child: new Text(
          "Swipe left to remove items from cart",
          textAlign: TextAlign.center,
          style: new TextStyle(color: Colors.grey[800], fontSize: 12.0),
        )
      ));
    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Cart"),
      ),
      body: new Container(
        color: Colors.white,
        child: new Column(
          children: <Widget>[
            new Expanded(
              child: new ListView(
                children: _productList,
              ),
            ),
            new CartTotalRow(_totals, _tip, updateTip, _shippingMethod, _setup, loggedIn: _loggedIn,)
          ],
        ),
      )
    );
  }

  Scaffold _errorScaffold() {
    var center = new Container();
    if (_cartError != null) {
      center = new Container(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(
              _cartError,
              style: new TextStyle(fontSize: 24.0, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return new Scaffold(
      appBar: new AppBar(
        title: new Image.asset("assets/images/ugo_logo.png"),
      ),
      body: new Container(
        padding: new EdgeInsets.symmetric(horizontal: 50.0),
        color: Colors.white,
        child: center,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cartError != null) {
      return _errorScaffold();
    }
    if (_cart == null && _shippingMethods == null) {
      return new LoadingScreen(loadingText: "LOADING CART . . .",);
    }

    _setShippingMethod();

    return _cartScaffold();
  }
}

class CartProductRow extends StatelessWidget {
  final CartProduct product;
  final Function(String key, int quantity) updateQuantity;
  final Function(String key) deleteProduct;

  CartProductRow(this.product, this.updateQuantity, this.deleteProduct);

  @override
  Widget build(BuildContext context) {
    Widget image = new Placeholder();
    if (product.thumbImage != null) {
      image = new Image.network(product.thumbImage);
    }

    var decreaseQuantity;
    if (product.quantity > 1) {
      decreaseQuantity = () => updateQuantity(product.key, product.quantity-1);
    }

    return new Dismissible(
      key: new Key(product.key),
      onDismissed: (direction) => deleteProduct(product.key),
      direction: DismissDirection.endToStart,
      background: new Container(
        padding: new EdgeInsets.only(right: 16.0),
        color: Colors.red,
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            new Icon(
              Icons.chevron_left,
              size: 48.0,
              color: Colors.white.withAlpha(175),
            ),
            new Icon(
              Icons.delete_forever,
              color: Colors.white.withAlpha(175),
              size: 64.0,
            ),
          ],
        ),
      ),
      child: new Container(
//      color: Colors.red,
        margin: new EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
        child: new Row(
          children: <Widget>[
            new SizedBox(
              height: 80.0,
              width: 80.0,
              child: new AspectRatio(
                aspectRatio: 1.0,
                child: image,
              ),
            ),
            new Expanded(
              child: new Container(
                margin: new EdgeInsets.only(left: 10.0),
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Text(
                      product.name,
                      style: new TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    new Padding(
                      padding: new EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 0.0
                      ),
                      child: new Text(product.model),
                    ),
                    new Text(product.price),
                  ],
                ),
              ),
            ),
            new Column(
              children: <Widget>[
                new IconButton(
                  icon: new Icon(Icons.keyboard_arrow_up),
                  padding: new EdgeInsets.all(4.0),
                  onPressed: () => updateQuantity(product.key, product.quantity+1),
                  iconSize: 35.0,
                  color: UgoGreen,
                ),
                new Text(product.quantity.toString(), style: new TextStyle(fontSize: 24.0),),
                new IconButton(
                  icon: new Icon(Icons.keyboard_arrow_down),
                  padding: new EdgeInsets.all(4.0),
                  onPressed: decreaseQuantity,
                  iconSize: 35.0,
                  color: UgoGreen,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class CartTotalRow extends StatelessWidget {
  final List<CartTotal> cartTotals;
  final double tipAmount;
  final Function(double value) onChangeTip;
  final Function() setupCart;
  final ShippingMethod shippingMethod;
  final bool loggedIn;

  CartTotalRow(
    this.cartTotals,
    this.tipAmount,
    this.onChangeTip,
    this.shippingMethod,
    this.setupCart,
    {
      this.loggedIn: false
    }
  );

//  double _totalType(String type) {
//    if (cartTotals == null) {
//      return 0.0;
//    }
//    final totals = cartTotals.where((total) => total.title == type);
//    if (totals.length > 0) {
//      return double.parse(totals.first.text.replaceAll(PRICE_REGEXP, ""));
//    }
//    return 0.0;
//  }

  Widget _totalRow(String text, String type, {double addedAmount: 0.0}) {
    if (cartTotals == null) {
      return new Container();
    }

    final totals = cartTotals.where((total) => total.title == type);
    if (totals == null || totals.length == 0) {
      return new Container();
    }

    final total = double.parse(totals.first.text.replaceAll(PRICE_REGEXP, ""));

    return new Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        new Text(
          "$text: \$${(total + addedAmount).toStringAsFixed(2)}",
          style: new TextStyle(fontSize: 18.0),)
      ],
    );
  }

  Widget _shippingRow() {
    if (shippingMethod == null) {
      return new Container();
    }

    var text = "Delivery Charge: ${shippingMethod.displayCost}";
    if (shippingMethod.cost == 0) {
      text = "FREE DELIVERY!";
    }
    return new Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        new Text(text, style: new TextStyle(fontSize: 18.0))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String checkoutText;
    Widget checkoutRoute;

    if (loggedIn) {
      checkoutText = "Proceed to Checkout";
      checkoutRoute = new CheckoutPage(cartTotals, shippingMethod);
    } else {
      checkoutText = "Log In to Checkout";
      checkoutRoute = new LoginPage();
    }

    final shippingCost = shippingMethod == null
      ? 0.0
      : shippingMethod.cost.toDouble();

    // get number of cents, rounded, then convert to dollars
    final shippingTax = (shippingCost * 100 * TAX_RATE).round()/100.0;

    var tipIcon;

    if (tipAmount > 3.5) {
      tipIcon = Icons.sentiment_very_satisfied;
    } else if (tipAmount > 0.5) {
      tipIcon = Icons.sentiment_satisfied;
    }

    return new Container(
      child: new Column(
        children: <Widget>[
          new Divider(color: Colors.black, height: 0.0,),
          new Container(
            padding: new EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
            child: new Row(
              children: <Widget>[
                new Text("Driver Tip", style: new TextStyle(fontSize: 18.0),),
                new Expanded(
                  child: new Slider(
                    value: tipAmount,
                    onChanged: (value) => onChangeTip(value),
                    divisions: 10,
                    max: 10.0,
                  )
                ),
                new Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 4.0),
                  child: new Icon(
                    tipIcon,
                    color: UgoGreen,
                    size: 30.0,
                  ),
                ),
                new Text("\$${tipAmount.toStringAsFixed(2)}", style: new TextStyle(fontSize: 18.0),),
              ],
            ),
          ),
          new Container(
            padding: new EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: new Column(
              children: <Widget>[
                _totalRow("Cart (Including Tip)", "Sub-Total"),
                _totalRow("Low Order Fee", "Low Order Fee"),
                _shippingRow(),
                _totalRow("Sales Tax", "Sales Tax", addedAmount: shippingTax),
                _totalRow("Total", "Total", addedAmount: (shippingCost+shippingTax)),
              ],
            ),
          ),

          new Container(
            padding: new EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
            child: new Row(
              children: <Widget>[
                new Expanded(
                  child: new RaisedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        new MaterialPageRoute(
                          builder: (BuildContext context) => checkoutRoute
                        )
                      ).then((value) => setupCart());
                    },
                    color: UgoGreen,
                    child: new Text(checkoutText, style: new TextStyle(fontSize: 18.0, color: Colors.white)),
                  )
                )
              ],
            )
          ),
        ],
      ),
    );
  }
}
