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
  double purchaseCredit;
  bool showError = false;
  String errorMsg = "";

  TextEditingController _creditController = new TextEditingController();


  @override
  initState() {
    _getCreditDetails();

  }


  _getCreditDetails() {
    ApiManager.request(
        OCResources.GET_CREDIT_DETAILS,
            (json) {
          setState(() => _minCredit = double.parse(json['credit']['min _amount']));
          setState(() => _maxCredit = double.parse(json['credit']['max_amount']));
          setState(() => _creditController.text = json['credit']['default_amount']);
        }
    );
  }

  _validatePurchaseCredit(){
    if(checkedValue == false){
      setState(() => showError = true);
      setState(() => errorMsg = "You must agree that store credit are non-refundable!");
    }
    if(amount == null){
      var credit = _creditController.text;
      setState(() => purchaseCredit = double.parse(credit));
    }else {
      setState(() => purchaseCredit = double.parse(amount));
    }
    if(purchaseCredit >= _minCredit && purchaseCredit <= _maxCredit) {
      ApiManager.request(
        OCResources.POST_CREDIT_DETAILS,
            (json) {
        },
        params: {
          "amount" : purchaseCredit.toString(),
          "agree" : "1"
        },
      );
    }else if(purchaseCredit < _minCredit) {
      setState(() => showError = true);
      setState(() => errorMsg = "Amount must be greater than \$${_minCredit}0!");
    }else {
      setState(() => showError = true);
      setState(() => errorMsg = "Amount must be lesser than \$${_maxCredit}0!");
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
                        showError ? new Container(
                          padding: new EdgeInsets.all(10.0),
                          child: new Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              new Text(errorMsg, style: new TextStyle(fontSize: 14.0, color: Colors.red)),
                            ],
                          ),
                        ): new Container(),
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
