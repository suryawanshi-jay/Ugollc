import 'package:flutter/material.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/models/reward_point.dart';

class StoreCreditPage extends StatefulWidget {
  @override
  _StoreCreditPageState createState() => new _StoreCreditPageState();
}

class _StoreCreditPageState extends State<StoreCreditPage> {

    String _userEmail;
    double _credits;
    List<RewardPoint> _rewards = [];
    String description;
    int points;
    int _rewardTotal = 0;

    @override
    initState() {
      super.initState();
      _getUserEmail();
    }

    _getUserEmail() async{
      _userEmail = await PrefsManager.getString(PreferenceNames.USER_EMAIL);
      setState(() => _userEmail = _userEmail);
      _getCredits();
      _getRewards();
    }

    _getCredits() {
      ApiManager.request(
        OCResources.POST_STORE_CREDIT,
            (json) {
          if(json["credit"] != null) {
            setState(() => _credits = double.parse(json['credit']));
          }else{
            setState(() => _credits = 0.00);
          }
        },
        params: {
          "customer_email" : _userEmail
        },
      );
    }

    _getRewards() {
      ApiManager.request(
        OCResources.POST_REWARD_POINTS,
            (json) {
          if(json["rewards_total"] != null) {
            setState(() => _rewardTotal = json['rewards_total']);
          }
          if(json["rewards"] != "null") {
            final fetchedRewards = json["rewards"];
            final rewardPoint = fetchedRewards.map((Map reward) =>
            new RewardPoint.fromJSON(reward)).toList();
            setState(() => _rewards = rewardPoint);
          }
        },
        params: {
          "customer_email" : _userEmail
        },
      );
    }

    Widget build (BuildContext ctxt) {
      return new Scaffold(
        appBar: new AppBar(
          title: new Text("Store Credit & Reward"),
        ),
        body: new Container (
          child: new Column(
            children: <Widget>[
              new Container(
                  padding: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                  child:new Row(
                      children: <Widget>[
                        new Text("Store Credits:",style: new TextStyle(fontSize: 20.0,fontWeight: FontWeight.bold,color:Colors.black), textAlign: TextAlign.left,),
                      ])
              ),
              new Container(
                  padding: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                  child:new Row(
                      children: <Widget>[
                        new SizedBox(width: 330.0,height: 100.0, child : new Text("You have \$${_credits} in your UGO wallet as store Credits.",style: new TextStyle(fontSize: 25.0,fontWeight: FontWeight.bold,color:Colors.green ), textAlign: TextAlign.center,)),
                      ])
              ),
              new Container(
                  padding: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                  child:new Row(
                      children: <Widget>[
                        new Text("Reward Points:",style: new TextStyle(fontSize: 20.0,fontWeight: FontWeight.bold,color:Colors.black), textAlign: TextAlign.left,),
                      ])
              ),
              new Container(
                  padding: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                  child:new Row(
                      children: <Widget>[
                        new SizedBox(width: 330.0,height: 100.0, child : new Text("You have ${_rewardTotal} reward points in your UGO account.",style: new TextStyle(fontSize: 25.0,fontWeight: FontWeight.bold,color:Colors.green ), textAlign: TextAlign.center,)),
                      ])
              ),
            ],
          ),
        ),
      );
    }
  }

