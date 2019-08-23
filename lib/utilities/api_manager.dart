import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugo_flutter/utilities/secrets.dart';

import "constants.dart";

class ApiManager extends Object {
  static request(
    String resource,
    void successHandler(json),
    {
      Function errorHandler(response),
      Function exceptionHandler(exception),
      String resourceID,
      Map<String, dynamic> params,
      BuildContext context
    }
    ) async {

    try {
      _urlForRequest(resource, resourceID).then((url) {
        _makeRequest(resource, url, params).then((response) {
          var json;
          if (response.body.length > 0) {
            json = JSON.decode(response.body);
          }
          if (response.statusCode == HttpStatus.OK || response.statusCode == HttpStatus.CREATED) {
            successHandler(json);
          } else {
            if (errorHandler != null) {
              errorHandler(json);
            } else {
              defaultErrorHandler(json, context: context);
            }
          }
        });
      });
    } catch (exception) {
      if (exceptionHandler != null) {
        exceptionHandler(exception);
      } else {
        _defaultExceptionHandler(exception);
      }
    }
  }

  static Future<String> _urlForRequest(String resource, String resourceID) async {
    final endpoint = resource.split("::").last;
    //var url = "https://";
    var url = "http://";
    switch (resource.split("::")[1]) {
      case OPENCART_IDENTIFIER:
        url += API_HOST + "/" + apiVersion + endpoint;
        if (resource == OCResources.POST_TOKEN) {
          return url;
        }
        var token = await _apiToken();
        url += "?access_token=" + token;
        break;
      case STRIPE_IDENTIFIER:
        url = "https://";
        url += AWS_HOST + "/" + endpoint;
        break;
      case GOOGLE_IDENTIFIER:
        url = "https://";
        url += GOOGLE_HOST + "/" + endpoint;
    }

    if (resourceID != null) {
      url = url.replaceAll(r'{id}', resourceID);
    }
    debugPrint("$url");
    return url;
  }

  static Future<http.Response> _makeRequest(String resource, String url, Map params) async {
    if (resource == OCResources.POST_TOKEN) {
      final headers = {
        HttpHeaders.AUTHORIZATION: basicAuthToken,
        HttpHeaders.CACHE_CONTROL: 'private'
      };
      return http.post(url, headers: headers);
    }
    dynamic body = params;
    var headers = {};
    if (resource.split("::")[1] == STRIPE_IDENTIFIER) {
      headers = {
        "x-api-key": AWS_API_KEY,
      };
      body = JSON.encode(params);
    }

    final method = resource.split("::").first;

    switch(method){
      case "POST":
        return http.post(url, body: body, headers: headers);
      case "PUT":
        return http.put(url, body: body, headers: headers);
      case "DELETE":
        return http.delete(url, headers: headers);
      default:
        if (body != null && body != {}) {
          var queryParams = [];
          body.forEach((key, value) {
            queryParams.add("$key=$value");
          });
          final prefix = url.contains("?") ? "&" : "?";
          final queryLine = prefix + queryParams.join("&");
          url += queryLine;
        }
        return http.get(url, headers: headers);
    }
  }

  static Future<String> _apiToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(PreferenceNames.USER_TOKEN);
    if (token == null) {
      request(
        OCResources.POST_TOKEN,
        (response) {
            token = response["access_token"];
            prefs.setString(PreferenceNames.USER_TOKEN, token);
        },
        errorHandler: (response) {
//          // todo: handle this error
          token = "";
        },
        exceptionHandler: (response) {
//          //todo: handle this exception
          token = "";
        }
      );
    }
    return token;
  }

  static void defaultErrorHandler(errResponse, {BuildContext context, String analyticsInfo, String message, int delay}) {
    print("ERROR");
    print(errResponse);

    final _analytics = new FirebaseAnalytics();

    var displayMessage = message;

    if (errResponse["errors"] != null) {
      final error = errResponse["errors"].first;
      displayMessage = displayMessage ?? error["message"];
    }

    int errorLength = 0;
    String errorMessage = "No error message provided";

    if (displayMessage != null) {
      errorLength = displayMessage.length >= 100 ? 99 : displayMessage.length - 1;
      errorMessage = displayMessage.substring(0, errorLength);
    }

    _analytics.logEvent(name: "api_manager_error", parameters: {
      "error": errorMessage,
      "info": analyticsInfo ?? "No additional info provided",
    });

    if (context != null) {
      Scaffold.of(context).showSnackBar(
        new SnackBar(
          duration: new Duration(milliseconds: delay ?? 3000),
          content: new Text(displayMessage ?? "An error occurred. Please try again."),
          backgroundColor: Colors.red,)
      );
    }
  }

  static void _defaultExceptionHandler(excResponse) {
    print("EXCEPTION");
    print(excResponse);

    final _analytics = new FirebaseAnalytics();
    _analytics.logEvent(name: "api_manager_exception", parameters: {
      "exception": excResponse,
    });
  }
}

