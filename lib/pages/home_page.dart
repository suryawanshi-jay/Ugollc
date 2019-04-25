import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugo_flutter/models/cart.dart';
import 'package:ugo_flutter/models/category.dart';
import 'package:ugo_flutter/models/product.dart';
import 'package:ugo_flutter/pages/category_page.dart';
import 'package:ugo_flutter/pages/loading_screen.dart';
import 'package:ugo_flutter/pages/search_page.dart';
import 'package:ugo_flutter/utilities/api_manager.dart';
import 'package:ugo_flutter/utilities/constants.dart';
import 'package:ugo_flutter/widgets/cart_button.dart';
import 'package:ugo_flutter/widgets/store_credit_button.dart';
import 'package:ugo_flutter/widgets/product_widget.dart';
import 'package:ugo_flutter/widgets/circle_product_widget.dart';
import 'package:ugo_flutter/widgets/list_divider.dart';
import 'package:ugo_flutter/pages/drawer.dart';
import 'package:ugo_flutter/utilities/prefs_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  static const APP_STORE_URL = 'https://itunes.apple.com/us/app/ugo-convenience-delivery/id1029275361?mt=8';
  static const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.ugollc.ugoflutter&hl=en_US';
  List<SimpleCategory> _simpleCategories = [];
  List<Category> _categories = [];
  bool _loading = false;
  Cart _cart;
  bool showMaintenanceMsg = false;
  String maintenenanceMsg;
  double _credits;
  bool loggedIn = false;
  String currentVersion = "3.0.11";
  String platform = "android";
  bool isiOS = false;
  bool isAndroid = false;

  TabController _tabController;

  // search state
  List<SimpleProduct> _searchProducts;
  TextEditingController _textController = new TextEditingController();
  TextField _searchField;
  FocusNode _searchFocus;

  final _analytics = new FirebaseAnalytics();

  @override
  initState() {
    _checkLoggedIn();
    super.initState();
    _tabController = new TabController(length: 3, vsync: this);
    setState(() => _loading = true);
    _startupTokenCheck();
    versionCheck();
    _searchFocus = new FocusNode();
    _searchField = new TextField(
      focusNode: _searchFocus,
      controller: _textController,
      onChanged: (value) {
        if (value.length > 2) {
          _search(value);
        }
      },
      onSubmitted: (value) => _search(value),
      decoration: new InputDecoration(
        prefixIcon: new Icon(Icons.search),
        suffixIcon: new IconButton(
          icon: new Icon(Icons.close),
          onPressed: () => _textController.text = "",
        ),
        labelText: 'Search',
      ),
    );
    _tabController.addListener(() {
      if (_searchFocus.hasFocus) {
        _searchFocus.unfocus();
      }
    });
  }

  _startupTokenCheck() async {
    await _analytics.logAppOpen();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(PreferenceNames.USER_TOKEN);
    if (token == null) {
      ApiManager.request(
        OCResources.POST_TOKEN,
          (response) {
          var json = response;
          var token = json["access_token"];
          prefs.setString(PreferenceNames.USER_TOKEN, token);
          _fetchCategories();
          _fetchCart();
        },
        errorHandler: (response) {
          // TODO: handle this error
          print("ERROR GETTING TOKEN ON LAUNCH, " + response.statusCode.toString());
        },
        exceptionHandler: (exception) {
          // TODO: handle this exception
          print("EXCEPTION GETTING TOKEN ON LAUNCH");
        }
      );
    } else {
      _fetchCategories();
      _fetchCart();
      _getCredits();
      _checkLoggedIn();
    }
  }

  versionCheck() async {
    if(platform == "ios"){
      setState(() => isiOS = true);
    }else{
      setState(() => isAndroid = true);
    }
    ApiManager.request(
        OCResources.GET_VERSION,
            (json) async {
          if(json['version'] != currentVersion ){
            _showVersionDialog();
          }
        },
      params: {
          "platform" :platform
      }
    );
  }

  void _showVersionDialog() async {
     await showDialog<String>(
      //context: context,
      barrierDismissible: false,
      child: new Builder (builder: (BuildContext context) {
        String title = "New Update Available";
        String message =
            "There is a newer version of app available please update it now.";
        String btnLabel = "Update Now";
        return isiOS
            ? new CupertinoAlertDialog(
          title: new Text(title),
          content:new Text(message),
          actions: <Widget>[
            new FlatButton(
              child: new Text(btnLabel),
              onPressed: () => _launchURL(APP_STORE_URL),
            ),
            //new  FlatButton(
            //  child: new Text(btnLabelCancel),
            //  onPressed: () => Navigator.pop(context),
            //),
          ],
        )
            : new AlertDialog(
          title: new Text(title),
          content:new  Text(message),
          actions: <Widget>[
            new  FlatButton(
              child: new Text(btnLabel),
              onPressed: () => _launchURL(PLAY_STORE_URL),
            ),
            //new FlatButton(
            //  child: new  Text(btnLabelCancel),
            //  onPressed: () => Navigator.pop(context),
            //),
          ],
        );
      }),
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _checkLoggedIn() async {
    final username = await PrefsManager.getString(PreferenceNames.USER_FIRST_NAME);
    if (username != null) {
      setState(() => loggedIn = true);
    }
  }

  List<SimpleCategory> flattenCategoryHierarchy(List<SimpleCategory> list, List<SimpleCategory>flatList) {
    list.forEach((category) {
      flatList.add(category);
      if (category.categories.length > 0) {
        flatList = flattenCategoryHierarchy(category.categories, flatList);
      }
    });
    return flatList;
  }

  void _fetchCategories() {
    ApiManager.request(
      OCResources.GET_CATEGORIES,
      (json) {
        var categories = json["categories"].map((category) {
          return new SimpleCategory.fromJSON(category);
        }).toList();
        setState(() => _simpleCategories = categories);
        
        // flatten simple categories to fetch data for ALL categories to pass around
        var flatCategories = flattenCategoryHierarchy(categories, []);
        flatCategories.forEach((SimpleCategory category) {
          if(category.totalProducts > 3) {
            _fetchCategoryDetails(category);
            _loading = false;
          }
        });
      },
      errorHandler: (response) {
        print(response);
        if(response["heading_title"] == "Maintenance"){
          setState(() => showMaintenanceMsg = true);
          setState(() => maintenenanceMsg = "😥 We have temporarily paused all orders but don't worry we will back soon.");
          setState(()=> _loading = false);
        }
      },
      exceptionHandler: (exc) {
        print("GET CATEGORIES EXCEPTION");
      }
    );
  }

  void _fetchCart() {
    ApiManager.request(
      OCResources.GET_CART,
      (json) async {
        final fetchedCart = new Cart.fromJSON(json["cart"]);
        setState(() => _cart = fetchedCart);
      }
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

  void _updateCart(json) {
    final updatedCart = new Cart.fromJSON(json["cart"]);
    setState(() => _cart = updatedCart);
  }

  void _fetchCategoryDetails(SimpleCategory category) {
    ApiManager.request(
      OCResources.GET_CATEGORY,
        (json) {
          var category = new Category.fromJSON(json["category"]);
          setState(() => _categories.add(category));
      },
      resourceID: category.id.toString(),
    );
  }

  List<Category> _filterCategories(String filterGroupName, String filterName) {
    return _categories.where((category) {
      return category.filterDisplay(filterGroupName, filterName);
    }).toList();
  }

  _buildCategoryList() {
    var displayCategories = _filterCategories(OCFilterGroups.DISPLAY, OCFilters.DISPLAY_HOME);
    displayCategories.sort((catA, catB) => catA.name.compareTo(catB.name));

    return displayCategories.map((category) {
      if (category.products.length > 0) {
        return new CategoryListRow(category, _cart, updateCart: _updateCart,);
      }
      return new Container();
    }).toList();
  }

  List<Widget> _featuredCategories() {
    final featured = _filterCategories(OCFilterGroups.DISPLAY, OCFilters.DISPLAY_FEATURED);
    //featured.sort((catA, catB) => catA.name.compareTo(catB.name));
    return featured.map((category) =>
      new CategoryListRow(category, _cart, namePrefix: "Featured: ", updateCart: _updateCart,)).toList();
  }

  List<CircleProductWidget> _quickLinks() {
    var categories = _filterCategories(OCFilterGroups.DISPLAY, OCFilters.DISPLAY_QUICK);
    //categories.sort((catA, catB) => catA.name.compareTo(catB.name));
    var list = [];
    for(int i = 0; i < 3; i++) {
      if (categories.length > i && categories[i] != null) {
        list.add(new CircleProductWidget(categories[i].name, categories[i].id, categories[i].thumbImage, _cart, updateCart: _updateCart,));
      } else {
        list.add(new Expanded(child: new Container(),));
      }
    }
    return list;
  }

  _search(String value) {
    if (value != null && value != "") {
      ApiManager.request(
        OCResources.PRODUCT_SEARCH,
          (json) async {
          final results = json["products"].map((prodData) {
            return new SimpleProduct.fromJSON(prodData);
          }).toList();
          setState(() => _searchProducts = results);
          await _analytics.logSearch(searchTerm: value);
        },
        params: {
          "search": value,
          "sort": "name",
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> baseWidgets = [];
    baseWidgets.add(new ListDivider('Quick Links', _cart, updateCart: _updateCart, showMore: false,));
    baseWidgets.add(new Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _quickLinks(),
    ));
    baseWidgets.addAll(_featuredCategories());


    baseWidgets.addAll(_buildCategoryList());

    final cartCount = _cart == null ? 0 : _cart.productCount();
//
//    TextField _searchField = new TextField(
//      controller: _textController,
//      onChanged: (value) {
//        if (value.length > 2) {
//          _search(value);
//        }
//      },
//      onSubmitted: (value) => _search(value),
//      decoration: new InputDecoration(
//        prefixIcon: new Icon(Icons.search),
//        suffixIcon: new IconButton(
//          icon: new Icon(Icons.close),
//          onPressed: () => _textController.text = "",
//        ),
//        labelText: 'Search',
//      ),
//    );

    final _hiddenListCategories = _filterCategories(OCFilterGroups.DISPLAY, OCFilters.DISPLAY_HIDE);
    final _hiddenCategoryIDs = _hiddenListCategories.map((category) =>
      category.id).toList();

//    return new LoadingScreen();

    return _categories.length == 0
      ? showMaintenanceMsg ? new Scaffold(
        appBar: new AppBar(
          backgroundColor: UgoGreen,
          title: new Image.asset('assets/images/ugo_logo.png'),
        ),
        body : new AlertDialog(
          content: new ListView(
            children: <Widget>[
              new Image.asset('assets/images/pause.png'),
              new ListTile(
                title: new Text(maintenenanceMsg,textAlign: TextAlign.center, style : new TextStyle(fontWeight: FontWeight.bold,fontSize: 20.0)),
              )
            ],
          )//actions: <Widget>[
        ),
    ): new LoadingScreen() : new Scaffold(
      drawer: new UgoDrawer(updateCart: _fetchCart,),
      appBar: new AppBar(
        backgroundColor: UgoGreen,
        title: new Image.asset('assets/images/ugo_logo.png'),
        //centerTitle: true,
        actions: [
          loggedIn ? new StoreCreditButton(_credits,_cart): new Container(),
          new CartButton(_cart, updateCart: _updateCart),
        ],
        bottom: new TabBar(
          controller: _tabController,
          tabs: [
            new Tab(icon: new Icon(Icons.home)),
            new Tab(icon: new Icon(Icons.search)),
            new Tab( icon: new Icon(Icons.view_module)),
        ]),
      ),
      body: new TabBarView(
        controller: _tabController,
        children: [
          new Container(
            color: Colors.white,
            child: _loading ? new Center(child: new Text("loading...")) :
            new ListView(
              children: baseWidgets
            ),
          ),
          new SearchPage(_cart, _searchField, updateCart: _updateCart, products: _searchProducts,),
          new CategoryPage(
            _filterCategories(
              OCFilterGroups.DISPLAY,
              OCFilters.DISPLAY_FEATURED_LIST
            ),
            _simpleCategories,
            _cart,
            updateCart: _updateCart,
            hiddenCategoryIDs: _hiddenCategoryIDs,
          )
        ]
      ),
    );
  }
}

class CategoryListRow extends StatelessWidget {
  final Category category;
  final String namePrefix;
  final Cart cart;
  final Function(dynamic) updateCart;

  CategoryListRow(this.category, this.cart, {this.namePrefix = "", this.updateCart});

  Widget _buildProduct(SimpleProduct product) {
    return new Expanded(
      child: new ProductWidget(
        product.id,
        product.name,
        cart,
        price: product.price,
        imageUrl: product.thumbImage,
        updateCart: updateCart,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = category.previewProducts();

    return new Container(
      child: new Column(
        children: <Widget>[
          new ListDivider(namePrefix + category.name, cart, categoryID: category.id, updateCart: updateCart,),
          new Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildProduct(products[0]),
              _buildProduct(products[1]),
              _buildProduct(products[2]),
            ],
          ),
        ],
      )
    );
  }
}


