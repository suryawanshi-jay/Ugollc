import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_stripe/src/utilities/validators.dart';
import 'package:ugo_flutter/models/payment_card.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';
import 'package:ugo_flutter/utilities/secrets.dart';

class AddCardPage extends StatefulWidget {
  @override
  _AddCardPageState createState() => new _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  String _card_number = "";
  static final now = new DateTime.now();
  int _expMonth = now.month;
  int _expYear = now.year;
  String _cvc = "";
  String _zip = "";

  final _analytics = new FirebaseAnalytics();

  // TODO: move to card params object for state for better validation handling once that's in flutter_stripe package
//  STPCardParams _cardParams = new STPCardParams("", now.month, now.year);

  Future generateToken(BuildContext context) async {
    var client = new STPApiClient(STRIPE_PUBLIC_KEY);
    var token = await client.createTokenWithCard(
      new STPCardParams(
        _card_number,
        _expMonth,
        _expYear,
        cvc: _cvc,
        address: new STPAddress(
          postalCode: _zip,
        )
      )
    );

    final customerID = await PrefsManager.getString(PreferenceNames.USER_STRIPE_ID);

    ApiManager.request(
      StripeResources.ADD_CARD,
      (json) async {
        await _analytics.logAddPaymentInfo();
        final card = new PaymentCard.fromJSON(json);
        Navigator.pop(context, card);
      },
      params: {
        "customer_id": customerID,
        "card_token" : token.id
      },
      context: context
    );
  }

  List<DropdownMenuItem> monthItems() {
    var months = [];
    for (var month = 1; month < 13; month++) {
      final monthString = month.toString().padLeft(2, '0');
      months.add(
        new DropdownMenuItem(
          child: new Text(monthString),
          value: month,
        )
      );
    }
    return months;
  }

  List<DropdownMenuItem> yearItems() {
    var currentYear = now.year;
    var years = [];

    for (var year = currentYear; year < currentYear + 10; year++) {
      years.add(
        new DropdownMenuItem(
          child: new Text(year.toString()),
          value: year,
        )
      );
    }
    return years;
  }

  VoidCallback submitAction(BuildContext context) {
    // TODO: add validators import to main flutter_stipe.dart file;
    if (_card_number.length < 13 || !isLuhnValid(_card_number)) {
      return null;
    } else {
      // TODO: validate card number based on expected ranges and length
      // TODO: display card brand
    }

    if (_expYear == now.year && _expMonth < now.month) {
      return null;
    }

    // TODO: modify this per card brand (Amex = 4)
    if (_cvc.length < 3) {
      return null;
    }

    if (_zip.length < 5) {
      return null;
    }

    final nonDigitPattern = new RegExp(r"\D");
    if (_card_number.contains(nonDigitPattern)
      || _cvc.contains(nonDigitPattern)
      || _zip.contains(nonDigitPattern)) {
      return null;
    }

    return (() => generateToken(context));
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Image.asset("assets/images/ugo_logo.png"),
      ),
      body: new Container(
        margin: new EdgeInsets.all(20.0),
        child: new ListView(
          children: <Widget>[
            new TextField(
              decoration: const InputDecoration(
                labelText: 'Card Number*',
                prefixIcon: const Icon(Icons.credit_card),
              ),
              onChanged: (value) {
                setState(() => _card_number = value);
              },
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            new Padding(padding: new EdgeInsets.only(top: 10.0)),
            new Text("Expiration month/year*"),
            new Row(
              children: <Widget>[
                new DropdownButton(
                  items: monthItems(),
                  value: _expMonth,
                  onChanged: (value) {
                    setState(() => _expMonth = value);
                  }),
                new DropdownButton(
                  items: yearItems(),
                  value: _expYear,
                  onChanged: (value) {
                    setState(() => _expYear = value);
                  }),
              ],
            ),
            new TextField(
              decoration: const InputDecoration(
                labelText: 'CVC*'
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() => _cvc = value);
              },
            ),
            new TextField(
              decoration: const InputDecoration(
                labelText: 'Billing Zip*'
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() => _zip = value);
              },
            ),
            new Padding(padding: new EdgeInsets.only(top: 10.0)),
            new Builder(
              builder: (BuildContext context) {
                return new RaisedButton(
                  onPressed: submitAction(context),
                  color: UgoGreen,
                  child: new Text(
                    'Add Card',
                    style: BUTTON_STYLE,
                  ),
                );
              },
            )
          ],
        )
      ),
    );
  }
}
