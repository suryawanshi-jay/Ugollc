import 'package:flutter/material.dart';
import 'package:ugo_flutter/pages/registration_page.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/pages/guest_details.dart';
import 'package:ugo_flutter/models/cart.dart';
import 'package:ugo_flutter/models/shipping_method.dart';
import 'package:ugo_flutter/pages/guest_details.dart';




class GuestMsgPage extends StatefulWidget {
  final List<CartTotal> cartTotals;
  final ShippingMethod shippingMethod;

  GuestMsgPage(this.cartTotals, this.shippingMethod);

  @override
  _GuestMsgPageState createState() => new _GuestMsgPageState();
}

class _GuestMsgPageState extends State<GuestMsgPage> {
  final Function() setupCart;
  @override
  Widget build (BuildContext ctxt) {
    String regText = "Register Now";
    Widget regRoute = new RegistrationPage();
    String guestCheckoutText = "Continue as Guest User";
    Widget guestCheckoutRoute = new GuestDetailsPage(widget.cartTotals, widget.shippingMethod,true);
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Guest Checkout"),
      ),
      body: new Container (
        child: new Column(
          children: <Widget>[
            new Container(
              padding: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              child:new Row(
                children: <Widget>[
                new SizedBox(width: 330.0,height: 180.0, child : new Text("If you register your account, you will get an instant coupon for additional 10% off on your order",style: new TextStyle(fontSize: 25.0,fontWeight: FontWeight.bold,color:Colors.green ), textAlign: TextAlign.center,)),
              ])
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
                                builder: (BuildContext context) => regRoute,
                            )
                        );
                      },
                      color: UgoGreen,
                      child: new Text(regText, style: new TextStyle(fontSize: 18.0, color: Colors.white)),
                    )
                  )
                ],
              )
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
                                builder: (BuildContext context) => guestCheckoutRoute,
                              )
                          );
                        },
                        color: UgoGreen,
                        child: new Text(guestCheckoutText, style: new TextStyle(fontSize: 18.0, color: Colors.white)),
                      )
                    )
                  ],
                )
            ),
          ],
        ),
      ),
    );
  }
}
