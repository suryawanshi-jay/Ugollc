import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ugo_flutter/utilities/secrets.dart';
const String API_HOST = "ugollc.com";
//const String API_HOST = "stage.ugollc.com";
const String apiVersion = "api/v1/";
const String basicAuthToken = "Basic VWdvQXV0aDMyMTY1NDpSVGdPQnN0QUJ4MjN4OTgxd3BvQQ==";
const String PLATFORM = "ios";
const String CURRENT_VERSION = "3.0.6";
//const String PLATFORM = "android";
//const String CURRENT_VERSION = "3.0.2";

const double TAX_RATE = 0.09;

const String STRIPE_IDENTIFIER = "STRIPE";
const String OPENCART_IDENTIFIER = "OC";
const String GOOGLE_IDENTIFIER = "GOOGLE";

const String STRIPE_STANDIN = "UGOPAYMENTS";

const Color UgoGreen = const Color.fromARGB(255, 68, 144, 54);
const Color UgoGray = const Color.fromARGB(255, 151, 151, 151);

const Point UGO_STORE_LOC = const Point(33.198056, -87.535080);
const double EARTH_RADIUS = 3958.756;
const double UGO_DELIVERY_RADIUS = 3.0;

const String UGO_PHONE_NUMBER = "205-632-3307";

const String DRIVER_TIP_ID = "860";
const String DRIVER_TIP_NAME = "UGODRIVERTIP";
const double MIN_FREE_SHIPPING = 35.0;

final RegExp EMAIL_REGEXP = new RegExp(r"^([a-z0-9_+\.-]+\@[\da-z\.-]+\.[a-z\.]{2,6})$");
final RegExp PHONE_REGEXP = new RegExp(r"[^0-9.\s\(\)-]");
final RegExp PHONE_LENGTH_REGEXP = new RegExp(r"[^0-9]");
final RegExp PRICE_REGEXP = new RegExp(r"[^0-9.]");

//Styles
const TextStyle BUTTON_STYLE = const TextStyle(fontSize: 18.0, color: Colors.white);

enum OCResource {
  PostToken,
}

abstract class OCResources {
  // METHOD::endpoint
  static const POST_TOKEN = "POST::$OPENCART_IDENTIFIER::oauth2/token";
  static const LOGIN = "POST::$OPENCART_IDENTIFIER::account/login";
  static const LOGOUT = "GET::$OPENCART_IDENTIFIER::account/logout";
  static const REGISTER = "POST::$OPENCART_IDENTIFIER::account/register";
  static const PUT_ACCOUNT = "PUT::$OPENCART_IDENTIFIER::account/account";
  static const POST_PASSWORD = "POST::$OPENCART_IDENTIFIER::account/password";
  static const POST_FORGOTTEN = "POST::$OPENCART_IDENTIFIER::account/forgotten";
  static const GET_ADDRESSES = "GET::$OPENCART_IDENTIFIER::account/address";
  static const GET_ADDRESS = "GET::$OPENCART_IDENTIFIER::account/address/{id}";
  static const ADD_ADDRESS = "POST::$OPENCART_IDENTIFIER::account/address";
  static const PUT_ADDRESS = "PUT::$OPENCART_IDENTIFIER::account/address/{id}";
  static const GET_ORDERS = "GET::$OPENCART_IDENTIFIER::account/order";
  static const GET_ORDER = "GET::$OPENCART_IDENTIFIER::account/order/{id}";
  static const REORDER_ORDER = "GET::$OPENCART_IDENTIFIER::account/order/{id}/reorder";

  static const GET_CATEGORIES = "GET::$OPENCART_IDENTIFIER::product/category";
  static const GET_CATEGORY = "GET::$OPENCART_IDENTIFIER::product/category/{id}";
  static const GET_PRODUCT = "GET::$OPENCART_IDENTIFIER::product/product/{id}";
  static const PRODUCT_SEARCH = "GET::$OPENCART_IDENTIFIER::product/search";

  static const GET_CART = "GET::$OPENCART_IDENTIFIER::cart/cart";
  static const ADD_CART_PRODUCT = "POST::$OPENCART_IDENTIFIER::cart/product";
  static const PUT_CART_PRODUCT = "PUT::$OPENCART_IDENTIFIER::cart/product";
  static const DELETE_CART_PRODUCT = "DELETE::$OPENCART_IDENTIFIER::cart/product/{id}";

