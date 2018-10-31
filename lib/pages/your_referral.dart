import 'package:flutter/material.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';

class YourReferralPage extends StatefulWidget {
  @override
  _YourReferralPageState createState() => new _YourReferralPageState();
}

class _YourReferralPageState extends State<YourReferralPage> {

  String _userEmail;

  @override
  initState() {
    super.initState();
    _getRefferalHistory();
    _getUserEmail();
  }

  _getRefferalHistory(){
    ApiManager.request(
        OCResources.GET_REFERRAL_HISTORY,
            (json) {
             debugPrint('$json');
        },
      params: {
        "customer_email" : _userEmail
      },
    );
  }

  _getUserEmail() async{
    _userEmail = await PrefsManager.getString(PreferenceNames.USER_EMAIL);
    setState(() => _userEmail = _userEmail);
  }


  @override
  Widget build (BuildContext ctxt) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Your Referral"),
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
                        new SizedBox(width: 330.0,height: 240.0, child : new Text("Your Referral",style: new TextStyle(fontSize: 15.0,fontWeight: FontWeight.normal,color:Colors.black ), textAlign: TextAlign.left,)),
                      ])
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
