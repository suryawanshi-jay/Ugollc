import 'package:flutter/material.dart';
import 'package:ugo_flutter/models/cart.dart';
import 'package:ugo_flutter/pages/cart_page.dart';
import 'package:ugo_flutter/utilities/constants.dart';

class CartButton extends StatefulWidget {
  final Cart cart;
  final Function(dynamic) updateCart;

  CartButton(this.cart, {this.updateCart});

  @override
  _CartButtonState createState() => new _CartButtonState();
}

class _CartButtonState extends State<CartButton> {
  @override
  Widget build(BuildContext context) {
    final _cartCount = widget.cart == null ? 0 : widget.cart.nonTipCount();
    final _cartText = _cartCount > 0 ? "$_cartCount" : "";
    final _cartPadding = _cartCount > 0 ? 5.0 : 0.0;
    return new GestureDetector(
      child: new Container(
        margin: new EdgeInsets.all(10.0),
        padding: new EdgeInsets.symmetric(horizontal: 15.0),
        decoration: new BoxDecoration(
          color: Colors.white,
          borderRadius: new BorderRadius.all(const Radius.circular(20.0)),
        ),
        child: new Row(
          children: <Widget>[
            new Text("$_cartText", style: new TextStyle(color: UgoGreen, fontSize: 18.0)),
            new Padding(padding: new EdgeInsets.only(left: _cartPadding),),
            new Icon(Icons.shopping_cart, color: UgoGreen,)
          ]
        ),
      ),
      onTap: () {
        Navigator.push(context,
          new MaterialPageRoute(
            builder: (BuildContext context) => new CartPage(updateCart: widget.updateCart,))
        );
      },
    );
  }
}
