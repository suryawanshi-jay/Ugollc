import 'package:flutter/material.dart';
import 'package:ugo_flutter/models/order.dart';
import 'package:ugo_flutter/pages/loading_screen.dart';
import 'package:ugo_flutter/pages/order_details_page.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/constants.dart';

class OrderHistoryPage extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => new _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<SimpleOrder> _orders = [];
  bool _loading = false;

  @override
  initState() {
    super.initState();
    _fetchOrders();
  }

  _fetchOrders() {
    setState(() => _loading = true);
    ApiManager.request(
      OCResources.GET_ORDERS,
        (json) {
        final fetchedOrders = json["orders"];
        final simpleOrders = fetchedOrders.map((Map order) =>
          new SimpleOrder.fromJSON(order)).toList();
        setState(() => _orders = simpleOrders);
        setState(() => _loading = false);
      }
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return new LoadingContainer(loadingText: "LOADING ORDERS . . .");
    }

    final _orderList = _orders.map((order) {
      final pluralItem = order.products > 1 ? "items" : "item";
      final dateText = "${order.date.month}/${order.date.day}/${order.date.year}";
      return new ListTile(
        title: new Text("${dateText} - ${order.total}"),
        subtitle: new Text("${order.products} $pluralItem ordered"),
        trailing: new IconButton(
          icon: new Icon(Icons.chevron_right, color: UgoGreen, size: 36.0,),
          onPressed: () => Navigator.push(
              context, new MaterialPageRoute(
                  builder: (BuildContext context) => new OrderDetailsPage(order.id)
              )
          ),
        ),
      );
    }).toList();

    return new ListView(
      children: _orderList,
    );
  }
}
