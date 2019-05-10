import 'package:flutter/material.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/widgets/store_credit_button.dart';
import 'package:ugo_flutter/pages/checkout_page.dart';
import 'package:ugo_flutter/models/cart.dart';
import 'package:flutter/cupertino.dart';
import 'package:ugo_flutter/utilities/constants.dart';

class PurchaseCreditPage extends StatefulWidget {

  PurchaseCreditPage();

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
  double _credits = 0.00;
  Widget checkoutRoute;
  bool showPurchaseForm = true;
  Cart _cart;
  bool isIos = false;

  TextEditingController _creditController = new TextEditingController();

  @override
  initState() {
    _getCreditDetails();
    _getCredits();
    _getCart();
    _checkPlatform();
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

  _getCart(){
    ApiManager.request(
        OCResources.GET_CART,
            (json) {
          setState(() => _cart = new Cart.fromJSON(json["cart"]));
          if (_cart.productCount() > 0) {
              setState(() => showPurchaseForm = false);
          }
        },
        params :{
          "api_call" :1
        },
    );
  }

  _checkPlatform(){
    if(PLATFORM == "ios"){
      isIos = true;
    }else {
      isIos = false;
    }
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
    if(purchaseCredit >= _minCredit && purchaseCredit <= _maxCredit && checkedValue == true ) {
      showError = false;
      ApiManager.request(
        OCResources.POST_CREDIT_DETAILS,
            (json) {
          empty_cart();
        },
        params: {
          "amount" : purchaseCredit.toString(),
          "agree" : "1"
        },
      );
    }else if(purchaseCredit < _minCredit && checkedValue == true) {
      setState(() => showError = true);
      setState(() => errorMsg = "Amount must be greater than \$${_minCredit}0!");
    }else if(purchaseCredit > _maxCredit && checkedValue == true) {
      setState(() => showError = true && checkedValue == true);
      setState(() => errorMsg = "Amount must be lesser than \$${_maxCredit}0!");
    }
  }

  empty_cart(){
    ApiManager.request(
      OCResources.GET_EMPTY_CART,
        (json) {
         _nextPage();
        },
    );
  }

  _showTermsDialog()  {
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      child: new Builder (builder: (BuildContext context)
    {
      String title = "Terms & Conditions";
      String message =
          "Ugo Credit must be purchased separately\nUgo Credit accepts the following payment methods:\n-Credit/debit card\n-Dining Dollars\n-Bama Cash\nEvery attempted Ugo Credit purchase undergoes a review process by management that will take 3-5 minutes.\nBuyer will receive SMS updates on their credit status, every step of the way.\nWhen approved, Ugo Credit will be added to buyers E-Wallet where the Balance will be displayed.\nWhen approved, Ugo Credit will be added to buyers E-Wallet where the Balance will be displayed.\nAll future orders will draw from buyers existing credit balance.\nIf Ugo Credit does not cover full order, the buyer must pay the difference with another payment type.";
      return new WillPopScope(
        onWillPop: () {},
        child: isIos ? new CupertinoAlertDialog(
          title: new Text(title),
          content: new Container(
            margin: new EdgeInsets.only(
                top: 15.0, left: 5.0, right: 5.0, bottom: 0.0),
            child: new ListView(
              children: <Widget>[
                new Text("1. Ugo Credit must be purchased separately.\n",
                    style: new TextStyle(fontStyle: FontStyle.italic)),
                new Text(
                    "2. Ugo Credit accepts the following payment methods:\n-Credit/debit card\n-Dining Dollars\n-Bama Cash.\n",
                    style: new TextStyle(fontStyle: FontStyle.italic)),
                new Text(
                    "3. Every attempted Ugo Credit purchase undergoes a review process by management that will take 3-5 minutes.\n",
                    style: new TextStyle(fontStyle: FontStyle.italic)),
                new Text(
                    "4. Buyer will receive SMS updates on their credit status, every step of the way.\n",
                    style: new TextStyle(fontStyle: FontStyle.italic)),
                new Text(
                    "5. When approved, Ugo Credit will be added to buyers E-Wallet where the Balance will be displayed.\n",
                    style: new TextStyle(fontStyle: FontStyle.italic)),
                new Text(
                    "6. All future orders will draw from buyers existing credit balance.\n",
                    style: new TextStyle(fontStyle: FontStyle.italic)),
                new Text(
                    "7. If Ugo Credit does not cover full order, the buyer must pay the difference with another payment type.\n",
                    style: new TextStyle(fontStyle: FontStyle.italic)),
              ]
              ),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ) : new AlertDialog(
            title: new Text(title),
            content: new Container(
              margin: new EdgeInsets.only(
                  top: 15.0, left: 5.0, right: 5.0, bottom: 0.0),
              child: new ListView(
                  children: <Widget>[
                    new Text("1. Ugo Credit must be purchased separately.\n",
                        style: new TextStyle(fontStyle: FontStyle.italic)),
                    new Text(
                        "2. Ugo Credit accepts the following payment methods:\n-Credit/debit card\n-Dining Dollars\n-Bama Cash.\n",
                        style: new TextStyle(fontStyle: FontStyle.italic)),
                    new Text(
                        "3. Every attempted Ugo Credit purchase undergoes a review process by management that will take 3-5 minutes.\n",
                        style: new TextStyle(fontStyle: FontStyle.italic)),
                    new Text(
                        "4. Buyer will receive SMS updates on their credit status, every step of the way.\n",
                        style: new TextStyle(fontStyle: FontStyle.italic)),
                    new Text(
                        "5. When approved, Ugo Credit will be added to buyers E-Wallet where the Balance will be displayed.\n",
                        style: new TextStyle(fontStyle: FontStyle.italic)),
                    new Text(
                        "6. All future orders will draw from buyers existing credit balance.\n",
                        style: new TextStyle(fontStyle: FontStyle.italic)),
                    new Text(
                        "7. If Ugo Credit does not cover full order, the buyer must pay the difference with another payment type.\n",
                        style: new TextStyle(fontStyle: FontStyle.italic)),
                  ]
              ),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          )
        );
      }),
    );
  }

  _nextPage(){
    Widget checkoutRoute = new CheckoutPage(null,0.0,null,null,false);
    Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (BuildContext context) => checkoutRoute,
        )
    );
  }

  void _getCredits() {
    ApiManager.request(
      OCResources.GET_STORE_CREDIT,
          (json) {
        if(json["credit"] != null) {
          setState(() => _credits = double.parse(json['credit']));
        }else{
          setState(() => _credits = 0.00);
        }
      },
    );
  }

  @override
  Widget build (BuildContext ctxt) {
    return showPurchaseForm ? new Scaffold(
      appBar: new AppBar(
        title: new Text("UGO Credit"),
        actions: [
          new StoreCreditButton(_credits,null),
        ],
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
                        new Padding(padding: new EdgeInsets.only(top: 25.0, left: 5.0, right: 5.0, bottom: 0.0),),
                        new CheckboxListTile(
                          title: new GestureDetector(
                              child: new Text("I have read and agree with the Terms & Conditions.",textAlign: TextAlign.left, style: new TextStyle(decoration: TextDecoration.underline, color:UgoGreen,)),
                              onTap: () {
                                _showTermsDialog();
                                // do what you need to do when "Click here" gets clicked
                              }
                          ),
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
    ):new AlertDialog(
      //title: new Text("Alert Dialog title"),
      content: new Text("You must empty your cart first to purchase UGO credit!",textAlign: TextAlign.left, style : new TextStyle(fontWeight: FontWeight.bold,fontSize: 16.0)),
      actions: <Widget>[
        new FlatButton(
          child: new Text("Back"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
