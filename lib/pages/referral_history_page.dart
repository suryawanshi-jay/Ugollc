import 'package:flutter/material.dart';
import 'package:ugo_flutter/models/referral_history.dart';
import 'package:ugo_flutter/pages/loading_screen.dart';
import 'package:ugo_flutter/pages/order_details_page.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';

class ReferralHistoryPage extends StatefulWidget {
  @override
  _ReferralHistoryPageState createState() => new _ReferralHistoryPageState();
}

class _ReferralHistoryPageState extends State<ReferralHistoryPage> {
  List<ReferralHistory> _referrals = [];
  bool _loading = false;
  String email = "";

  @override
  initState() {
    super.initState();
    _getUserEmail();

  }

  _getUserEmail() async{
    var _userEmail = await PrefsManager.getString(PreferenceNames.USER_EMAIL);
    setState(() => email = _userEmail);
    _fetchReferrals();

  }


  _fetchReferrals() {
    setState(() => _loading = true);
    ApiManager.request(
      OCResources.POST_REFERRAL_HISTORY,
          (json) {
        final fetchedReferrals = json["referrals"];
        final referralHistory = fetchedReferrals.map((Map refer) =>
        new ReferralHistory.fromJSON(refer)).toList();
        setState(() => _referrals = referralHistory);
        setState(() => _loading = false);
      },
      params: {
        "customer_email" : email
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return new LoadingContainer(loadingText: "LOADING REFERRALS . . .");
    }

    final _referList = _referrals.map((refer) {
      final dateText = "${refer.date.month}-${refer.date.day}-${refer.date.year}";
      return new ListTile(
        title: new Text("${refer.name}"),
        subtitle: new Text("${dateText}  ${refer.email}" ),
      );
    }).toList();


    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Referral History"),
      ),
      body: new GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child:new Container(
          child: new Container(
            child: new ListView(
              children: _referList,
            ),
          ),
        ),
      ),
    );
  }
}
