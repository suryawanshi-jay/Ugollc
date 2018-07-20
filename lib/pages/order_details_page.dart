import 'package:flutter/material.dart';
import 'package:ugo_flutter/models/order.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/constants.dart';

class OrderDetailsPage extends StatefulWidget {
  int id;

  OrderDetailsPage(this.id);

  @override
  _OrderDetailsPageState createState() => new _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Order _order;

  @override
  initState() {
    super.initState();
    _fetchOrder();
  }

  _fetchOrder() {
    ApiManager.request(
      OCResources.GET_ORDER,
      (json) {
        final fetchedOrder = new Order.fromJSON(json["order"]);
        setState(() => _order = fetchedOrder);
      },
      resourceID: widget.id.toString()
    );
  }

  List<Widget> _productList() =>
    _order.products.map((product) =>
      new ListTile(
        title: new Text("${product.name} - ${product.model}"),
        subtitle: new Text("${product.quantity} @ ${product.price} = ${product.total}"),
//        trailing: new RaisedButton(
//          color: UgoGreen,
//          child: new Text("Reorder", style: new TextStyle(color: Colors.white, fontSize: 18.0),),
//          onPressed: () => {}
//        ),
      )
    ).toList();

  _totals() =>
    _order.totals.map((total) =>
      new Text("${total.title}: ${total.text}")
    ).toList();

  _body() {
    List<Widget> list = [
      new Padding(
        padding: new EdgeInsets.only(top: 20.0),
      ),
      new Container(
        padding: new EdgeInsets.symmetric(horizontal: 16.0),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Text("Shipping Address:"),
            new Text("${_order.shippingAddress1}\n"
              "${_order.shippingCity}, ${_order.shippingZone} ${_order
              .shippingPostcode}"),
          ],
        ),
      ),
      new Divider(),
      new Container(
        padding: new EdgeInsets.symmetric(horizontal: 16.0),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Text("Recipient:"),
            new Text(
              "${_order.shippingFirstName} ${_order.shippingLastName}"),
            new Text("Phone: ${_order.telephone}"),
            new Text("Email: ${_order.email}"),
          ],
        ),
      ),
      new Divider(),
      new Container(
        padding: new EdgeInsets.symmetric(horizontal: 16.0),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Text("Shipping Method: ${_order.shippingMethod}"),
            new Text("Order ID: ${_order.id}"),
          ],
        ),
      ),
      new Divider(),
      new Container(
        padding: new EdgeInsets.symmetric(horizontal: 16.0),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _totals(),
        ),
      ),
      new Divider(),
    ];

    list.addAll(_productList());

    return new ListView(
      children: list,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Order Details"),
      ),
      body: _order == null ? new Container() : _body()
    );
  }
}
