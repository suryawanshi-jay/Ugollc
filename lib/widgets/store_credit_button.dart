import 'package:flutter/material.dart';
import 'package:ugo_flutter/models/cart.dart';
import 'package:ugo_flutter/pages/purchase_credit.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/pages/home_page.dart';

class StoreCreditButton extends StatefulWidget {
  final double credits;
  final Cart cart;
  StoreCreditButton(this.credits,this.cart);

  @override
  _StoreCreditButtonState createState() => new _StoreCreditButtonState();
}

class _StoreCreditButtonState extends State<StoreCreditButton> {
  @override

  bool showAlert = false;

  _onStoreCreditClick(){
    Navigator.push(context,
        new MaterialPageRoute(
            builder: (BuildContext context) => new PurchaseCreditPage())
    );
  }

  Widget build(BuildContext context) {
    final _cartCount = widget.credits == null ? 0.00 : widget.credits;
    final _cartText = _cartCount.toStringAsFixed(2);
    final _cartPadding = _cartCount > 0 ? 4.0 : 0.0;
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
              showAlert ? new Text("Empty your cart\nfirst", style: new TextStyle(color: Colors.red, fontSize: 10.0)) : new Text("\$${_cartText}", style: new TextStyle(color: UgoGreen, fontSize: 13.0)),
              new Icon(Icons.add_circle, color: UgoGreen,),
              new Padding(padding: new EdgeInsets.only(left: _cartPadding),),
            ]
        ),
      ),
      onTap: () => _onStoreCreditClick(),
    );
  }
}
