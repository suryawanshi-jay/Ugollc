import 'package:flutter/material.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/pages/your_referral.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';

class SendReferralPage extends StatefulWidget {
  @override
  _SendReferralPageState createState() => new _SendReferralPageState();
}

class _SendReferralPageState extends State<SendReferralPage> {
  String message;
  String name;
  String email;
  bool newMessage = false;
  String success;
  String sending_limit;
  String error;
  bool showReturnMsg = false;
  String returnMsg ="";
  Color returnMsgColor;
  String _userEmail;
  TextEditingController _messageController = new TextEditingController();
  Map<String, String> _referralInfo = {};

  @override
  initState() {
    super.initState();
    _getRefferal();
    _getUserEmail();
    _setDefaultmsg();

  }

  _getUserEmail() async{
    _userEmail = await PrefsManager.getString(PreferenceNames.USER_EMAIL);
    setState(() => _userEmail = _userEmail);
  }

  _setDefaultmsg() {
    setState(() => _messageController.text = "Click the link and find the amazing app: https://www.ugollc.com ");
  }

  _getRefferal() {
    ApiManager.request(
      OCResources.GET_REFERRAL_COUPON,
          (json) {
         setState(() => _referralInfo = {
           "sending_reward" : json['sending_reward'],
           "coupon_redeemed_reward" :json['coupon_redeemed_reward'],
           "reward_type" : json['reward_type'],
           "coupon_discount": json['coupon_discount'],
           "order_total": json['order_total'],
           "customer_login": json['customer_login'],
           "expire": json['expire'],
           "uses_total": json['uses_total'],
           "uses_customer":json['uses_customer'],
         });
      }
    );
  }

  _yourReferral(){
    Widget referralRoute = new YourReferralPage();
    Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (BuildContext context) => referralRoute,
      )
    );
  }

  _sendRefferal(){
    ApiManager.request(
      OCResources.POST_REFERRAL_COUPON,
          (json) {
           setState(() => success = json['referee']['success']);
           setState(() => sending_limit = json['referee']['sending_limit']['text']);
           setState(() => error = json['referee']['error']['email_existed']);
           setState(() => showReturnMsg = true);
           if(success == null){
             returnMsg = "${error}";
             returnMsgColor = Colors.red;
           }else{
             returnMsg = "${success} ${sending_limit}";
             returnMsgColor = Colors.green;
           }
      },
      params: {
        "referee_email": email,
        "referee_name": name,
        "referrer_message" : newMessage ? message : _messageController.text,
        "customer_email" : _userEmail
      },
      errorHandler: (error) {
        ApiManager.defaultErrorHandler(error, context: context);
      }
    );
  }

  @override
  Widget build (BuildContext ctxt) {
    return new Scaffold(
        appBar: new AppBar(
        title: new Text("Send Referral Coupon"),
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
                  padding: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                  child:new Row(
                      children: <Widget>[
                        new SizedBox(width: 330.0,height: 240.0, child : new Text("When you refer a friend to the store, you will receive ${_referralInfo['sending_reward']} ${_referralInfo['reward_type']} and your friend will receive a coupon for ${_referralInfo['coupon_discount']}. When your friend redeems the coupon, you will receive an additional ${_referralInfo['coupon_redeemed_reward']} ${_referralInfo['reward_type']}. Coupon conditions: \n \nOrder total: ${_referralInfo['order_total']} \nCustomer login: ${_referralInfo['customer_login']} \nExpire in: ${_referralInfo['expire']} days \nUses per coupon: ${_referralInfo['uses_total']} \nUses per customer: ${_referralInfo['uses_customer']}",style: new TextStyle(fontSize: 15.0,fontWeight: FontWeight.normal,color:Colors.black ), textAlign: TextAlign.left,)),
                      ])
              ),
              new Container(
                  padding: new EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 20.0),
                  child: new Row(
                    children: <Widget>[
                      new Expanded(
                          child: new RaisedButton(
                            onPressed: ()  => _yourReferral(),
                            color: UgoGreen,
                            child: new Text("Check your Referral", style: new TextStyle(fontSize: 18.0, color: Colors.white)),
                          )
                      )
                    ],
                  )
              ),
              new Container(
                  padding: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                  child:new Row(
                      children: <Widget>[
                       new Text("Sending Referral Form",style: new TextStyle(fontSize: 20.0,fontWeight: FontWeight.bold,color:Colors.black), textAlign: TextAlign.left,),
                      ])
              ),
              new Container(
                margin: new EdgeInsets.only(top: 0.0, left: 10.0, right: 10.0, bottom: 0.0),
                child: new SingleChildScrollView(
                  child: new Column(
                    children: <Widget>[
                      new TextField(
                        decoration: const InputDecoration(
                            prefixIcon: const Icon(Icons.person),
                            labelText: 'Name'
                        ),
                        onChanged: (value) {
                          setState(() => name = value);
                        },
                        keyboardType: TextInputType.text,
                        autocorrect: false,
                      ),
                      new TextField(
                        decoration: const InputDecoration(
                            prefixIcon: const Icon(Icons.mail),
                            labelText: 'Email'
                        ),
                        onChanged: (value) {
                          setState(() => email = value);
                        },
                        keyboardType: TextInputType.text,
                        autocorrect: false,
                      ),
                      new Padding(padding: new EdgeInsets.only(top: 25.0),),
                      new TextField(
                        decoration: new InputDecoration(
                            labelText: "Message",
                            border: new OutlineInputBorder(),
                            contentPadding: const EdgeInsets.all(20.0)
                        ),
                        controller: _messageController,
                        maxLines: 5,
                        onChanged: (value) { setState(() => message = value); setState(() => newMessage = true);},
                      ),
                      new Padding(padding: new EdgeInsets.only(top: 25.0),),
                      new Container(
                        padding: new EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
                        child: new Row(
                          children: <Widget>[
                            new Expanded(
                                child: new RaisedButton(
                                  onPressed: ()  => _sendRefferal(),
                                  color: UgoGreen,
                                  child: new Text("Send Referral", style: new TextStyle(fontSize: 18.0, color: Colors.white)),
                                )
                            )
                          ],
                        )
                      ),
                      showReturnMsg?new Container(
                        padding: new EdgeInsets.only(top: 0.0, left: 10.0, right: 10.0, bottom: 10.0),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            new Text(returnMsg, style: new TextStyle(fontSize: 15.0, color: returnMsgColor)),
                          ],
                        ),
                      ):new Container(),
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
