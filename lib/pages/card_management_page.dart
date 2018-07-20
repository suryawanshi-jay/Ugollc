import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugo_flutter/models/payment_card.dart';
import 'package:ugo_flutter/pages/add_card_page.dart';
import 'package:ugo_flutter/pages/loading_screen.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';

class CardManagementPage extends StatefulWidget {
  @override
  _CardManagementPageState createState() => new _CardManagementPageState();
}

class _CardManagementPageState extends State<CardManagementPage> {
  List<PaymentCard> _cards = [];
  bool _loading = false;

  @override
  initState() {
    super.initState();
    _getCards();
  }

  _getCards() async {
    final prefs = await SharedPreferences.getInstance();

    PrefsManager.getString(PreferenceNames.USER_EMAIL).then((email) {
      setState(() => _loading = true);
      ApiManager.request(
        StripeResources.ADD_CUSTOMER,
        (json) {
          final sources = json["sources"];
          prefs.setString(PreferenceNames.USER_STRIPE_ID, json["id"]);
          final stripeCards = sources["data"].map((source) =>
            new PaymentCard.fromJSON(source));
          setState(() => _cards = stripeCards.toList());
          setState(() => _loading = false);
        },
        params: {
          "email": email
        }
      );
    });
  }

  _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      child: new AlertDialog(
        title: new Text("Delete Card?", style: new TextStyle(color: Colors.grey[800]),),
        actions: <Widget>[
          new FlatButton(
            onPressed: () => Navigator.pop(context, false),
            child: new Text("Cancel", style: new TextStyle(color: Colors.grey[800]),),
          ),
          new FlatButton(
            onPressed: () => Navigator.pop(context, true),
            child: new Text("Delete", style: new TextStyle(color: Colors.red),)
          )
        ],
      )
    ).then((value) {
      if (value == true) {
        _getCustomerInfo(id);
      }
    });
  }

  _getCustomerInfo(id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final stripeID = prefs.getString(PreferenceNames.USER_STRIPE_ID);
    if (stripeID != null && stripeID != "") {
      _deleteCard(id, stripeID);
    } else {
      ApiManager.request(
        StripeResources.ADD_CUSTOMER,
        (json) {
          prefs.setString(PreferenceNames.USER_STRIPE_ID, json["id"]);
          _deleteCard(id, json["id"]);
        },
        params: {
          "email": prefs.getString(PreferenceNames.USER_EMAIL)
        }
      );
    }
  }

  _deleteCard(String id, String stripeID) {
    ApiManager.request(
      "DELETE::$STRIPE_IDENTIFIER::card/{id}/customer/$stripeID",
      (json) {
        var _updatedCards = _cards;
        _updatedCards.removeWhere((card) => card.id == id);
        setState(() => _cards = _updatedCards);
      },
      resourceID: id
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return new LoadingContainer(loadingText: "LOADING CARDS . . .",);
    }

    final _cardList = _cards.map((card) =>
      new ListTile(
        title: new Text("${card.brand} - ***${card.last4}"),
        subtitle: new Text("${card.expMonth}/${card.expYear}"),
        trailing: new IconButton(
          icon: new Icon(
            Icons.delete_forever,
            size: 36.0,
            color: Colors.red
          ),
          onPressed: () => _confirmDelete(context, card.id)),
      )
    ).toList();

    return new Container(
      child: new Column(
        children: <Widget>[
          new Expanded(
            child: new ListView(
              children: _cardList,
            ),
          ),
          new Padding(
            padding: const EdgeInsets.all(20.0),
            child: new Row(
              children: <Widget>[
                new Expanded(
                  child: new RaisedButton(
                    onPressed: () {
                      Navigator.push(context,
                        new MaterialPageRoute(
                          builder: (BuildContext context) => new AddCardPage())
                      ).then((newCard) {
                        if (newCard != null && newCard.runtimeType == PaymentCard) {
                          var updatedCards = _cards;
                          updatedCards.add(newCard);
                          setState(() => _cards = updatedCards);
                        }
                    });},
                    color: UgoGreen,
                    child: new Text("Add New Card", style: BUTTON_STYLE,)
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
