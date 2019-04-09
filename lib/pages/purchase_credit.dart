import 'package:flutter/material.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';
import 'package:ugo_flutter/pages/referral_history_page.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';
import'package:ugo_flutter/pages/store_credit_page.dart';

class PurchaseCreditPage extends StatefulWidget {
  @override
  _PurchaseCreditPageState createState() => new _PurchaseCreditPageState();
}

class _PurchaseCreditPageState extends State<PurchaseCreditPage> {
  String amount;
  bool checkedValue = false;
  double _maxCredit;
  double _minCredit;
  String defaultAmount;

  TextEditingController _creditController = new TextEditingController();


  @override
  initState() {
    _getCreditDetails();

  }


  _getCreditDetails() {
    ApiManager.request(
        OCResources.GET_CREDIT_DETAILS,
            (json) {
          debugPrint("$json");
          setState(() => _minCredit = 20.00);
          setState(() => _maxCredit = double.parse(json['credit']['max_amount']));
          setState(() => _creditController.text = json['credit']['default_amount']);
        }
    );
  }

  _validatePurchaseCredit(){
    //debugPrint(_minCredit);
    //var min_amount = double.parse(_minCredit);
    //var max_amount = double.parse(_maxCredit);
    //var buyAmount = double.parse(amount);

    if(double.parse(amount) >= _minCredit && double.parse(amount) <= _maxCredit) {
      debugPrint("here1");
    }else {
      debugPrint("nookk");
    }
  }


  @override
  Widget build (BuildContext ctxt) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("UGO Credits"),
      ),
      body: new GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child:new Container(
          child: new Container(
            child: new ListView(
              children: <Widget>[
                new Container(
                  padding: new EdgeInsets.all(10.0),
                  child: new Text("The store credit will be added to your account after your order has been paid for.\n\nNB: you cannot buy credit with your store credit balance!",style: new TextStyle(fontSize: 15.0,fontWeight: FontWeight.normal,color:Colors.black ), textAlign: TextAlign.left),
                ),
                new Container(
                    padding: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                    child:new Row(
                        children: <Widget>[
                          new Text("Purchase UGO Credit",style: new TextStyle(fontSize: 20.0,fontWeight: FontWeight.bold,color:Colors.black), textAlign: TextAlign.left,),
                        ])
                ),
                new Container(
                  margin: new EdgeInsets.only(top: 0.0, left: 10.0, right: 10.0, bottom: 0.0),
                  child: new SingleChildScrollView(
                    child: new Column(
                      children: <Widget>[
                        new TextField(
                          controller: _creditController,
                          decoration: new InputDecoration(
                            prefixIcon: const Icon(Icons.monetization_on),
                            labelText: 'Enter Amount',
                          ),
                            onChanged: (value) {
                              setState(() => amount = value);
                            },
                        ),
                        new Padding(padding: new EdgeInsets.only(top: 25.0),),
                        new CheckboxListTile(
                          title: new Text("I understand that purchase of store credits are non-refundable."),
                          value: checkedValue,
                          onChanged: (value) {
                            setState(() => checkedValue = true);
                          },
                        ),
                        new Padding(padding: new EdgeInsets.only(top: 25.0),),
                        new Container(
                            padding: new EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
                            child: new Row(
                              children: <Widget>[
                                new Expanded(
                                    child: new RaisedButton(
                                      onPressed: ()  => _validatePurchaseCredit(),
                                      color: UgoGreen,
                                      child: new Text("Buy Credit", style: new TextStyle(fontSize: 18.0, color: Colors.white)),
                                    )
                                )
                              ],
                            )
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
