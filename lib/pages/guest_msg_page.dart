import 'package:flutter/material.dart';
import 'package:ugo_flutter/pages/registration_page.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/pages/guest_details.dart';
import 'package:ugo_flutter/models/cart.dart';
import 'package:ugo_flutter/models/shipping_method.dart';
import 'package:ugo_flutter/pages/guest_details.dart';
import 'package:shared_preferences/shared_preferences.dart';



class GuestMsgPage extends StatefulWidget {
  final List<CartTotal> cartTotals;
  final ShippingMethod shippingMethod;
  final double tipAmount;

  GuestMsgPage(this.cartTotals,this.tipAmount,this.shippingMethod);

  @override
  _GuestMsgPageState createState() => new _GuestMsgPageState();
}

class _GuestMsgPageState extends State<GuestMsgPage> {

  String guestRegCoupon;

  void _regGuestUser(BuildContext context) async{
    setState(() => guestRegCoupon = "REGISTER10");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(PreferenceNames.GUEST_REG_COUPON, guestRegCoupon);
    _regPage();
  }

  _regPage(){
    Widget checkoutRoute = new RegistrationPage();
    Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (BuildContext context) => checkoutRoute,
        )
    );
  }


  final Function() setupCart;
  @override
  Widget build (BuildContext ctxt) {
    String regText = "Get Registered";
    String guestCheckoutText = "Continue as Guest User";
    Widget guestCheckoutRoute = new GuestDetailsPage(widget.cartTotals,widget.tipAmount, widget.shippingMethod,true);
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
                new SizedBox(width: 330.0,height: 120.0, child : new Text("Register an account to receive an additional 10% off on your next order",style: new TextStyle(fontSize: 25.0,fontWeight: FontWeight.bold,color:Colors.green ), textAlign: TextAlign.center,)),
              ])
            ),
            new Container(
              padding: new EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
              child: new Row(
                children: <Widget>[
                  new Expanded(
                    child: new RaisedButton(
                      onPressed: ()  => _regGuestUser(context),
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