  static const POST_PAYMENT_ADDRESS = "POST::$OPENCART_IDENTIFIER::checkout/payment_address";
  static const POST_GUEST_SHIPPING_ADDRESS = "POST::$OPENCART_IDENTIFIER::checkout/guest_shipping";
  static const POST_SHIPPING_ADDRESS = "POST::$OPENCART_IDENTIFIER::checkout/shipping_address";
  static const GET_SHIPPING_METHODS = "GET::$OPENCART_IDENTIFIER::checkout/shipping_method";
  static const POST_SHIPPING_METHOD = "POST::$OPENCART_IDENTIFIER::checkout/shipping_method";
  static const GET_PAYMENT_METHOD = "GET::$OPENCART_IDENTIFIER::checkout/payment_method";
  static const POST_PAYMENT_METHOD = "POST::$OPENCART_IDENTIFIER::checkout/payment_method";
  static const GET_CONFIRM = "GET::$OPENCART_IDENTIFIER::checkout/confirm";
  static const POST_GUEST_CONFIRM = "POST::$OPENCART_IDENTIFIER::checkout/guest_confirm";
  static const GET_PAY = "GET::$OPENCART_IDENTIFIER::checkout/pay";
  static const GET_SUCCESS = "GET::$OPENCART_IDENTIFIER::checkout/success";
  static const POST_COUPON_DETAILS = "POST::$OPENCART_IDENTIFIER::cart/coupon";
  static const POST_CLEAR_COUPON = "POST::$OPENCART_IDENTIFIER::cart/clear_coupon";
  static const POST_UPDATE_COUPON_DETAILS = "POST::$OPENCART_IDENTIFIER::checkout/coupon_confirm";
  static const GET_MIN_SHIPPING_AMT = "GET::$OPENCART_IDENTIFIER::cart/get_free_shipping";
  static const GET_REFERRAL_COUPON = "GET::$OPENCART_IDENTIFIER::module/referral_coupon";
  static const POST_REFERRAL_COUPON = "POST::$OPENCART_IDENTIFIER::module/referral_coupon";
  static const POST_REFERRAL_HISTORY = "POST::$OPENCART_IDENTIFIER::module/referral_history";
  static const GET_STORE_CREDIT = "GET::$OPENCART_IDENTIFIER::cart/store_credit";
  static const POST_REWARD_POINTS = "POST::$OPENCART_IDENTIFIER::cart/reward_points";
  static const POST_REWARD_VALUE = "POST::$OPENCART_IDENTIFIER::checkout/reward_point";
  static const POST_CLEAR_REWARD = "POST::$OPENCART_IDENTIFIER::cart/clear_reward";
  static const GET_FORBIDDEN_CHECK = "GET::$OPENCART_IDENTIFIER::checkout/forbidden_check";
  static const POST_NEW_SHIPPING_AMT = "POST::$OPENCART_IDENTIFIER::checkout/shipping_amount";
  static const GET_CWID = "GET::$OPENCART_IDENTIFIER::checkout/get_cwid";
  static const GET_CREDIT_DETAILS = "GET::$OPENCART_IDENTIFIER::account/buy_credit";
  static const POST_CREDIT_DETAILS = "POST::$OPENCART_IDENTIFIER::account/buy_credit";
  static const GET_EMPTY_CART = "GET::$OPENCART_IDENTIFIER::checkout/empty_cart";
  static const GET_VERSION = "GET::$OPENCART_IDENTIFIER::common/version";
  static const GET_COUNTRY = "GET::$OPENCART_IDENTIFIER::common/country";
  static const POST_ZONE = "POST::$OPENCART_IDENTIFIER::common/country";
  static const APP_STORE_URL = 'https://itunes.apple.com/us/app/ugo-convenience-delivery/id1029275361?mt=8';
  static const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.ugollc.ugoflutter&hl=en_US';

}

abstract class StripeResources {
  static const ADD_CUSTOMER = "POST::$STRIPE_IDENTIFIER::customer";
  static const GET_CUSTOMER = "GET::$STRIPE_IDENTIFIER::customer/{id}";

  static const ADD_CARD = "POST::$STRIPE_IDENTIFIER::card";

  static const POST_CHARGE = "POST::$STRIPE_IDENTIFIER::charge";

  static const DELETE_CARD = "DELETE::$STRIPE_IDENTIFIER::card/{id}";
}

abstract class GoogleResources {
  static const GET_COORDS = "GET::$GOOGLE_IDENTIFIER::maps/api/geocode/json?key=$GOOGLE_API_KEY&address={id}";
}

abstract class OCFilterGroups {
  static const DISPLAY = "Display";
}

abstract class OCFilters {
  static const DISPLAY_QUICK = "Quick Links";
  static const DISPLAY_FEATURED = "Featured";
  static const DISPLAY_HOME = "Home";
  static const DISPLAY_HIDE = "Hide List";
  static const DISPLAY_HIDE_HOME = "Hide Home";
  static const DISPLAY_FEATURED_LIST = "Featured List";
}

abstract class PreferenceNames {
  static const USER_TOKEN = "${API_HOST}_token";
  static const USER_FIRST_NAME = "${API_HOST}_userFirstName";
  static const USER_LAST_NAME = "${API_HOST}_userLastName";
  static const USER_EMAIL = "${API_HOST}_userEmail";
  static const USER_TELEPHONE = "${API_HOST}_userTelephone";
  static const USER_FAX = "${API_HOST}_userFax";
  static const USER_DATE_OF_BIRTH = "${API_HOST}_userDateOfBirth";
  static const USER_GENDER = "${API_HOST}_userGender";
  static const USER_PROFILE = "${API_HOST}_userProfile";
  static const USER_ADDRESS_TYPE = "${API_HOST}_userAddressType";
  static const USER_APARTMENT_NAME = "${API_HOST}_userAddressName";
  static const USER_ADDRESS1 = "${API_HOST}_userAddress1";
  static const USER_ADDRESS2 = "${API_HOST}_userAddress2";
  static const USER_CITY = "${API_HOST}_userCity";
  static const USER_POSTCODE =  "${API_HOST}_userPostCode";
  static const USER_COUNTRY =  "${API_HOST}_userCountry";
  static const USER_ZONE =  "${API_HOST}_userZone";
  static const USER_COUNTRY_ID = "${API_HOST}_userCountryId";
  static const USER_ZONE_ID = "${API_HOST}_userZoneId";
  static const USER_ADDRESS_TYPE_ID = "${API_HOST}_userAddressTypeId";
  static const USER_STRIPE_ID = "${API_HOST}_userStripeID";
  static const STRIPE_IDEM_KEY = "stripeIdempotencyKey";
  static const STRIPE_IDEM_KEY_EXPIRE = "stripeIdempotencyKeyExpire";
  static const STRIPE_IDEM_KEY_PRICE = "stripeIdempotencyKeyPrice";
  static const GUEST_USER = "guestUser";
  static const GUEST_USER_FIRST_NAME = "${API_HOST}_guestUserFirstName";
  static const GUEST_USER_LAST_NAME = "${API_HOST}_guestUserLastName";
  static const GUEST_USER_EMAIL = "${API_HOST}_guestUseruserEmail";
  static const GUEST_USER_TELEPHONE = "${API_HOST}_guestUserTelephone";
  static const GUEST_USER_DATE_OF_BIRTH = "${API_HOST}_guestUserDateOfBirth";
  static const GUEST_USER_GENDER = "${API_HOST}_guestUserGender";
  static const GUEST_USER_PROFILE = "${API_HOST}_guestUserProfile";
  static const GUEST_USER_APARTMENT_NAME = "${API_HOST}_guestUserAddressName";
  static const GUEST_USER_ADDRESS1 = "${API_HOST}_guestUserAddress1";
  static const GUEST_USER_ADDRESS2 = "${API_HOST}_guestUserAddress2";
  static const GUEST_USER_CITY = "${API_HOST}_guestUserCity";
  static const GUEST_USER_POSTCODE =  "${API_HOST}_guestUserPostCode";
  static const GUEST_USER_COUNTRY_ID = "${API_HOST}_guestUserCountryId";
  static const GUEST_USER_ZONE_ID = "${API_HOST}_guestUserZoneId";
  static const GUEST_USER_ADDRESS_TYPE_ID = "${API_HOST}_guestUserAddressTypeId";
  static const GUEST_REG_COUPON = "${API_HOST}_guestUserRegCoupon";
}

final Map<String, dynamic> standinAddress = {
  "firstname": "Ugo",
  "lastname": "Delivery",
  "company": STRIPE_STANDIN,
  "address_1": "Ugo Delivery",
  "city": "Tuscaloosa",
  "postcode": "35401",
  "country_id": "223",
  "zone_id": "3613",
};